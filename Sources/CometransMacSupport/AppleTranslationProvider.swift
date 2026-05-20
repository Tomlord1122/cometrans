import CometransCore
import Foundation
#if canImport(NaturalLanguage)
import NaturalLanguage
#endif
#if canImport(Translation)
import Translation
#endif

public final class AppleTranslationProvider: AIProvider {
    public static let identifier = "appleTranslation"
    public static let displayName = "Apple Translation (on-device)"
    public static let apiKeyURL = "https://www.apple.com/apple-intelligence/"
    public static let apiKeyPlaceholder = ""

    public init() {}

    public func processText(
        text: String,
        apiKey: String,
        instructions: String,
        completion: @escaping (Result<String, AIProviderError>) -> Void
    ) {
        #if canImport(Translation)
        Task {
            do {
                let source = Self.sourceLanguage(for: text)
                let target = Self.targetLanguage(for: source)
                let session: TranslationSession

                if #available(macOS 26.4, *) {
                    session = TranslationSession(
                        installedSource: source,
                        target: target,
                        preferredStrategy: .lowLatency
                    )
                } else {
                    session = TranslationSession(installedSource: source, target: target)
                }

                if #available(macOS 26.0, *), await !session.isReady {
                    try await session.prepareTranslation()
                }

                let response = try await session.translate(text)
                let output = response.targetText.trimmingCharacters(in: .whitespacesAndNewlines)
                completion(output.isEmpty ? .failure(.noContent) : .success(output))
            } catch {
                completion(.failure(.unknown("Apple Translation error: \(error.localizedDescription)")))
            }
        }
        #else
        completion(.failure(.unknown("Apple Translation is unavailable on this macOS SDK.")))
        #endif
    }

    private static func sourceLanguage(for text: String) -> Locale.Language {
        #if canImport(NaturalLanguage)
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        if let language = recognizer.dominantLanguage {
            switch language {
            case .english:
                return Locale.Language(identifier: "en")
            case .simplifiedChinese, .traditionalChinese:
                return Locale.Language(identifier: "zh-Hant")
            case .japanese:
                return Locale.Language(identifier: "ja")
            case .korean:
                return Locale.Language(identifier: "ko")
            default:
                break
            }
        }
        #endif

        return containsHanCharacters(text) ? Locale.Language(identifier: "zh-Hant") : Locale.Language(identifier: "en")
    }

    private static func targetLanguage(for source: Locale.Language) -> Locale.Language {
        source.languageCode?.identifier == "en"
            ? Locale.Language(identifier: "zh-Hant")
            : Locale.Language(identifier: "en")
    }

    private static func containsHanCharacters(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0x4E00...0x9FFF).contains(Int(scalar.value))
        }
    }
}
