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
                    switch model.availability {
                    case .available:
                        break
                    case .unavailable(let reason):
                        completion(.failure(.unknown(Self.message(for: reason))))
                        return
                    @unknown default:
                        completion(.failure(.unknown("Apple Intelligence availability is unknown.")))
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
                    completion(.failure(.unknown("Apple Intelligence error: \(error.localizedDescription)")))
                }
            }
            return
        }
        #endif
        completion(.failure(.unknown("Apple Intelligence requires macOS 26 (Tahoe) or later with Apple Silicon.")))
    }

    #if canImport(FoundationModels)
    @available(macOS 26.0, *)
    private static func message(for reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "Apple Intelligence isn't supported on this Mac (needs Apple Silicon M-series)."
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence is turned off. Enable it in System Settings → Apple Intelligence & Siri."
        case .modelNotReady:
            return "Apple Intelligence model is still downloading. Check progress in System Settings → Apple Intelligence & Siri."
        @unknown default:
            return "Apple Intelligence unavailable (reason: \(reason))."
        }
    }
    #endif
}
