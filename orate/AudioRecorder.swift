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
    private var meterTimer: Timer?

    /// Called on the main thread with a normalized audio level (0…1).
    var onLevel: ((CGFloat) -> Void)?

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
            rec.isMeteringEnabled = true
            rec.record()
            recorder = rec
            startMetering()
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    func stopRecording() -> Data? {
        stopMetering()
        guard let rec = recorder else { return nil }
        rec.stop()
        recorder = nil
        return try? Data(contentsOf: tempURL)
    }

    private func startMetering() {
        meterTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self, let rec = self.recorder else { return }
            rec.updateMeters()
            let db = rec.averagePower(forChannel: 0) // range: -160 … 0
            let clamped = max(-40.0, min(db, 0.0))
            let normalized = CGFloat((clamped + 40.0) / 40.0) // 0…1
            self.onLevel?(normalized)
        }
    }

    private func stopMetering() {
        meterTimer?.invalidate()
        meterTimer = nil
    }
}
