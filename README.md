# Orate

> *to write, by speaking.*

An open source macOS dictation app powered by **Google Gemini** — not Whisper. It listens to your voice natively, in every language you actually speak (yes, including hinglish), and types what you meant into the focused text field.

<p align="center">
  <a href="https://github.com/lavisht22/orate/releases/latest/download/Orate.dmg"><strong>↓ Download Orate</strong></a>
  &nbsp;·&nbsp;
  <a href="https://orate.app">orate.app</a>
  &nbsp;·&nbsp;
  <em>macOS 26.2+</em>
</p>

<p align="center">
  <a href="https://github.com/lavisht22/orate/releases/latest"><img src="https://img.shields.io/github/v/release/lavisht22/orate?style=flat-square&color=E94B3C&label=release" alt="Latest release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/lavisht22/orate?style=flat-square&color=15140F" alt="License"></a>
  <img src="https://img.shields.io/badge/swift-5-orange?style=flat-square&color=E94B3C" alt="Swift 5">
  <img src="https://img.shields.io/badge/macOS-26.2%2B-15140F?style=flat-square" alt="macOS 26.2+">
</p>

---

## Why orate exists

I built orate because every dictation app I tried butchered the way I speak. I think in English. Also Hindi. Sometimes Punjabi — half a sentence in one, half in another, the way a billion of us actually talk.

Every tool I tried flattened that. They all use OpenAI Whisper, trained on the internet's English. It hears hinglish and panics.

So I rebuilt dictation on **Gemini** — which listens to audio natively, instead of forcing it through speech-to-text first. It's slower than Whisper. It's also smarter — and it doesn't flatten the way you talk.

— [Lavish](https://github.com/lavisht22)

## How it works

1. **Hold Right Option (⌥)** to start recording
2. **Speak naturally** — code-switched, with "ums" and false starts. Don't worry.
3. **Release the key** — orate transcribes via Gemini and pastes into the focused text field, cleaned up.

No window switching. No copy-paste. Just talk and it appears wherever you're typing.

## What makes it different

- **A real LLM, not a transcriber.** Gemini understands what you *meant*, not just what you said. Fixes grammar, formats lists, handles dictated punctuation ("new line", "comma"), follows custom instructions.
- **Speaks every language you do.** Hinglish, Spanglish, Tagalog, Bengali, Tamil — code-switched mid-sentence. Whisper can't. Gemini does.
- **Custom instructions.** "Always use British spelling." "Format code in backticks." "Translate to French." Real rules that actually work, because there's a real LLM listening.
- **Custom vocabulary.** Add names, brands, jargon — they're always spelled correctly.
- **Works in any text field.** Slack, Mail, VS Code, Notion, your terminal. One menubar app, every text field on macOS.
- **Recording history.** Browse, replay, copy past transcriptions locally.
- **Push-to-talk.** Records only when you're holding the key. Nothing is always listening.

## Privacy & open source

The whole app is open source. Read it. Fork it. Build it yourself. Trust it because you can verify it — not because anyone asked you to.

Two paths to use it:

**1. Bring your own Google key** *(recommended)*
Your audio goes straight from your Mac to Google. You pay Google directly. **Orate never sees a thing** — not the audio, not the transcript, not the metadata. It can't. Use a free [Google AI Studio](https://aistudio.google.com/apikey) key, or Google Vertex AI for production volume.

**2. Orate API credits** *(coming soon)*
A thin wrapper around Vertex AI, built originally for friends without their own keys. Zero transcripts logged, ever. **No email required to purchase.** Buy credits, get an API key, done. Recharge the same key, or generate a new one every time. Source going public so you can self-host.

**No subscriptions. Ever.** Pay once for credits, use what you bought, come back when you need more. Subscriptions are extortion.

## Pricing

| | |
|---|---|
| **BYO Google key** | $0, forever. You pay Google directly. |
| **Orate API credits** *(coming soon)* | $10 / 200,000 words. ≈ two novels' worth, or a year of journaling. No expiry. |

## Install

1. **[Download the latest .dmg](https://github.com/lavisht22/orate/releases/latest/download/Orate.dmg)** *(macOS 26.2+)*
2. **Drag** Orate.app to your Applications folder
3. **Launch** Orate — onboarding will walk you through:
   - Microphone access
   - Accessibility permission (needed to paste into other apps)
   - Setting up your Gemini API key (free from [Google AI Studio](https://aistudio.google.com/apikey))

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| Hold **Right Option (⌥)** | Start recording |
| Release **Right Option (⌥)** | Stop recording, transcribe, and paste |
| **Esc** | Cancel the current recording |
| **⌃⌘V** | Re-paste the last transcription |

## Permissions

Orate needs two macOS permissions to work:

- **Microphone** — to record your voice. Only active while you're holding the push-to-talk key.
- **Accessibility** — to simulate ⌘V and paste transcribed text into the focused app. Without this, orate falls back to copying to your clipboard.

## Build from source

```bash
git clone https://github.com/lavisht22/orate.git
cd orate
xcodebuild -project orate.xcodeproj -scheme orate -configuration Debug build
```

Requires Xcode. Zero external dependencies — pure AppKit + SwiftUI + AVFoundation. See [CLAUDE.md](CLAUDE.md) for an architectural map of the codebase.

## Contribute

Issues, ideas, and PRs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## Links

- **Website** — [orate.app](https://orate.app)
- **Twitter** — [@lthakkar22](https://twitter.com/lthakkar22)
- **Email** — [lavisht22@gmail.com](mailto:lavisht22@gmail.com)
- **Issues** — [github.com/lavisht22/orate/issues](https://github.com/lavisht22/orate/issues)
- **Releases** — [github.com/lavisht22/orate/releases](https://github.com/lavisht22/orate/releases)

## License

MIT — see [LICENSE](LICENSE).

---

<p align="center">
  <em>Built with ♥ in Bharat 🇮🇳 · Powered by Gemini.</em>
</p>
