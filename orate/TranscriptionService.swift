//
//  TranscriptionService.swift
//  orate
//
//  Created by Lavish Thakkar on 26/03/26.
//

import Foundation

enum AIProvider: String, CaseIterable {
    case googleAI = "googleAI"
    case vertexAI = "vertexAI"

    var displayName: String {
        switch self {
        case .googleAI: "Google AI Studio"
        case .vertexAI: "Vertex AI"
        }
    }
}

struct TranscriptionResult {
    let transcript: String
    let latencyMs: Int
    let model: String
    let usage: UsageMetadata
}

struct TranscriptionService {
    static var provider: AIProvider {
        guard let raw = UserDefaults.standard.string(forKey: "aiProvider") else { return .googleAI }
        return AIProvider(rawValue: raw) ?? .googleAI
    }

    static var apiKey: String? {
        switch provider {
        case .googleAI: KeychainHelper.read(key: "geminiAPIKey")
        case .vertexAI: KeychainHelper.read(key: "vertexAPIKey")
        }
    }

    static var vertexProjectID: String? {
        UserDefaults.standard.string(forKey: "vertexProjectID")
    }

    static var vertexRegion: String {
        UserDefaults.standard.string(forKey: "vertexRegion") ?? "us-central1"
    }

    static let model = "gemini-3.1-flash-lite-preview"
    private static let systemPrompt = """
        You are Orate, an intelligent speech-to-text assistant. Your job is to transcribe spoken audio and produce clean, polished text ready to be inserted directly into whatever the user is typing.

        Core rules:
        - Transcribe the spoken content accurately, preserving the speaker's intended meaning.
        - Clean up speech disfluencies: remove filler words (um, uh, like, you know), false starts, and repeated words — unless they are clearly intentional for emphasis.
        - Fix grammar and punctuation naturally. Add proper capitalization, periods, commas, and other punctuation as appropriate for written text.
        - Do NOT add any preamble, commentary, labels, or formatting beyond the transcription itself. Output ONLY the final clean text.
        - Do NOT wrap the output in quotes or add "Transcription:" or similar prefixes.
        - If the speaker dictates punctuation explicitly (e.g. says "period", "comma", "new line", "question mark"), convert those to the actual punctuation characters.
        - CRITICAL: If the audio contains no spoken words (silence, background noise, breathing, typing, or other non-speech sounds), you MUST output an empty string. Do not generate any text whatsoever — not even from vocabulary hints or custom instructions. Only transcribe actual spoken words.
        - Preserve the speaker's tone and intent: if they are writing a casual message, keep it casual. If formal, keep it formal.
        - For numbers, use digits for quantities and measurements (e.g. "5 minutes", "200 users") and words for conversational usage (e.g. "a couple of things").
        - If the speaker is dictating a list (e.g. "first... second... third..." or "number one... number two..." or "bullet point..."), format the output as a properly structured list with line breaks and markers (1. 2. 3. or - bullets) as appropriate.
        """

    private static var customInstructions: String? {
        UserDefaults.standard.string(forKey: "customInstructions")
    }

    private static var vocabularyWords: [String] {
        UserDefaults.standard.stringArray(forKey: "vocabularyWords") ?? []
    }

