//
//  OverlayPanel.swift
//  orate
//
//  Created by Lavish Thakkar on 26/03/26.
//

import AppKit
import QuartzCore

class OverlayPanel {
    private var panel: NSPanel?
    private var pillView: NSView?
    private var waveformBars: [CALayer] = []
    private var loadingDots: [CALayer] = []
    private var smoothedBarHeights: [CGFloat] = []
    private var waveformPhase: Double = 0

    private let idlePillHeight: CGFloat = 10
    private let activePillHeight: CGFloat = 34
    private let waveformBarCount = 11

    private(set) var isListening = false
    private(set) var isTranscribing = false
    private var errorDismissWork: DispatchWorkItem?

    func show() {
        guard panel == nil else { return }

        let idleSize = NSSize(width: 28, height: idlePillHeight)
        let pillView = NSView(frame: NSRect(origin: .zero, size: idleSize))
        pillView.wantsLayer = true
        pillView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.5).cgColor
        pillView.layer?.cornerRadius = idlePillHeight / 2
        self.pillView = pillView

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: idleSize),
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

        positionPanel(panel, size: idleSize)
        panel.orderFrontRegardless()
        self.panel = panel
    }

    func setListening(_ listening: Bool) {
        guard listening != isListening else { return }
        isListening = listening

        if listening {
            showWaveform()
        } else if !isTranscribing {
            showIdle()
        }
    }

    func setTranscribing(_ transcribing: Bool) {
        guard transcribing != isTranscribing else { return }
        isTranscribing = transcribing

        if transcribing {
            showLoading()
        } else {
            showIdle()
        }
    }

    func showError() {
        errorDismissWork?.cancel()
        isTranscribing = false
        isListening = false
        showErrorState()

        let work = DispatchWorkItem { [weak self] in
            self?.showIdle()
        }
        errorDismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: work)
    }

    // MARK: - States

    private func showIdle() {
        clearContent()
        let size = NSSize(width: 28, height: idlePillHeight)
        resizePill(to: size, cornerRadius: idlePillHeight / 2, bgAlpha: 0.5)
    }

    func updateLevel(_ level: CGFloat) {
        guard isListening, !waveformBars.isEmpty else { return }

        let boosted = pow(level, 0.4)
        waveformPhase += 0.15

        let minH: CGFloat = 3
        let maxH: CGFloat = activePillHeight - 6
        let smoothing: CGFloat = 0.2 // lower = smoother/slower

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for i in 0..<waveformBars.count {
            let center = CGFloat(waveformBars.count - 1) / 2.0
            let distFromCenter = abs(CGFloat(i) - center) / center // 0 at center, 1 at edges

            // Sine wave variation: each bar has a different phase offset
            let sine = CGFloat(sin(waveformPhase + Double(i) * 0.8))
            let variation = 0.7 + 0.3 * sine // oscillates 0.7…1.0

            // Center bars taller, edge bars shorter
            let shape = 1.0 - distFromCenter * 0.4

            let target = min(boosted * variation * shape, 1.0)
            let targetH = minH + (maxH - minH) * target

            // Exponential smoothing for gliding transitions
            let prev = smoothedBarHeights[i]
            let smoothed = prev + (targetH - prev) * smoothing
            smoothedBarHeights[i] = smoothed

            waveformBars[i].bounds.size.height = smoothed
        }
        CATransaction.commit()
    }

    private func showWaveform() {
        clearContent()
        smoothedBarHeights = Array(repeating: 3, count: waveformBarCount)
        waveformPhase = 0

        let barWidth: CGFloat = 2.5
        let barGap: CGFloat = 2
        let h = activePillHeight
        let barsWidth = CGFloat(waveformBarCount) * barWidth + CGFloat(waveformBarCount - 1) * barGap
        let pillWidth = barsWidth + 20

        resizePill(to: NSSize(width: pillWidth, height: h), cornerRadius: h / 2, bgAlpha: 0.75)

        guard let layer = pillView?.layer else { return }

        let startX = (pillWidth - barsWidth) / 2
        let minH: CGFloat = 3

        for i in 0..<waveformBarCount {
            let bar = CALayer()
            let cx = startX + CGFloat(i) * (barWidth + barGap) + barWidth / 2
            bar.bounds = CGRect(x: 0, y: 0, width: barWidth, height: minH)
            bar.position = CGPoint(x: cx, y: h / 2)
            bar.backgroundColor = NSColor.white.cgColor
            bar.cornerRadius = barWidth / 2
            layer.addSublayer(bar)
            waveformBars.append(bar)
        }
    }

    private func showLoading() {
        clearContent()

        let dotCount = 3
        let dotSize: CGFloat = 4
        let dotGap: CGFloat = 6
        let h = activePillHeight
        let dotsWidth = CGFloat(dotCount) * dotSize + CGFloat(dotCount - 1) * dotGap
        let pillWidth = dotsWidth + 28

        resizePill(to: NSSize(width: pillWidth, height: h), cornerRadius: h / 2, bgAlpha: 0.75)

        guard let layer = pillView?.layer else { return }

        let startX = (pillWidth - dotsWidth) / 2

        for i in 0..<dotCount {
            let dot = CALayer()
            let cx = startX + CGFloat(i) * (dotSize + dotGap) + dotSize / 2
            dot.bounds = CGRect(x: 0, y: 0, width: dotSize, height: dotSize)
            dot.position = CGPoint(x: cx, y: h / 2)
            dot.backgroundColor = NSColor.white.cgColor
            dot.cornerRadius = dotSize / 2
            dot.opacity = 0.3
            layer.addSublayer(dot)
            loadingDots.append(dot)

            let anim = CABasicAnimation(keyPath: "opacity")
            anim.fromValue = 0.3
            anim.toValue = 1.0
            anim.duration = 0.5
            anim.autoreverses = true
            anim.repeatCount = .infinity
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            anim.beginTime = CACurrentMediaTime() + Double(i) * 0.2
            dot.add(anim, forKey: "pulse")
        }
    }

    private func showErrorState() {
        clearContent()

        let h = activePillHeight
        let font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        let label = "Error"
        let textWidth = (label as NSString).size(withAttributes: [.font: font]).width
        let pillWidth = ceil(textWidth) + 24

        resizePill(to: NSSize(width: pillWidth, height: h), cornerRadius: h / 2, color: NSColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 0.9))

        guard let layer = pillView?.layer else { return }

        let textLayer = CATextLayer()
        textLayer.string = label
        textLayer.font = font
        textLayer.fontSize = 11
        textLayer.foregroundColor = NSColor.white.cgColor
        textLayer.alignmentMode = .center
        textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        let textHeight: CGFloat = 14
        textLayer.frame = CGRect(x: 12, y: (h - textHeight) / 2, width: ceil(textWidth), height: textHeight)
        layer.addSublayer(textLayer)
        waveformBars.append(textLayer)
    }

    // MARK: - Helpers

    private func clearContent() {
        waveformBars.forEach { $0.removeAllAnimations(); $0.removeFromSuperlayer() }
        waveformBars.removeAll()
        loadingDots.forEach { $0.removeAllAnimations(); $0.removeFromSuperlayer() }
        loadingDots.removeAll()
    }

    private func resizePill(to size: NSSize, cornerRadius: CGFloat, bgAlpha: CGFloat) {
        resizePill(to: size, cornerRadius: cornerRadius, color: NSColor.black.withAlphaComponent(bgAlpha))
    }

    private func resizePill(to size: NSSize, cornerRadius: CGFloat, color: NSColor) {
        guard let panel = panel, let pillView = pillView else { return }
        pillView.frame.size = size
        pillView.layer?.cornerRadius = cornerRadius
        pillView.layer?.backgroundColor = color.cgColor
        positionPanel(panel, size: size)
    }

    private func positionPanel(_ panel: NSPanel, size: NSSize) {
        guard let screen = NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame

        let x = visibleFrame.midX - size.width / 2
        let y = visibleFrame.origin.y + 8

        panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
    }
}
