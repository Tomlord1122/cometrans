import Foundation

public protocol AIProvider {
    static var identifier: String { get }
    static var displayName: String { get }

    func processText(
        text: String,
        instructions: String,
        completion: @escaping (Result<String, AIProviderError>) -> Void
    )
}

public enum AIProviderError: Error, LocalizedError, Equatable {
    case invalidAPIKey
    case networkError(String)
    case invalidResponse
    case rateLimited
    case serverError(Int)
    case noContent
    case unknown(String)

    public init(networkError error: Error) {
        self = .networkError(error.localizedDescription)
    }

    public var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please check your credentials."
        case .networkError(let description):
            return "Network error: \(description)"
        case .invalidResponse:
            return "Invalid response from the AI service."
        case .rateLimited:
            return "Rate limited. Please wait and try again."
        case .serverError(let code):
            return "Server error (code: \(code)). Please try again."
        case .noContent:
            return "No content in response."
        case .unknown(let message):
            return message
        }
    }
}

public enum AIProviderType: String, CaseIterable, Codable, Identifiable {
    case appleTranslation
    case appleIntelligence

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .appleTranslation: return "Apple Translation (on-device)"
        case .appleIntelligence: return "Apple Intelligence (on-device)"
        }
    }

    public var availableModels: [String] {
        switch self {
        case .appleTranslation:
            return ["auto-en-zh-Hant"]
        case .appleIntelligence:
            return ["system-default"]
        }
    }

    public var defaultModel: String {
        availableModels.first ?? ""
    }
}
