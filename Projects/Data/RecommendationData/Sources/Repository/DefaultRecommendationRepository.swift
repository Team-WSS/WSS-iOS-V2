//
//  DefaultRecommendationRepository.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 3/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import RecommendationDomain
import BaseDomain
import Networking

public final class DefaultRecommendationRepository: RecommendationRepository {
    
    private let service: RecommendationService
    private let logger: RecommendationLogger?
    
    public init(service: RecommendationService,
                logger: RecommendationLogger? = nil) {
        self.service = service
        self.logger = logger
    }
    
    public func fetchTodayDiscoveries() async throws(RepositoryError) -> [TodayDiscovery] {
        do {
            let response = try await service.getTodayDiscovery()
            return RecommendationMapper.todayDiscoveryNovels(from: response)
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .load, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logError(type: .unknown, action: .load, error: error)
            throw .unknown
        }
    }
    
    public func fetchTrendingFeeds() async throws(RepositoryError) -> [TrendingFeed] {
        do {
            let response = try await service.getTrendingFeeds()
            return RecommendationMapper.trendingFeeds(from: response)
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .load, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logError(type: .unknown, action: .load, error: error)
            throw .unknown
        }
    }
    
    public func fetchInterestFeeds() async throws(RepositoryError) -> InterestFeedState {
        do {
            let response = try await service.getInterestFeeds()
            return RecommendationMapper.interestFeeds(from: response)
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .load, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logError(type: .unknown, action: .load, error: error)
            throw .unknown
        }
    }
    
    public func fetchPreferenceGenreNovels() async throws(RepositoryError) -> PreferenceGenreNovelState {
        do {
            let response = try await service.getPreferenceGenreNovels()
            return RecommendationMapper.preferenceGenreNovels(from: response)
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .load, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logError(type: .unknown, action: .load, error: error)
            throw .unknown
        }
    }
    
    public func fetchSosoPick() async throws(RepositoryError) -> [SosoPick] {
        do {
            let response = try await service.getSosopickNovels()
            return RecommendationMapper.sosopickNovels(from: response)
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .load, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logError(type: .unknown, action: .load, error: error)
            throw .unknown
        }
    }
}
