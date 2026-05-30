import Foundation
@testable import CometransCore

final class MockClipboardService: ClipboardServicing {
    var permissionGranted = true
    var copiedText: String?
    var pastedTexts: [String] = []
    var promptedValues: [Bool] = []

    func checkAccessibilityPermissions(prompt: Bool) -> Bool {
        promptedValues.append(prompt)
        return permissionGranted
    }

    func copySelectedText() -> String? {
        copiedText
    }

    func pasteText(_ text: String) {
        pastedTexts.append(text)
    }
}

final class MockHotKeyManager: HotKeyManaging {
    var isPaused = false
    var onTrigger: ((ShortcutAction) -> Void)?
    var registeredActionSets: [[ShortcutAction]] = []
    var unregisterCallCount = 0

    func registerHotKeys(for actions: [ShortcutAction]) {
        registeredActionSets.append(actions)
    }

    func unregisterAllHotKeys() {
        unregisterCallCount += 1
    }
}

final class MockLaunchAtLoginController: LaunchAtLoginControlling {
    var isEnabled: Bool
    var receivedValues: [Bool] = []
    var error: Error?

    init(isEnabled: Bool = false, error: Error? = nil) {
        self.isEnabled = isEnabled
        self.error = error
    }

    func setEnabled(_ enabled: Bool) throws {
        receivedValues.append(enabled)
        if let error {
            throw error
        }
        isEnabled = enabled
    }
}

final class StubAIProvider: AIProvider {
    static let identifier = "stub"
    static let displayName = "Stub"

    var nextResult: Result<String, AIProviderError> = .success("done")
    var receivedTexts: [String] = []
    var receivedInstructions: [String] = []

    func processText(
        text: String,
        instructions: String,
        completion: @escaping (Result<String, AIProviderError>) -> Void
    ) {
        receivedTexts.append(text)
        receivedInstructions.append(instructions)
        completion(nextResult)
    }
}

final class DelayedStubAIProvider: AIProvider {
    static let identifier = "delayed"
    static let displayName = "Delayed"

    var completion: ((Result<String, AIProviderError>) -> Void)?

    func processText(
        text: String,
        instructions: String,
        completion: @escaping (Result<String, AIProviderError>) -> Void
    ) {
        self.completion = completion
    }
}

enum TestError: Error, LocalizedError {
    case failed

    var errorDescription: String? {
        "boom"
    }
}
