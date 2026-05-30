# AGENTS.md

## Commands

```bash
make build          # swift build
make test           # swift test
make coverage       # runs test_coverage.sh — enforces 100% executable line coverage on CometransCore
make dmg            # builds signed .app + DMG (requires code signing identity)
make release VERSION=v0.5.3  # coverage + dual-arch DMGs + git tag + gh release
make icon           # regenerates AppIcon.icns from SVG (requires librsvg)
```

Run a single test:

```bash
swift test --filter CometransTests.AppControllerTests
swift test --filter CometransTests.AppControllerTests/testProcessSelectionSuccess
```

CI runs `swift build -c release` then `swift test` on `macos-26` with Xcode 26.4.

## Architecture

Three SPM targets, zero external dependencies:

- **CometransCore** — models, protocols (`AIProvider`, `ClipboardServicing`, `HotKeyManaging`, `LaunchAtLoginControlling`), `AppController`. This is the testable core.
- **CometransMacSupport** — live macOS implementations: clipboard via AppKit/Accessibility, Carbon hotkeys, SMAppService launch-at-login, Apple Translation/Intelligence frameworks. Depends on CometransCore.
- **Cometrans** — SwiftUI executable: `CometransApp.swift` + `UI/` views. Depends on both above.

`AppController` is the central orchestrator. It owns settings, clipboard, and hotkey interactions. All provider and platform access goes through protocol contracts.

## Package.swift Gotchas

The `Cometrans` executable target uses explicit `sources` and `exclude` arrays. Adding a new `.swift` file under `Sources/Cometrans/` **requires** adding it to the `sources` list in `Package.swift` or it will not compile.

`Sources/Cometrans/` contains `Contracts/`, `Model/`, `Providers/`, `Services/` directories that are **excluded from the build** — these are legacy copies of files now owned by `CometransCore`. Do not edit them; edit the originals under `Sources/CometransCore/`.

## Testing

- Tests live in `Tests/CometransTests/` and depend **only on CometransCore**. Do not import CometransMacSupport or Cometrans in tests.
- `TestSupport.swift` provides mocks: `MockClipboardService`, `MockHotKeyManager`, `MockLaunchAtLoginController`, `StubAIProvider`, `DelayedStubAIProvider`.
- `make coverage` fails if any executable line in `Sources/CometransCore/` is uncovered. New code in CometransCore must have tests.

## Adding a New AI Provider

1. Add a case to `AIProviderType` in `Sources/CometransCore/Contracts/AIProvider.swift` (update all switch statements: `displayName`, `availableModels`, `defaultModel`).
2. Create the provider conforming to the `AIProvider` protocol. If it uses Apple frameworks, place it in `Sources/CometransMacSupport/`; otherwise in `Sources/CometransCore/Providers/`.
3. Register it in `AIProviderFactory` — either in `defaultBuilders` (for CometransCore providers) or in `LiveAppControllerFactory` (for CometransMacSupport providers).
4. Add tests in `Tests/CometransTests/AIProviderTests.swift`.

## Conventions

- No external dependencies. Use Foundation and Apple frameworks only.
- Callback-based async (completion handlers), not async/await.
- Platform: macOS 26+ (swift-tools-version 5.9).
- Version is managed in `version.txt`.
- App bundle identifier: `com.tomliu.cometrans`.
