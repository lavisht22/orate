//
//  OverlayPanel.swift
//  orate
//
//  Created by Lavish Thakkar on 26/03/26.
//

import AppKit

class OverlayPanel {
    private var panel: NSPanel?

    func show() {
        guard panel == nil else { return }

        let pillWidth: CGFloat = 70
        let pillHeight: CGFloat = 24

        let pillView = NSView(frame: NSRect(x: 0, y: 0, width: pillWidth, height: pillHeight))
        pillView.wantsLayer = true
        pillView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.8).cgColor
        pillView.layer?.cornerRadius = pillHeight / 2

        let dot = NSView(frame: NSRect(x: 8, y: 8, width: 8, height: 8))
        dot.wantsLayer = true
        dot.layer?.backgroundColor = NSColor.red.cgColor
        dot.layer?.cornerRadius = 4
        pillView.addSubview(dot)

        let label = NSTextField(labelWithString: "Orate")
        label.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        label.textColor = .white
        label.sizeToFit()
        label.frame.origin = NSPoint(x: 22, y: (pillHeight - label.frame.height) / 2)
        pillView.addSubview(label)

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: NSSize(width: pillWidth, height: pillHeight)),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = pillView
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        panel.ignoresMouseEvents = true

        positionPanel(panel)
        panel.orderFrontRegardless()
        self.panel = panel
    }

    private func positionPanel(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let menuBarHeight = screenFrame.maxY - screen.visibleFrame.maxY
        let panelSize = panel.frame.size

        let x = screenFrame.maxX - panelSize.width - 12
        let y = screenFrame.maxY - menuBarHeight - panelSize.height - 8

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
