# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

macOS Swift app, Xcode only, zero external dependencies.

```bash
# Build
xcodebuild -project orate.xcodeproj -scheme orate -configuration Debug build

# Run (after building)
open build/Debug/orate.app
# Or just build & run from Xcode
```

There are no tests currently.

## What Is Orate

A macOS push-to-talk voice transcription app. User holds Right Option to record, releases to transcribe via Gemini API, and the result is pasted into the focused text field. It's not a dumb transcriber — it uses an LLM (Gemini) with a system prompt to intelligently clean up speech, fix grammar, format lists, handle dictated punctuation, etc. Users can customize transcription behavior via custom instructions.

## File Map (all Swift files live in `orate/`)

| File | What It Does |
|---|---|
| `orateApp.swift` | Entry point. `@main` App struct with `WindowGroup` + `MenuBarExtra`. `AppDelegate` monitors Right Option key (keyCode 61) via `NSEvent` global/local flag monitors. Orchestrates the record→transcribe→insert pipeline. Also handles Esc to cancel, Ctrl+Cmd+V to re-paste last transcription. |
| `AudioRecorder.swift` | `AudioRecorder` class. Records mic to temp FLAC file (`orate_recording.flac` in tmp dir). 16kHz mono. Uses `AVAudioRecorder` with metering at 30fps. Exposes `onLevel: ((CGFloat) -> Void)?` callback with normalized 0…1 levels. |
| `TranscriptionService.swift` | Sends base64-encoded FLAC audio to Gemini API (`generativelanguage.googleapis.com/v1beta`). Uses `system_instruction` field for the system prompt. Returns `TranscriptionResult` with transcript, latency, model name, and token usage. Model: `gemini-3.1-flash-lite-preview`. API key read from Keychain. Throws `missingAPIKey` error if not configured. |
| `TextInserter.swift` | Inserts transcription text by: saving clipboard → setting text → simulating Cmd+V via `CGEvent` → restoring clipboard after 0.2s. Falls back to clipboard-only if accessibility isn't granted. All static methods. |
| `OverlayPanel.swift` | Floating `NSPanel` pill at bottom-center of screen (above dock). States: idle (tiny dark pill) → listening (expanded with animated waveform bars driven by mic levels) → transcribing (pulsing dots) → error (red pill with "Error" text, auto-dismisses after 3s). Pure AppKit + Core Animation, no SwiftUI. |
| `ContentView.swift` | Main window UI. `NavigationSplitView` with sidebar (`SidebarItem` enum) and detail area. Contains `HomeView` with welcome header and recording history list (play, copy, metadata). |
| `CustomInstructionsView.swift` | Settings screen for user custom instructions. `TextEditor` that saves to UserDefaults. Includes tappable example prompts. |
| `VocabularyView.swift` | Screen for managing custom vocabulary words. Users add words that should be spelled a specific way (names, brands, etc.). Words stored in UserDefaults as `"vocabularyWords"` array. Includes `FlowLayout` for wrapping word chips. |
| `SettingsView.swift` | Settings screen with API key configuration. Stores key securely in macOS Keychain via `KeychainHelper`. Includes link to Google AI Studio for key generation. Show/hide toggle for the key field. |
| `KeychainHelper.swift` | Thin wrapper around Security framework for Keychain CRUD. `save(key:value:)`, `read(key:)`, `delete(key:)`. Service identifier: `com.orate.app`. |
| `RecordingStore.swift` | Persists recordings to `~/Library/Application Support/orate/recordings/`. Each recording = one `.flac` audio file + one `.json` metadata file. Also defines `RecordingMetadata`, `UsageMetadata`, `ModalityTokenCount` structs. |
| `orate.entitlements` | Empty dict (sandbox disabled). |

## Architecture Details

### Pipeline Flow

