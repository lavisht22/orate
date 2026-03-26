//
//  AudioRecorder.swift
//  orate
//
//  Created by Lavish Thakkar on 26/03/26.
//

import AVFoundation

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    private var recorder: AVAudioRecorder?
    private let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("orate_recording.flac")

    func startRecording() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            guard granted else {
                print("Microphone permission denied")
                return
            }
            DispatchQueue.main.async {
                self?.beginRecording()
            }
        }
    }

    private func beginRecording() {
        try? FileManager.default.removeItem(at: tempURL)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatFLAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
        ]

        do {
            let rec = try AVAudioRecorder(url: tempURL, settings: settings)
            rec.delegate = self
            rec.record()
            recorder = rec
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    func stopRecording() -> Data? {
        guard let rec = recorder else { return nil }
        rec.stop()
        recorder = nil
        return try? Data(contentsOf: tempURL)
    }
}
