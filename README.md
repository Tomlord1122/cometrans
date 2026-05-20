# Cometrans

Cometrans is a native macOS menu bar app for AI-powered text transformations. Select text in any app, press a global shortcut, and Cometrans sends the selection to your chosen AI provider before pasting the result back in place.

It is built for macOS 26+ and is designed for everyday translation, rewriting, summarization, grammar fixes, and custom prompt-based text workflows.

## Features

- Native macOS menu bar app with global keyboard shortcuts.
- Works with selected text from other apps through the clipboard and Accessibility permissions.
- Built-in shortcut templates for translation, writing improvement, grammar fixes, summaries, and professional tone rewrites.
- Custom shortcuts with your own prompts, key combinations, provider overrides, and model choices.
- Provider settings for OpenAI, Anthropic Claude, Google Gemini, xAI Grok, OpenCode Go, and Apple Intelligence.
- Launch-at-login support and a dedicated settings window.

## Requirements

- macOS 26 or newer
- Xcode Command Line Tools for local development
- Accessibility permission for text capture and paste-back behavior
- An API key for cloud providers, unless using Apple Intelligence

## Getting Started

Run from source:

```bash
swift run Cometrans
```

Build and test:

```bash
make build
make test
```

After launching Cometrans:

1. Open Cometrans from the menu bar.
2. Grant Accessibility access in System Settings.
3. Choose a default AI provider in the Providers tab.
4. Add an API key if the provider requires one.
5. Configure shortcuts in the Shortcuts tab.

## Default Shortcuts

- `Cmd+Shift+O`: Translate
- `Cmd+Shift+I`: Improve Writing
- `Cmd+Shift+G`: Fix Grammar

Additional templates are available for summarizing text and making text sound more professional.

## Development Commands

```bash
make build
make test
make coverage
make dmg
make release VERSION=v0.4.0
```

Optional icon generation requires `librsvg`:

```bash
brew install librsvg
make icon
```

## Architecture

The package is split into three targets:

- `CometransCore`: models, settings, providers, controller logic, and testable contracts.
- `CometransMacSupport`: live macOS integrations for clipboard, hotkeys, launch at login, and Apple Intelligence.
- `Cometrans`: SwiftUI app shell, menu bar integration, and settings UI.

This keeps provider and shortcut logic testable while isolating platform-specific macOS behavior.

## Privacy

- API keys are stored locally on your Mac.
- Selected text is sent only to the AI provider configured for the shortcut.
- Apple Intelligence does not require an API key.
- Cometrans does not include analytics, telemetry, or a remote backend.

## License

MIT. See [LICENSE](LICENSE).
