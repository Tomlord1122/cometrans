import XCTest
@testable import CometransCore

final class AIProviderTests: XCTestCase {
    func testProviderMetadataAndErrors() {
        XCTAssertEqual(AIProviderType.allCases.map(\.displayName), [
            "Apple Translation (on-device)",
            "Apple Intelligence (on-device)"
        ])
        XCTAssertEqual(AIProviderType.appleTranslation.id, "appleTranslation")
        XCTAssertEqual(AIProviderType.appleIntelligence.id, "appleIntelligence")

        XCTAssertEqual(AIProviderError.invalidAPIKey.errorDescription, "Invalid API key. Please check your credentials.")
        XCTAssertEqual(AIProviderError(networkError: TestError.failed), .networkError("boom"))
        XCTAssertEqual(AIProviderError.networkError("boom").errorDescription, "Network error: boom")
        XCTAssertEqual(AIProviderError.invalidResponse.errorDescription, "Invalid response from the AI service.")
        XCTAssertEqual(AIProviderError.rateLimited.errorDescription, "Rate limited. Please wait and try again.")
        XCTAssertEqual(AIProviderError.serverError(500).errorDescription, "Server error (code: 500). Please try again.")
        XCTAssertEqual(AIProviderError.noContent.errorDescription, "No content in response.")
        XCTAssertEqual(AIProviderError.unknown("custom").errorDescription, "custom")
    }

    func testFactoryResolveRegisterAndFallback() {
        let appleStub = StubAIProvider()
        let otherStub = StubAIProvider()
        let factory = AIProviderFactory(providers: [.appleIntelligence: appleStub])

        XCTAssertTrue(factory.resolve(.appleTranslation) is StubAIProvider)
        factory.register(.appleTranslation, provider: otherStub)
        XCTAssertTrue(factory.resolve(.appleTranslation) as AnyObject === otherStub)
        XCTAssertEqual(factory.availableProviders, AIProviderType.allCases)
    }
}
