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

    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            self.overlayPanel.show()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
