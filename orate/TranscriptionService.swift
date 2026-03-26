//
//  TranscriptionService.swift
//  orate
//
//  Created by Lavish Thakkar on 26/03/26.
//

import Foundation

struct TranscriptionService {
    // TODO: Make configurable
    private static let apiKey = "AIzaSyD0QI6k-PzuTGFzx1_defFRVMLqq2OYuIw"
    private static let model = "gemini-3.1-flash-lite-preview"
    private static let prompt = "Transcribe this audio exactly as spoken. Output only the transcription text, nothing else."

    static func transcribe(audioData: Data) async throws -> String {
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
                        "mime_type": "audio/wav",
                        "data": base64Audio,
                    ]],
                ]
            ]]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

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

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
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
