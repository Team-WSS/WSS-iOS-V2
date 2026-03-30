@testable import RecommendationData

final class MockRecommendationLogger: RecommendationLogger {
    struct LoggedError: Equatable {
        let type: RecommendationErrorType
        let action: RecommendationAction
    }

    private(set) var loggedErrors: [LoggedError] = []

    func logError(
        type: RecommendationErrorType,
        action: RecommendationAction,
        error: Error?
    ) {
        loggedErrors.append(
            LoggedError(type: type, action: action)
        )
    }
}
