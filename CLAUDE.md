# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is a macOS Swift app built with Xcode. No external dependencies.

```bash
# Build
xcodebuild -project orate.xcodeproj -scheme orate -configuration Debug build

# Run (after building)
open build/Debug/orate.app
# Or just build & run from Xcode
```

There are no tests currently.

## Architecture

**Orate** is a macOS push-to-talk voice transcription app. The user holds Right Option to record, releases to transcribe via Gemini API, and the result is pasted into the focused text field.

### Flow

1. **orateApp.swift** — Entry point. `AppDelegate` monitors Right Option key (keyCode 61) via `NSEvent` global/local monitors. On press→release, it orchestrates the record→transcribe→insert pipeline.
2. **AudioRecorder.swift** — Records microphone to a temporary WAV file (16kHz, mono, 16-bit PCM) using `AVAudioRecorder`.
3. **TranscriptionService.swift** — Sends base64-encoded audio to Google Gemini API (`generativelanguage.googleapis.com`), returns transcription text.
4. **TextInserter.swift** — Inserts text by setting clipboard + simulating Cmd+V via `CGEvent` (accessibility API). Restores previous clipboard after 0.2s. Falls back to clipboard-only if accessibility is denied.
5. **OverlayPanel.swift** — Always-on-top `NSPanel` pill in top-right corner showing state: idle (red) → listening (green) → transcribing (yellow).
6. **ContentView.swift** — Placeholder companion window (minimal).

### Key Design Decisions

- **App Sandbox disabled** — Required for accessibility (`AXIsProcessTrusted`) and `CGEvent` posting.
- **NSPanel over SwiftUI** for the overlay — avoids `NSHostingView` constraint issues with floating panels.
- **No external dependencies** — Uses only AVFoundation, AppKit, ApplicationServices, SwiftUI.
- **macOS 26.2+** deployment target, Swift 5 with `MainActor` default isolation.

### Permissions Required at Runtime

- Microphone access (`AVCaptureDevice.requestAccess`)
- Accessibility (`AXIsProcessTrusted` with prompt)
