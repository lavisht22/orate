//
//  RecordingStore.swift
//  orate
//
//  Created by Lavish Thakkar on 26/03/26.
//

import Foundation

struct RecordingMetadata: Codable {
    let id: String
    let timestamp: Date
    let transcript: String
    let latencyMs: Int
    let audioFile: String
    let audioSizeBytes: Int
    let model: String
    let usage: UsageMetadata
}

struct UsageMetadata: Codable {
    let promptTokenCount: Int
    let candidatesTokenCount: Int
    let totalTokenCount: Int
    let promptTokensDetails: [ModalityTokenCount]?
    let candidatesTokensDetails: [ModalityTokenCount]?
}

struct ModalityTokenCount: Codable {
    let modality: String
    let tokenCount: Int
}

struct RecordingStore {
    private static var recordingsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("orate/recordings")
    }

    static func save(audioData: Data, result: TranscriptionResult) throws {
        let dir = recordingsDirectory
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let id = UUID().uuidString
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let prefix = "\(formatter.string(from: Date()))-\(id.prefix(8))"

        let audioFileName = "\(prefix).flac"
        let audioURL = dir.appendingPathComponent(audioFileName)
        try audioData.write(to: audioURL)

        let metadata = RecordingMetadata(
            id: id,
            timestamp: Date(),
            transcript: result.transcript,
            latencyMs: result.latencyMs,
            audioFile: audioFileName,
            audioSizeBytes: audioData.count,
            model: result.model,
            usage: result.usage
        )

        let metadataURL = dir.appendingPathComponent("\(prefix).json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(metadata).write(to: metadataURL)
    }
}
