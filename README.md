# Orate

**Push to talk. Release to transcribe.**

Orate is a macOS app that turns your voice into text, anywhere. Hold a key, speak naturally, and release — your words appear in whatever app you're typing in, cleaned up and ready to go.

It's not a dumb transcriber. Orate uses an LLM (Google Gemini) to intelligently clean up your speech: fixing grammar, formatting lists, handling punctuation you dictate, and generally making your spoken words read like you typed them.

<p align="center">
<a href="https://github.com/lavisht22/orate/releases/latest/download/Orate.dmg"><strong>Download Orate</strong></a>&nbsp;&nbsp;(macOS 14+)
</p>

---

## How It Works

1. **Hold Right Option (&#x2325;)** to start recording
2. **Speak naturally** — say what you mean, don't worry about "um"s or false starts
3. **Release the key** — Orate transcribes your speech and pastes it into the focused text field

That's it. No window switching, no copy-pasting. Just talk and it appears.

## Features

- **Push-to-talk** — Record only when you want to. Nothing is always listening.
- **Smart transcription** — Powered by Gemini, so it cleans up filler words, fixes grammar, formats lists, and handles dictated punctuation ("new line", "comma", etc.)
- **Custom instructions** — Tell Orate how you want your text. "Always use British spelling." "Format code snippets in backticks." It follows your rules.
- **Custom vocabulary** — Add names, brands, or jargon so they're always spelled correctly.
- **Works everywhere** — Pastes directly into any text field in any app via the system clipboard.
- **Recording history** — Browse, replay, and copy past transcriptions.
- **Menu bar app** — Lives in your menu bar, stays out of your way.
- **Privacy-first** — Audio is sent directly to Google's API. Nothing is stored on any server. Recordings stay on your Mac.
- **Configurable hotkey** — Change the push-to-talk key to whatever works for you.

## Getting Started

1. **Download** the latest DMG from [Releases](https://github.com/lavisht22/orate/releases/latest)
2. **Drag** Orate.app to your Applications folder
3. **Launch** Orate — the onboarding flow will walk you through:
   - Granting microphone access
   - Granting accessibility permission (needed to paste text)
   - Setting up your Gemini API key (free from [Google AI Studio](https://aistudio.google.com/apikey))

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| Hold **Right Option (&#x2325;)** | Record |
| Release **Right Option (&#x2325;)** | Stop recording and transcribe |
| **Esc** | Cancel current recording |
| **&#x2303;&#x2318;V** | Re-paste last transcription |

## Permissions

Orate needs two permissions to work:

- **Microphone** — To record your voice. Orate only records while you hold the push-to-talk key.
- **Accessibility** — To simulate &#x2318;V and paste transcribed text into the active app. Without this, Orate falls back to copying text to your clipboard.

## Building from Source

```bash
# Clone the repo
git clone https://github.com/lavisht22/orate.git
cd orate

# Build
xcodebuild -project orate.xcodeproj -scheme orate -configuration Debug build
```

Requires Xcode and macOS 14+. No external dependencies.

## License

MIT
