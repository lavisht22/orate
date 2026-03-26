//
//  TranscriptionService.swift
//  orate
//
//  Created by Lavish Thakkar on 26/03/26.
//

import Foundation

struct TranscriptionResult {
    let transcript: String
    let latencyMs: Int
    let model: String
    let usage: UsageMetadata
}

struct TranscriptionService {
    // TODO: Make configurable
    private static let apiKey = "AIzaSyD0QI6k-PzuTGFzx1_defFRVMLqq2OYuIw"
    static let model = "gemini-3.1-flash-lite-preview"
    private static let prompt = "Transcribe this audio exactly as spoken. Output only the transcription text, nothing else."

    static func transcribe(audioData: Data) async throws -> TranscriptionResult {
        let base64Audio = audioData.base64EncodedString()

        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": prompt],
                    ["inline_data": [
                        "mime_type": "audio/flac",
                        "data": base64Audio,
                    ]],
                ]
            ]]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

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
        case apiError(statusCode: Int, message: String)
        case parseError

        var errorDescription: String? {
            switch self {
            case .apiError(let code, let message): "Gemini API error (\(code)): \(message)"
            case .parseError: "Failed to parse transcription response"
            }
        }
    }
}