    private static func buildSystemInstruction() -> String {
        var prompt = systemPrompt

        let vocab = vocabularyWords
        if !vocab.isEmpty {
            prompt += "\n\nVocabulary — the user has registered these custom words. When you hear something that sounds like one of these words, use the exact spelling provided here:\n"
            prompt += vocab.map { "- \($0)" }.joined(separator: "\n")
            prompt += "\nIMPORTANT: These vocabulary words are spelling hints ONLY. Do not use them to generate or infer content. If no speech is present in the audio, output an empty string regardless of these words."
        }

        if let custom = customInstructions, !custom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            prompt += "\n\nUser's custom instructions:\n\(custom)"
        }
        return prompt
    }

    private static func buildRequest(apiKey: String, base64Audio: String) throws -> URLRequest {
        let systemInstruction = buildSystemInstruction()

        let body: [String: Any] = [
            "system_instruction": [
                "parts": [
                    ["text": systemInstruction]
                ]
            ],
            "contents": [[
                "role": "user",
                "parts": [
                    ["inline_data": [
                        "mime_type": "audio/flac",
                        "data": base64Audio,
                    ]],
                ]
            ]]
        ]

        var request: URLRequest
        switch provider {
        case .googleAI:
            let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)")!
            request = URLRequest(url: url)
        case .vertexAI:
            guard let projectID = vertexProjectID, !projectID.isEmpty else {
                throw TranscriptionError.missingVertexConfig
            }
            let region = vertexRegion
            let host = region == "global"
                ? "aiplatform.googleapis.com"
                : "\(region)-aiplatform.googleapis.com"
            let url = URL(string: "https://\(host)/v1/projects/\(projectID)/locations/\(region)/publishers/google/models/\(model):generateContent?key=\(apiKey)")!
            request = URLRequest(url: url)
        }

        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    static func transcribe(audioData: Data) async throws -> TranscriptionResult {
        guard let apiKey, !apiKey.isEmpty else {
            throw TranscriptionError.missingAPIKey
        }

        let base64Audio = audioData.base64EncodedString()

        let request = try buildRequest(apiKey: apiKey, base64Audio: base64Audio)

        let start = ContinuousClock.now
        let (data, response) = try await URLSession.shared.data(for: request)
        let elapsed = start.duration(to: .now)
        let latencyMs = Int(elapsed.components.seconds * 1000 + elapsed.components.attoseconds / 1_000_000_000_000_000)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let responseBody = String(data: data, encoding: .utf8) ?? "no body"
            throw TranscriptionError.apiError(statusCode: statusCode, message: responseBody)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let candidates = json?["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String
        else {
            throw TranscriptionError.parseError
        }

        let usage = Self.parseUsageMetadata(from: json)

        return TranscriptionResult(
            transcript: text.trimmingCharacters(in: .whitespacesAndNewlines),
            latencyMs: latencyMs,
            model: model,
            usage: usage
        )
    }

    private static func parseUsageMetadata(from json: [String: Any]?) -> UsageMetadata {
        guard let usageMeta = json?["usageMetadata"] as? [String: Any] else {
            return UsageMetadata(promptTokenCount: 0, candidatesTokenCount: 0, totalTokenCount: 0, promptTokensDetails: nil, candidatesTokensDetails: nil)
        }

        let promptDetails = (usageMeta["promptTokensDetails"] as? [[String: Any]])?.compactMap { detail -> ModalityTokenCount? in
            guard let modality = detail["modality"] as? String, let count = detail["tokenCount"] as? Int else { return nil }
            return ModalityTokenCount(modality: modality, tokenCount: count)
        }

        let candidatesDetails = (usageMeta["candidatesTokensDetails"] as? [[String: Any]])?.compactMap { detail -> ModalityTokenCount? in
            guard let modality = detail["modality"] as? String, let count = detail["tokenCount"] as? Int else { return nil }
            return ModalityTokenCount(modality: modality, tokenCount: count)
        }

        return UsageMetadata(
            promptTokenCount: usageMeta["promptTokenCount"] as? Int ?? 0,
            candidatesTokenCount: usageMeta["candidatesTokenCount"] as? Int ?? 0,
            totalTokenCount: usageMeta["totalTokenCount"] as? Int ?? 0,
            promptTokensDetails: promptDetails,
            candidatesTokensDetails: candidatesDetails
        )
    }

    enum TranscriptionError: Error, LocalizedError {
        case missingAPIKey
        case missingVertexConfig
        case apiError(statusCode: Int, message: String)
        case parseError

        var errorDescription: String? {
            switch self {
            case .missingAPIKey: "No API key configured. Open Settings to add your API key."
            case .missingVertexConfig: "Vertex AI requires a Project ID. Open Settings to configure it."
            case .apiError(let code, let message): "API error (\(code)): \(message)"
            case .parseError: "Failed to parse transcription response"
            }
        }
    }
}
