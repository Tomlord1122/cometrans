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
    public init() {}

    public func processText(
        text: String,
        instructions: String,
        completion: @escaping (Result<String, AIProviderError>) -> Void
    ) {
        #if canImport(Translation)
        Task {
            do {
                let source = Self.sourceLanguage(for: text)
                let target = Self.targetLanguage(for: source)
                let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !trimmedText.isEmpty else {
                    completion(.failure(.noContent))
                    return
                }

                guard !Self.sameLanguage(source, target) else {
                    completion(.success(trimmedText))
                    return
                }

                let availability = Self.languageAvailability()
                let status = await availability.status(from: source, to: target)

                guard status != .unsupported else {
                    completion(.failure(.unknown("Apple Translation does not support \(Self.languageName(source)) to \(Self.languageName(target)) on this Mac.")))
                    return
                }

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

                let isReady = await session.isReady
                if status == .supported || !isReady {
                    try await session.prepareTranslation()
                }

                let response = try await session.translate(trimmedText)
                let output = response.targetText.trimmingCharacters(in: .whitespacesAndNewlines)
                completion(output.isEmpty ? .failure(.noContent) : .success(output))
            } catch {
                completion(.failure(.unknown("Apple Translation error: \(Self.errorMessage(for: error))")))
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
        return source.languageCode?.identifier == "en"
            ? Locale.Language(identifier: "zh-Hant")
            : Locale.Language(identifier: "en")
    }

    private static func sameLanguage(_ lhs: Locale.Language, _ rhs: Locale.Language) -> Bool {
        lhs.languageCode?.identifier == rhs.languageCode?.identifier
    }

    #if canImport(Translation)
    private static func languageAvailability() -> LanguageAvailability {
        if #available(macOS 26.4, *) {
            LanguageAvailability(preferredStrategy: .lowLatency)
        } else {
            LanguageAvailability()
        }
    }

    private static func errorMessage(for error: Error) -> String {
        let localized = error.localizedDescription
        let reason = (error as? LocalizedError)?.failureReason

        if let reason, !reason.isEmpty, reason != localized {
            return "\(localized) \(reason)"
        }

        return localized
    }
    #endif

    private static func languageName(_ language: Locale.Language) -> String {
        language.minimalIdentifier
    }

    private static func containsHanCharacters(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0x4E00...0x9FFF).contains(Int(scalar.value))
        }
    }
}
