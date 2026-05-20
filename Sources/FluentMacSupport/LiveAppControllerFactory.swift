import FluentCore

public extension AppController {
    static func live() -> AppController {
        let factory = AIProviderFactory.live
        factory.register(.appleIntelligence) { _ in AppleIntelligenceProvider() }

        return AppController(
            settings: AppSettings(
                providerFactory: factory,
                launchAtLoginController: SMAppLaunchController()
            ),
            clipboardService: LiveClipboardService(),
            hotKeyManager: LiveHotKeyManager.shared
        )
    }
}
