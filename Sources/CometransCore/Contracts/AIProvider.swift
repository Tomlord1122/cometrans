import Foundation

public protocol AIProvider {
    static var identifier: String { get }
    static var displayName: String { get }
    static var apiKeyURL: String { get }
    static var apiKeyPlaceholder: String { get }

    func processText(
        text: String,
        apiKey: String,
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
    case openai
    case claude
    case gemini
    case grok
    case opencode
    case appleIntelligence

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .openai: return "OpenAI (GPT)"
        case .claude: return "Anthropic (Claude)"
        case .gemini: return "Google (Gemini)"
        case .grok: return "xAI (Grok)"
        case .opencode: return "opencode"
        case .appleIntelligence: return "Apple Intelligence (on-device)"
        }
    }

    public var apiKeyURL: String {
        switch self {
        case .openai: return "https://platform.openai.com/api-keys"
        case .claude: return "https://console.anthropic.com/api-keys"
        case .gemini: return "https://aistudio.google.com/apikey"
        case .grok: return "https://console.x.ai"
        case .opencode: return "https://opencode.ai"
        case .appleIntelligence: return "https://www.apple.com/apple-intelligence/"
        }
    }

    public var apiKeyPlaceholder: String {
        switch self {
        case .openai: return "sk-..."
        case .claude: return "sk-ant-..."
        case .gemini: return "AI..."
        case .grok: return "xai-..."
        case .opencode: return "oc-..."
        case .appleIntelligence: return ""
        }
    }

    public var requiresAPIKey: Bool {
        self != .appleIntelligence
    }

    public var availableModels: [String] {
        switch self {
        case .openai:
            return [
                "gpt-5.4-mini",
                "gpt-5.4-nano",
                "gpt-5.5",
                "gpt-5.5-pro",
                "gpt-5.3-chat-latest",
                "gpt-5.2"
            ]
        case .claude:
            return [
                "claude-haiku-4-5",
                "claude-sonnet-4-6",
                "claude-opus-4-7",
                "claude-opus-4-6"
            ]
        case .gemini:
            return [
                "gemini-2.5-flash",
                "gemini-2.5-pro",
                "gemini-3.1-flash-lite",
                "gemini-3.1-pro"
            ]
        case .grok:
            return [
                "grok-4.3",
                "grok-4.1",
                "grok-4.1-mini",
                "grok-4-1-fast-reasoning",
                "grok-4-1-fast-non-reasoning"
            ]
        case .opencode:
            return [
                "anthropic/claude-haiku-4-5",
                "anthropic/claude-sonnet-4-6",
                "anthropic/claude-opus-4-7",
                "openai/gpt-5.4-mini",
                "openai/gpt-5.5",
                "google/gemini-2.5-flash",
                "xai/grok-4.3"
            ]
        case .appleIntelligence:
            return ["system-default"]
        }
    }

    public var defaultModel: String {
        availableModels.first ?? ""
    }
}
