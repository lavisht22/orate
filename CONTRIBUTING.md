# Contributing to Orate

Thanks for your interest. Orate is a small, intentionally indie project — contributions of all sizes are welcome.

## Bug reports & feature requests

Open an [issue](https://github.com/lavisht22/orate/issues). The more specific, the better:

- What were you doing?
- What did you expect?
- What actually happened?
- macOS version, orate version (find it under About)
- Steps to reproduce, if you can

A short screen recording is worth a thousand words for UI bugs.

## Pull requests

1. Fork the repo
2. Create a branch — `git checkout -b your-feature`
3. Make your changes
4. Build locally:
   ```bash
   xcodebuild -project orate.xcodeproj -scheme orate -configuration Debug build
   ```
5. Open a PR with a clear description of *what* you changed and *why*

For bigger changes (new screens, architectural shifts, new dependencies), please open an issue first to chat about the approach. Saves both of us time.

## Code style

- Match the existing patterns — see [CLAUDE.md](CLAUDE.md) for an architectural map.
- Views: `ScrollView` → `VStack(alignment: .leading, spacing: 24)` → `.padding(32)`.
- Subviews extracted as computed properties with `// MARK: -` headers.
- **Zero external dependencies.** AppKit + SwiftUI + AVFoundation only. Don't add Swift Package Manager deps without a very good reason.
- No tests yet, sorry. If you add tests for the area you're touching, even better.

## Voice & copy

If you're touching user-facing strings:

- Plain language, no AI buzzwords.
- "It just works" beats "leverages cutting-edge ML".
- Specific is better than abstract.

## Translations & localization

The app is currently English-only in its UI, even though it transcribes any language. If you want to localize the UI to another language, open an issue and we'll figure out the scaffolding together.

## Questions

Open a [discussion](https://github.com/lavisht22/orate/discussions) or email [lavisht22@gmail.com](mailto:lavisht22@gmail.com).
