import CometransCore

public extension AppController {
    static func live() -> AppController {
        let factory = AIProviderFactory.live
        factory.register(.appleTranslation) { _ in AppleTranslationProvider() }
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
