//
//  orateApp.swift
//  orate
//
//  Created by Lavish Thakkar on 26/03/26.
//

import AppKit
import Combine
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
            Button("Home") {
                openWindow(id: "main")
            }
            Button("Paste Last Transcription (⌃⌘V)") {
                appDelegate.pasteLastTranscription()
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let overlayPanel = OverlayPanel()
    let audioRecorder = AudioRecorder()
    @Published var lastTranscription: String?
    private var globalFlagMonitor: Any?
    private var localFlagMonitor: Any?
    private var globalKeyMonitor: Any?
    private var localKeyMonitor: Any?
    private var transcriptionTask: Task<Void, Never>?

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

    func pasteLastTranscription() {
        guard let text = lastTranscription else { return }
        TextInserter.insertText(text)
    }

    private func startMonitoringHotkey() {
        localFlagMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }

        globalFlagMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleCancelKey(event) == true { return nil }
            if self?.handlePasteLastKey(event) == true { return nil }
            return event
        }

        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleCancelKey(event)
            self?.handlePasteLastKey(event)
        }
    }

    @discardableResult
    private func handleCancelKey(_ event: NSEvent) -> Bool {
        guard event.keyCode == 53, overlayPanel.isTranscribing else { return false }
        cancelTranscription()
        return true
    }

    // Ctrl+Cmd+V (keyCode 0x09 = V)
    @discardableResult
    private func handlePasteLastKey(_ event: NSEvent) -> Bool {
        guard event.keyCode == 0x09,
              event.modifierFlags.contains([.control, .command]),
              lastTranscription != nil else { return false }
        pasteLastTranscription()
        return true
    }

    private func cancelTranscription() {
        transcriptionTask?.cancel()
        transcriptionTask = nil
        overlayPanel.setTranscribing(false)
        print("Transcription cancelled by user")
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

        transcriptionTask = Task {
            do {
                let result = try await TranscriptionService.transcribe(audioData: audioData)
                try Task.checkCancellation()
                self.lastTranscription = result.transcript
                TextInserter.insertText(result.transcript)
                print("Transcription inserted (\(result.latencyMs)ms): \(result.transcript)")

                try RecordingStore.save(audioData: audioData, result: result)
            } catch is CancellationError {
                // Cancelled by user — already handled in cancelTranscription()
            } catch {
                print("Transcription failed: \(error)")
            }
            if !Task.isCancelled {
                overlayPanel.setTranscribing(false)
            }
            transcriptionTask = nil
        }
    }
}
