//
//  orateApp.swift
//  orate
//
//  Created by Lavish Thakkar on 26/03/26.
//

import AppKit
import SwiftUI

@main
struct orateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .onAppear {
                    NSApplication.shared.setActivationPolicy(.regular)
                }
                .onDisappear {
                    NSApplication.shared.setActivationPolicy(.accessory)
                }
        }

        MenuBarExtra("Orate", systemImage: "waveform") {
            Button("Open Orate") {
                openWindow(id: "main")
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let overlayPanel = OverlayPanel()
    let audioRecorder = AudioRecorder()
    private var globalFlagMonitor: Any?
    private var localFlagMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            self.overlayPanel.show()
            self.startMonitoringHotkey()

            if !TextInserter.isAccessibilityGranted {
                TextInserter.promptForAccessibility()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    // Right Option key code — will be user-configurable in the future
    private let pushToTalkKeyCode: UInt16 = 61

    private func startMonitoringHotkey() {
        localFlagMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }

        globalFlagMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        guard event.keyCode == pushToTalkKeyCode else { return }
        let pressed = event.modifierFlags.contains(.option)

        if pressed {
            overlayPanel.setListening(true)
            audioRecorder.startRecording()
        } else {
            overlayPanel.setListening(false)
            finishRecording()
        }
    }

    private func finishRecording() {
        guard let audioData = audioRecorder.stopRecording() else {
            print("No audio data captured")
            return
        }

        overlayPanel.setTranscribing(true)

        Task {
            do {
                let transcription = try await TranscriptionService.transcribe(audioData: audioData)
                TextInserter.insertText(transcription)
                print("Transcription inserted: \(transcription)")
            } catch {
                print("Transcription failed: \(error)")
            }
            overlayPanel.setTranscribing(false)
        }
    }
}
