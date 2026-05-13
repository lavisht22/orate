//
//  SoundFeedback.swift
//  orate
//

import AppKit

final class SoundFeedback {
    static let shared = SoundFeedback()

    private init() {}

    func playStartSound() {
        NSSound(named: "Blow")?.play()
    }

    func playStopSound() {
        NSSound(named: "Submarine")?.play()
    }

    func playErrorSound() {
        NSSound(named: "Sosumi")?.play()
    }
}
