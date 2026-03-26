//
//  OverlayPanel.swift
//  orate
//
//  Created by Lavish Thakkar on 26/03/26.
//

import AppKit

class OverlayPanel {
    private var panel: NSPanel?
    private var pillView: NSView?
    private var dotView: NSView?
    private var labelField: NSTextField?

    private let pillHeight: CGFloat = 24
    private let idleWidth: CGFloat = 70
    private let listeningWidth: CGFloat = 90
    private let transcribingWidth: CGFloat = 110

    private(set) var isListening = false
    private(set) var isTranscribing = false

    func show() {
        guard panel == nil else { return }

        let pillView = NSView(frame: NSRect(x: 0, y: 0, width: idleWidth, height: pillHeight))
        pillView.wantsLayer = true
        pillView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.8).cgColor
        pillView.layer?.cornerRadius = pillHeight / 2
        self.pillView = pillView

        let dot = NSView(frame: NSRect(x: 8, y: 8, width: 8, height: 8))
        dot.wantsLayer = true
        dot.layer?.backgroundColor = NSColor.red.cgColor
        dot.layer?.cornerRadius = 4
        pillView.addSubview(dot)
        self.dotView = dot

        let label = NSTextField(labelWithString: "Orate")
        label.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        label.textColor = .white
        label.sizeToFit()
        label.frame.origin = NSPoint(x: 22, y: (pillHeight - label.frame.height) / 2)
        pillView.addSubview(label)
        self.labelField = label

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: NSSize(width: idleWidth, height: pillHeight)),
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

    func setListening(_ listening: Bool) {
        guard listening != isListening else { return }
        isListening = listening

        if listening {
            updatePill(width: listeningWidth, label: "Listening", dotColor: .green)
        } else if !isTranscribing {
            updatePill(width: idleWidth, label: "Orate", dotColor: .red)
        }
    }

    func setTranscribing(_ transcribing: Bool) {
        guard transcribing != isTranscribing else { return }
        isTranscribing = transcribing

        if transcribing {
            updatePill(width: transcribingWidth, label: "Transcribing", dotColor: .yellow)
        } else {
            updatePill(width: idleWidth, label: "Orate", dotColor: .red)
        }
    }

    private func updatePill(width: CGFloat, label: String, dotColor: NSColor) {
        labelField?.stringValue = label
        labelField?.sizeToFit()
        dotView?.layer?.backgroundColor = dotColor.cgColor

        pillView?.frame.size.width = width

        guard let panel = panel else { return }
        var frame = panel.frame
        let oldWidth = frame.size.width
        frame.size.width = width
        frame.origin.x += oldWidth - width
        panel.setFrame(frame, display: true)
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
