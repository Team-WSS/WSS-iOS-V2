//
//  RecommendationService.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 3/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import Networking

public protocol RecommendationService {
    func getTodayDiscovery() async throws -> TodayDiscoveryNovelsResponse
    func getTrendingFeeds() async throws -> TrendingFeedsResponse
    func getInterestFeeds() async throws -> InterestFeedsResponse
    func getPreferenceGenreNovels() async throws -> PreferenceGenreNovelsResponse
    func getSosopickNovels() async throws -> SosopickNovelsResponse
}

public struct DefaultRecommendationService: RecommendationService {
    
    private let network: NetworkingRequestable
    
    public init(network: NetworkingRequestable) {
        self.network = network
    }
    
    public func getTodayDiscovery() async throws -> TodayDiscoveryNovelsResponse {
        try await network.request(
            RecommendationEndpoint.getTodayDiscovery,
            decodeTo: TodayDiscoveryNovelsResponse.self
        )
    }
    
    public func getTrendingFeeds() async throws -> TrendingFeedsResponse {
        try await network.request(
            RecommendationEndpoint.getTrendingFeeds,
            decodeTo: TrendingFeedsResponse.self
        )
    }
    
    public func getInterestFeeds() async throws -> InterestFeedsResponse {
        try await network.request(
            RecommendationEndpoint.getInterestFeeds,
            decodeTo: InterestFeedsResponse.self
        )
    }
    
    public func getPreferenceGenreNovels() async throws -> PreferenceGenreNovelsResponse {
        try await network.request(
            RecommendationEndpoint.getPreferenceGenreNovels,
            decodeTo: PreferenceGenreNovelsResponse.self
        )
    }
    
    public func getSosopickNovels() async throws -> SosopickNovelsResponse {
        try await network.request(
            RecommendationEndpoint.sosopickNovels,
            decodeTo: SosopickNovelsResponse.self
        )
    }
}
