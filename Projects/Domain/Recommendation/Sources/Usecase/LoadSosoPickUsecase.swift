//
//  LoadSosoPickUsecase.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol LoadSosoPickUsecase {
    func execute() async throws -> [SosoPick]
}

public final class DefaultLoadSosoPickUsecase: LoadSosoPickUsecase {
    
    private let recommendationRepository: RecommendationRepository
    
    public init(recommendationRepository: RecommendationRepository) {
        self.recommendationRepository = recommendationRepository
    }
    
    public func execute() async throws -> [SosoPick] {
        return try await recommendationRepository.fetchSosoPick()
    }
}
