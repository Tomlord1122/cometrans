import Foundation

public final class AIProviderFactory {
    public static let live = AIProviderFactory()

    public typealias Builder = (_ model: String) -> AIProvider

    private var builders: [AIProviderType: Builder]

    public init(builders: [AIProviderType: Builder] = AIProviderFactory.defaultBuilders) {
        self.builders = builders
    }

    public convenience init(providers: [AIProviderType: AIProvider]) {
        let builders = providers.reduce(into: [AIProviderType: Builder]()) { acc, entry in
            let instance = entry.value
            acc[entry.key] = { _ in instance }
        }
        self.init(builders: builders)
    }

    public static var defaultBuilders: [AIProviderType: Builder] {
        [:]
    }

    public func register(_ type: AIProviderType, builder: @escaping Builder) {
        builders[type] = builder
    }

    public func register(_ type: AIProviderType, provider: AIProvider) {
        builders[type] = { _ in provider }
    }

    public func resolve(_ type: AIProviderType, model: String) -> AIProvider {
        if let builder = builders[type] {
            return builder(model)
        }
        return builders[.appleIntelligence]!(AIProviderType.appleIntelligence.defaultModel)
    }

    public func resolve(_ type: AIProviderType) -> AIProvider {
        resolve(type, model: type.defaultModel)
    }

    public var availableProviders: [AIProviderType] {
        AIProviderType.allCases
    }
}
