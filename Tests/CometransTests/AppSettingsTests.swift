import XCTest
@testable import CometransCore

final class AppSettingsTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "CometransTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testDefaultsLoadAndPersist() {
        let settings = AppSettings(userDefaults: userDefaults)

        XCTAssertEqual(settings.selectedProvider, .appleIntelligence)
        XCTAssertEqual(settings.shortcutActions.count, 3)
        XCTAssertEqual(settings.shortcutActions.first?.prompt, "")
        XCTAssertEqual(settings.shortcutActions.first?.providerOverride, .appleTranslation)
        XCTAssertTrue(settings.launchAtStartup)
        XCTAssertFalse(settings.hideMenuBarIcon)
        XCTAssertEqual(userDefaults.bool(forKey: AppSettings.Keys.launchAtStartup), true)

        settings.selectedProvider = .claude
        settings.setAPIKey("  abc123  ", for: .claude)
        settings.hideMenuBarIcon = true

        XCTAssertEqual(userDefaults.string(forKey: AppSettings.Keys.selectedProvider), "claude")
        XCTAssertTrue(userDefaults.bool(forKey: AppSettings.Keys.hideMenuBarIcon))
        let apiKeys = userDefaults.dictionary(forKey: AppSettings.Keys.apiKeys) as? [String: String]
        XCTAssertEqual(apiKeys?["claude"], "abc123")
        XCTAssertEqual(settings.currentAPIKey, "abc123")
    }

    func testLoadsSavedProviderAPIKeysAndActions() throws {
        userDefaults.set("grok", forKey: AppSettings.Keys.selectedProvider)
        userDefaults.set(["openai": "one", "grok": "two"], forKey: AppSettings.Keys.apiKeys)
        let savedAction = ShortcutAction(name: "Saved", keyCode: 12, modifiers: 256, prompt: "Prompt")
        userDefaults.set(try JSONEncoder().encode([savedAction]), forKey: AppSettings.Keys.shortcutActions)
        userDefaults.set(false, forKey: AppSettings.Keys.launchAtStartup)
        userDefaults.set(true, forKey: AppSettings.Keys.hideMenuBarIcon)

        let settings = AppSettings(userDefaults: userDefaults)

        XCTAssertEqual(settings.selectedProvider, .grok)
        XCTAssertEqual(settings.apiKeys[.openai], "one")
        XCTAssertEqual(settings.apiKeys[.grok], "two")
        XCTAssertEqual(settings.shortcutActions, [savedAction])
        XCTAssertFalse(settings.launchAtStartup)
        XCTAssertTrue(settings.hideMenuBarIcon)
    }

    func testLaunchAtStartupIntegrationAndError() {
        let successController = MockLaunchAtLoginController(isEnabled: true)
        let settings = AppSettings(userDefaults: userDefaults, launchAtLoginController: successController)

        XCTAssertTrue(settings.isLaunchAtStartupEnabled)

        settings.launchAtStartup = false
        XCTAssertEqual(successController.receivedValues, [false])

        let failingController = MockLaunchAtLoginController(error: TestError.failed)
        let failingSettings = AppSettings(userDefaults: userDefaults, launchAtLoginController: failingController)
        failingSettings.launchAtStartup = false

        XCTAssertEqual(failingSettings.launchAtStartupError, "boom")
    }

    func testLaunchAtStartupDefaultSynchronizesOnFirstLaunch() {
        let controller = MockLaunchAtLoginController(isEnabled: false)

        let settings = AppSettings(userDefaults: userDefaults, launchAtLoginController: controller)

        XCTAssertTrue(settings.launchAtStartup)
        XCTAssertEqual(controller.receivedValues, [true])
        XCTAssertTrue(controller.isEnabled)
    }

    func testLaunchAtStartupSynchronizationErrorDuringInitialization() {
        userDefaults.set(true, forKey: AppSettings.Keys.launchAtStartup)
        let controller = MockLaunchAtLoginController(isEnabled: false, error: TestError.failed)

        let settings = AppSettings(userDefaults: userDefaults, launchAtLoginController: controller)

        XCTAssertTrue(settings.launchAtStartup)
        XCTAssertEqual(controller.receivedValues, [true])
        XCTAssertEqual(settings.launchAtStartupError, "boom")
    }

    func testActionCrudAndLookup() {
        let provider = StubAIProvider()
        let factory = AIProviderFactory(providers: [.openai: provider])
        let settings = AppSettings(userDefaults: userDefaults, providerFactory: factory)
        let added = settings.addAction(from: ShortcutCatalog.templates[3])

        XCTAssertTrue(settings.currentProvider as AnyObject === provider)
        XCTAssertEqual(settings.actionForHotKey(keyCode: added.keyCode, modifiers: added.modifiers)?.name, "Summarize")

        var updated = added
        updated.name = "TL;DR"
        settings.updateAction(updated)
        XCTAssertEqual(settings.shortcutActions.first(where: { $0.id == updated.id })?.name, "TL;DR")
        settings.updateAction(ShortcutAction(name: "Ghost", keyCode: 2, modifiers: 256, prompt: "Prompt"))

        settings.moveAction(from: IndexSet(integer: settings.shortcutActions.count - 1), to: 0)
        XCTAssertEqual(settings.shortcutActions.first?.id, updated.id)

        settings.deleteAction(updated)
        XCTAssertNil(settings.shortcutActions.first(where: { $0.id == updated.id }))

        settings.resetToDefaults()
        XCTAssertEqual(settings.shortcutActions.map(\.name), ["Translate", "Improve Writing", "Fix Grammar"])
        XCTAssertEqual(settings.enabledActions.count, 2)
    }

    func testShortcutChangeCallbackAndLegacyMigration() throws {
        userDefaults.set("legacy-key", forKey: AppSettings.Keys.legacyAPIKey)
        userDefaults.set(UInt32(12), forKey: AppSettings.Keys.legacyShortcutKeyCode)
        userDefaults.set(UInt32(768), forKey: AppSettings.Keys.legacyShortcutModifiers)
        userDefaults.set("Legacy prompt", forKey: AppSettings.Keys.legacyPrompt)

        let settings = AppSettings(userDefaults: userDefaults)
        var callbackCount = 0
        settings.onShortcutsChanged = {
            callbackCount += 1
        }

        XCTAssertEqual(settings.apiKeys[.openai], "legacy-key")
        XCTAssertEqual(settings.shortcutActions.first?.keyCode, 12)
        XCTAssertNil(userDefaults.string(forKey: AppSettings.Keys.legacyAPIKey))

        settings.addAction(ShortcutAction(name: "Custom", keyCode: 0, modifiers: 256, prompt: "Prompt"))
        XCTAssertEqual(callbackCount, 1)

        let data = try XCTUnwrap(userDefaults.data(forKey: AppSettings.Keys.shortcutActions))
        let decoded = try JSONDecoder().decode([ShortcutAction].self, from: data)
        XCTAssertEqual(decoded.count, settings.shortcutActions.count)
    }

    func testNoopLaunchController() throws {
        let noop = NoopLaunchAtLoginController()

        XCTAssertFalse(noop.isEnabled)
        XCTAssertNoThrow(try noop.setEnabled(true))
    }

    func testInvalidSavedShortcutDataFallsBackToDefaults() {
        userDefaults.set(Data("invalid".utf8), forKey: AppSettings.Keys.shortcutActions)

        let settings = AppSettings(userDefaults: userDefaults)

        XCTAssertEqual(settings.shortcutActions.map(\.name), ["Translate", "Improve Writing", "Fix Grammar"])
    }

    func testMigratesDefaultTranslateActionToAppleTranslation() throws {
        let template = try XCTUnwrap(ShortcutCatalog.templates.first { $0.id == "translate" })
        let previousDefaultPrompt = "Translate the following text to natural, fluent English. If it is already in English, polish it for clarity while preserving the original meaning. Output only the translated text without any explanations, quotation marks, or commentary."
        let savedTranslate = ShortcutAction(
            name: template.name,
            keyCode: template.keyCode,
            modifiers: template.modifiers,
            prompt: previousDefaultPrompt,
            providerOverride: .appleIntelligence
        )
        let savedCustom = ShortcutAction(
            name: "Translate",
            keyCode: 31,
            modifiers: 768,
            prompt: "Custom prompt",
            providerOverride: .appleIntelligence
        )
        userDefaults.set(try JSONEncoder().encode([savedTranslate, savedCustom]), forKey: AppSettings.Keys.shortcutActions)

        let settings = AppSettings(userDefaults: userDefaults)

        XCTAssertEqual(settings.shortcutActions[0].prompt, "")
        XCTAssertEqual(settings.shortcutActions[0].providerOverride, .appleTranslation)
        XCTAssertEqual(settings.shortcutActions[1].providerOverride, .appleIntelligence)

        let data = try XCTUnwrap(userDefaults.data(forKey: AppSettings.Keys.shortcutActions))
        let decoded = try JSONDecoder().decode([ShortcutAction].self, from: data)
        XCTAssertEqual(decoded[0].prompt, "")
        XCTAssertEqual(decoded[0].providerOverride, .appleTranslation)
        XCTAssertEqual(decoded[1].providerOverride, .appleIntelligence)
    }

    func testLegacyMigrationKeepsExistingOpenAIKeyAndFallsBackPrompt() {
        userDefaults.set(["openai": "existing"], forKey: AppSettings.Keys.apiKeys)
        userDefaults.set("legacy-key", forKey: AppSettings.Keys.legacyAPIKey)
        userDefaults.set(UInt32(31), forKey: AppSettings.Keys.legacyShortcutKeyCode)
        userDefaults.set(UInt32(768), forKey: AppSettings.Keys.legacyShortcutModifiers)

        let settings = AppSettings(userDefaults: userDefaults)

        XCTAssertEqual(settings.apiKeys[.openai], "existing")
        XCTAssertEqual(settings.shortcutActions.first?.prompt, ShortcutCatalog.templates.first?.prompt)
    }
}
