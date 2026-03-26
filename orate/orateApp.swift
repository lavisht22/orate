//
//  orateApp.swift
//  orate
//
//  Created by Lavish Thakkar on 26/03/26.
//

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
    private var globalFlagMonitor: Any?
    private var localFlagMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            self.overlayPanel.show()
            self.startMonitoringHotkey()
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
        overlayPanel.setListening(pressed)
    }
}
