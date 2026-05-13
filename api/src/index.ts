export interface Env {
  DB: D1Database;
  VERTEX_API_KEY: string;
  VERTEX_PROJECT_ID: string;
  VERTEX_REGION: string; // e.g. "us-central1"
}

const GEMINI_MODEL = "gemini-3.1-flash-lite";

// Limits
const MAX_AUDIO_SIZE_BYTES = 5 * 1024 * 1024; // 5 MB (base64 of ~3.75 MB raw, your largest is ~2.5 MB)
const MAX_SYSTEM_PROMPT_LENGTH = 10_000; // chars (~2 KB base prompt + generous room for custom instructions/vocabulary)
const MAX_REQUEST_SIZE_BYTES = 8 * 1024 * 1024; // 8 MB total request body

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function errorResponse(error: string, status: number): Response {
  return jsonResponse({ error }, status);
}

async function authenticate(
  request: Request,
  db: D1Database
): Promise<{ key: string; words_remaining: number } | Response> {
  const auth = request.headers.get("Authorization");
  if (!auth?.startsWith("Bearer ")) {
    return errorResponse("Missing or invalid Authorization header", 401);
  }

  const apiKey = auth.slice(7);
  const row = await db
    .prepare("SELECT api_key, words_remaining FROM keys WHERE api_key = ?")
    .bind(apiKey)
    .first<{ api_key: string; words_remaining: number }>();

  if (!row) {
    return errorResponse("Invalid API key", 401);
  }

  return { key: apiKey, words_remaining: row.words_remaining };
}

async function handleBalance(
  request: Request,
  env: Env
): Promise<Response> {
  const auth = await authenticate(request, env.DB);
  if (auth instanceof Response) return auth;

  return jsonResponse({ words_remaining: auth.words_remaining });
}

async function handleTranscribe(
  request: Request,
  env: Env
): Promise<Response> {
  const auth = await authenticate(request, env.DB);
  if (auth instanceof Response) return auth;

  // Check total request size
  const contentLength = request.headers.get("Content-Length");
  if (contentLength && parseInt(contentLength) > MAX_REQUEST_SIZE_BYTES) {
    return errorResponse("Request too large", 413);
  }

  const body = await request.json<{
    audio: string;
    system_prompt: string;
  }>();

  if (!body.audio) {
    return errorResponse("Missing 'audio' field", 400);
  }

  // Validate audio size (base64 string length ≈ 4/3 of raw bytes)
  const audioSizeBytes = Math.ceil(body.audio.length * 3 / 4);
  if (audioSizeBytes > MAX_AUDIO_SIZE_BYTES) {
    return errorResponse(`Audio too large (${(audioSizeBytes / 1024 / 1024).toFixed(1)} MB). Max is ${MAX_AUDIO_SIZE_BYTES / 1024 / 1024} MB.`, 413);
  }

  // Validate system prompt length
  if (body.system_prompt && body.system_prompt.length > MAX_SYSTEM_PROMPT_LENGTH) {
    return errorResponse(`System prompt too long (${body.system_prompt.length} chars). Max is ${MAX_SYSTEM_PROMPT_LENGTH}.`, 413);
  }

  // Check balance (already fetched during auth)
  if (auth.words_remaining <= 0) {
    return jsonResponse(
      { error: "insufficient_balance", words_remaining: 0 },
      402
    );
  }

  // Build Gemini request
  const geminiBody = {
    system_instruction: {
      parts: [{ text: body.system_prompt || "" }],
    },
    contents: [
      {
        role: "user",
        parts: [
          {
            inline_data: {
              mime_type: "audio/flac",
              data: body.audio,
            },
          },
        ],
      },
    ],
  };

  const region = env.VERTEX_REGION || "us-central1";
  const host =
    region === "global"
      ? "aiplatform.googleapis.com"
      : `${region}-aiplatform.googleapis.com`;
  const geminiUrl = `https://${host}/v1/projects/${env.VERTEX_PROJECT_ID}/locations/${region}/publishers/google/models/${GEMINI_MODEL}:generateContent?key=${env.VERTEX_API_KEY}`;

  const geminiResponse = await fetch(geminiUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Vertex-AI-LLM-Request-Type": "shared",
      "X-Vertex-AI-LLM-Shared-Request-Type": "priority",
    },
    body: JSON.stringify(geminiBody),
  });

  if (!geminiResponse.ok) {
    const errorBody = await geminiResponse.text();
    console.error("Gemini request failed", {
      status: geminiResponse.status,
      statusText: geminiResponse.statusText,
      url: geminiUrl.replace(env.VERTEX_API_KEY, "[REDACTED]"),
      body: errorBody,
    });
    return errorResponse(
      `Transcription failed: ${errorBody}`,
      500
    );
  }

  const geminiResult = await geminiResponse.json<any>();
  const text: string =
    geminiResult?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? "";

  // Count words in the transcription
  const wordCount = text ? text.split(/\s+/).length : 0;

  // Deduct words and log usage in a single batch
  if (wordCount > 0) {
    const results = await env.DB.batch([
      env.DB.prepare(
        "UPDATE keys SET words_remaining = words_remaining - ? WHERE api_key = ? AND words_remaining >= ?"
      ).bind(wordCount, auth.key, wordCount),
      env.DB.prepare(
        "INSERT INTO usage (api_key, words_used, created_at) VALUES (?, ?, datetime('now'))"
      ).bind(auth.key, wordCount),
    ]);

    if (!results[0].meta.changed_db || results[0].meta.changes === 0) {
      return jsonResponse(
        { error: "insufficient_balance", words_remaining: auth.words_remaining },
        402
      );
    }
  }

  return jsonResponse({
    text,
    words_used: wordCount,
    words_remaining: auth.words_remaining - wordCount,
  });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    try {
      if (url.pathname === "/balance" && request.method === "GET") {
        return await handleBalance(request, env);
      }

      if (url.pathname === "/transcribe" && request.method === "POST") {
        return await handleTranscribe(request, env);
      }

      return errorResponse("Not found", 404);
    } catch (err) {
      console.error("Unhandled error", {
        path: url.pathname,
        method: request.method,
        message: err instanceof Error ? err.message : String(err),
        stack: err instanceof Error ? err.stack : undefined,
      });
      return errorResponse("Internal server error", 500);
    }
  },
} satisfies ExportedHandler<Env>;
