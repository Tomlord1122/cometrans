import CometransCore
import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

public final class AppleIntelligenceProvider: AIProvider {
    public static let identifier = "appleIntelligence"
    public static let displayName = "Apple Intelligence (on-device)"
    public static let apiKeyURL = "https://www.apple.com/apple-intelligence/"
    public static let apiKeyPlaceholder = ""

    public init() {}

    public func processText(
        text: String,
        apiKey: String,
        instructions: String,
        completion: @escaping (Result<String, AIProviderError>) -> Void
    ) {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            Task {
                do {
                    let model = SystemLanguageModel.default
                    guard case .available = model.availability else {
                        completion(.failure(.unknown("Apple Intelligence is not available on this device.")))
                        return
                    }

                    let session = LanguageModelSession(instructions: instructions)
                    let response = try await session.respond(to: text)
                    let output = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                    if output.isEmpty {
                        completion(.failure(.noContent))
                    } else {
                        completion(.success(output))
                    }
                } catch {
                    completion(.failure(.unknown(error.localizedDescription)))
                }
            }
            return
        }
        #endif
        completion(.failure(.unknown("Apple Intelligence requires macOS 26 (Tahoe) or later with Apple Silicon.")))
    }
}