```
Right Option pressed → AudioRecorder.startRecording()
Right Option released → AudioRecorder.stopRecording() → Data
  → TranscriptionService.transcribe(audioData:) → TranscriptionResult
  → TextInserter.insertText(result.transcript)
  → RecordingStore.save(audioData:result:)
```

All orchestration lives in `AppDelegate.finishRecording()` in `orateApp.swift`.

### UI Structure

- **Window**: `NavigationSplitView` with sidebar (min 160, ideal 180) and detail
- **Sidebar items**: `SidebarItem` enum in `ContentView.swift` — add cases here for new screens
- **Detail views**: Switch in `ContentView.body` maps sidebar selection → view
- **Current screens**: Home (`.home` → `HomeView`), Instructions (`.instructions` → `CustomInstructionsView`), Vocabulary (`.vocabulary` → `VocabularyView`), Settings (`.settings` → `SettingsView`)
- **Overlay pill**: Completely separate from the window — it's an `NSPanel` managed by `AppDelegate`
- **Menu bar**: `MenuBarExtra` in `orateApp.body` with Home, Paste Last, Quit

### Adding a New Screen

1. Add a case to `SidebarItem` enum in `ContentView.swift` (with `rawValue` for label and `icon` computed property)
2. Create the view file (follow existing pattern: `ScrollView` → `VStack(alignment: .leading, spacing: 24)` → `.padding(32)`)
3. Add the case to the `switch selection` in `ContentView.body`

### State & Persistence

| What | Where | Key/Path |
|---|---|---|
| Custom instructions | `UserDefaults` | `"customInstructions"` |
| Vocabulary words | `UserDefaults` | `"vocabularyWords"` |
| Gemini API key | macOS Keychain | `"geminiAPIKey"` (service: `com.orate.app`) |
| Recording history | Files on disk | `~/Library/Application Support/orate/recordings/*.json` + `*.flac` |
| Last transcription | `AppDelegate.lastTranscription` (in-memory `@Published`) | — |
| Overlay state | `OverlayPanel.isListening` / `.isTranscribing` (in-memory) | — |

### System Prompt

The system prompt lives in `TranscriptionService.systemPrompt` (private static let). `buildSystemInstruction()` assembles the final prompt by appending vocabulary words (as spelling hints) and custom instructions from UserDefaults. The prompt is sent via Gemini's `system_instruction` API field, separate from the audio content.

### Hotkey Monitoring

`AppDelegate` sets up 4 event monitors in `startMonitoringHotkey()`:
- 2 `flagsChanged` monitors (local + global) for Right Option push-to-talk
- 2 `keyDown` monitors (local + global) for Esc (cancel transcription) and Ctrl+Cmd+V (re-paste)

The push-to-talk key code (`61`) is stored in `AppDelegate.pushToTalkKeyCode` — planned to be user-configurable.

### Key Design Decisions

- **App Sandbox disabled** — Required for `AXIsProcessTrusted` and `CGEvent` posting
- **NSPanel over SwiftUI** for overlay — avoids `NSHostingView` constraint issues with floating panels
- **No external dependencies** — AVFoundation, AppKit, ApplicationServices, SwiftUI only
- **macOS 26.2+** deployment target, Swift 5 with `MainActor` default isolation
- **FLAC audio format** — Used for recording and sending to Gemini (compact, lossless)

### Permissions Required at Runtime

- Microphone access (`AVCaptureDevice.requestAccess`)
- Accessibility (`AXIsProcessTrusted` with prompt)

## Style Conventions

- Views use `ScrollView` → `VStack(alignment: .leading, spacing: 24)` → `.padding(32)` pattern
- Subviews extracted as computed properties with `// MARK: -` headers
- Card/row backgrounds: `.quaternary.opacity(0.5)` with `RoundedRectangle(cornerRadius: 8)`
- Metadata labels use `.caption` font + `.secondary` style + SF Symbols
- No storyboards, no XIBs — all UI is code (SwiftUI for window, AppKit for overlay)
