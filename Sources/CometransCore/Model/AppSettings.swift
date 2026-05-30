import Combine
import Foundation

public final class AppSettings: ObservableObject {
    public let objectWillChange = ObservableObjectPublisher()

    public enum Keys {
        public static let selectedProvider = "selectedProvider"
        public static let shortcutActions = "shortcutActions"
        public static let launchAtStartup = "launchAtStartup"
        public static let hideMenuBarIcon = "hideMenuBarIcon"
        public static let legacyShortcutKeyCode = "shortcutKeyCode"
        public static let legacyShortcutModifiers = "shortcutModifiers"
        public static let legacyPrompt = "prompt"
    }

    public var selectedProvider: AIProviderType {
        didSet {
            objectWillChange.send()
            userDefaults.set(selectedProvider.rawValue, forKey: Keys.selectedProvider)
        }
    }

    public var shortcutActions: [ShortcutAction] {
        didSet {
            objectWillChange.send()
            saveShortcutActions()
        }
    }

    public var launchAtStartup: Bool {
        didSet {
            objectWillChange.send()
            userDefaults.set(launchAtStartup, forKey: Keys.launchAtStartup)
            do {
                try launchAtLoginController.setEnabled(launchAtStartup)
            } catch {
                launchAtStartupError = error.localizedDescription
            }
        }
    }

    public var hideMenuBarIcon: Bool {
        didSet {
            objectWillChange.send()
            userDefaults.set(hideMenuBarIcon, forKey: Keys.hideMenuBarIcon)
        }
    }

    public private(set) var launchAtStartupError: String? {
        didSet {
            objectWillChange.send()
        }
    }

    public var onShortcutsChanged: (() -> Void)?

    private let userDefaults: UserDefaults
    private let launchAtLoginController: LaunchAtLoginControlling
    private let providerFactory: AIProviderFactory

    public init(
        userDefaults: UserDefaults = .standard,
        providerFactory: AIProviderFactory = .live,
        launchAtLoginController: LaunchAtLoginControlling = NoopLaunchAtLoginController()
    ) {
        self.userDefaults = userDefaults
        self.providerFactory = providerFactory
        self.launchAtLoginController = launchAtLoginController

        if
            let rawProvider = userDefaults.string(forKey: Keys.selectedProvider),
            let provider = AIProviderType(rawValue: rawProvider)
        {
            selectedProvider = provider
        } else {
            selectedProvider = .appleIntelligence
        }

        shortcutActions = Self.loadShortcutActions(from: userDefaults)

        if userDefaults.object(forKey: Keys.launchAtStartup) != nil {
            launchAtStartup = userDefaults.bool(forKey: Keys.launchAtStartup)
        } else {
            launchAtStartup = true
            userDefaults.set(true, forKey: Keys.launchAtStartup)
        }

        hideMenuBarIcon = userDefaults.bool(forKey: Keys.hideMenuBarIcon)

        migrateLegacyValues()
        migrateDefaultTranslateAction()
        synchronizeLaunchAtStartupPreference()
    }

    public func provider(for type: AIProviderType) -> AIProvider {
        providerFactory.resolve(type)
    }

    public var currentProvider: AIProvider {
        provider(for: selectedProvider)
    }

    public var enabledActions: [ShortcutAction] {
        shortcutActions.filter(\.isEnabled)
    }

    public var isLaunchAtStartupEnabled: Bool {
        launchAtLoginController.isEnabled
    }

    public func addAction(_ action: ShortcutAction) {
        shortcutActions.append(action)
    }

    public func addAction(from template: ShortcutTemplate) -> ShortcutAction {
        let action = template.makeAction()
        addAction(action)
        return action
    }

    public func updateAction(_ action: ShortcutAction) {
        guard let index = shortcutActions.firstIndex(where: { $0.id == action.id }) else {
            return
        }

        shortcutActions[index] = action
    }

    public func deleteAction(_ action: ShortcutAction) {
        shortcutActions.removeAll { $0.id == action.id }
    }

    public func moveAction(from source: IndexSet, to destination: Int) {
        let items = source.map { shortcutActions[$0] }
        shortcutActions = shortcutActions.enumerated().filter { !source.contains($0.offset) }.map(\.element)

        let targetIndex = min(destination, shortcutActions.count)
        shortcutActions.insert(contentsOf: items, at: targetIndex)
    }

    public func resetToDefaults() {
        shortcutActions = ShortcutCatalog.defaults
    }

    public func actionForHotKey(keyCode: UInt32, modifiers: UInt32) -> ShortcutAction? {
        enabledActions.first { $0.keyCode == keyCode && $0.modifiers == modifiers }
    }

    private func saveShortcutActions() {
        if let data = try? JSONEncoder().encode(shortcutActions) {
            userDefaults.set(data, forKey: Keys.shortcutActions)
        }
        onShortcutsChanged?()
    }

    private static func loadShortcutActions(from userDefaults: UserDefaults) -> [ShortcutAction] {
        if
            let data = userDefaults.data(forKey: Keys.shortcutActions),
            let decoded = try? JSONDecoder().decode([ShortcutAction].self, from: data)
        {
            return decoded
        }

        if userDefaults.object(forKey: Keys.legacyShortcutKeyCode) != nil {
            let keyCode = userDefaults.object(forKey: Keys.legacyShortcutKeyCode) as? UInt32 ?? 31
            let modifiers = userDefaults.object(forKey: Keys.legacyShortcutModifiers) as? UInt32 ?? 768
            let prompt = userDefaults.string(forKey: Keys.legacyPrompt)
                ?? ShortcutCatalog.templates.first!.prompt

            return [
                ShortcutAction(
                    name: "Translate",
                    keyCode: keyCode,
                    modifiers: modifiers,
                    prompt: prompt
                )
            ]
        }

        return ShortcutCatalog.defaults
    }

    private func migrateLegacyValues() {
        if userDefaults.object(forKey: Keys.legacyShortcutKeyCode) != nil {
            userDefaults.removeObject(forKey: Keys.legacyShortcutKeyCode)
            userDefaults.removeObject(forKey: Keys.legacyShortcutModifiers)
            userDefaults.removeObject(forKey: Keys.legacyPrompt)
            saveShortcutActions()
        }
    }

    private func migrateDefaultTranslateAction() {
        guard let template = ShortcutCatalog.templates.first(where: { $0.id == "translate" }) else { return }
        let previousDefaultPrompt = "Translate the following text to natural, fluent English. If it is already in English, polish it for clarity while preserving the original meaning. Output only the translated text without any explanations, quotation marks, or commentary."

        var migratedActions = shortcutActions
        var didMigrate = false

        for index in migratedActions.indices {
            let action = migratedActions[index]
            guard
                action.name == template.name,
                action.keyCode == template.keyCode,
                action.modifiers == template.modifiers,
                action.prompt == previousDefaultPrompt || action.prompt == template.prompt,
                action.providerOverride == nil || action.providerOverride == .appleIntelligence || action.providerOverride == .appleTranslation
            else {
                continue
            }

            migratedActions[index].prompt = template.prompt
            migratedActions[index].providerOverride = template.providerOverride
            didMigrate = true
        }

        if didMigrate {
            shortcutActions = migratedActions
        }
    }

    private func synchronizeLaunchAtStartupPreference() {
        guard launchAtLoginController.isEnabled != launchAtStartup else { return }

        do {
            try launchAtLoginController.setEnabled(launchAtStartup)
            launchAtStartupError = nil
        } catch {
            launchAtStartupError = error.localizedDescription
        }
    }
}
