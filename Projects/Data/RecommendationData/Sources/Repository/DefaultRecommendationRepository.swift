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
import BaseData

public struct DefaultRecommendationRepository: RecommendationRepository {
    
    private let service: RecommendationService
    private let appStorage: AppStorage
    private let logger: DataLogger?

    public init(service: RecommendationService,
                appStorage: AppStorage,
                logger: DataLogger?) {
        self.service = service
        self.appStorage = appStorage
        self.logger = logger
    }

    public func fetchTodayDiscoveries() async throws(RepositoryError) -> [TodayDiscovery] {
        let action = RecommendationAction.fetchTodayDiscoveries

        do {
            let response = try await service.getTodayDiscovery()
            return try RecommendationMapper.todayDiscoveryNovels(from: response)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }
    
    public func fetchTrendingFeeds() async throws(RepositoryError) -> [TrendingFeed] {
        let action = RecommendationAction.fetchTrendingFeeds
        
        do {
            let response = try await service.getTrendingFeeds()
            return try RecommendationMapper.trendingFeeds(from: response)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }
    
    public func fetchInterestFeeds() async throws(RepositoryError) -> InterestFeedState {
        let action = RecommendationAction.fetchInterestFeeds
        
        do {
            let response = try await service.getInterestFeeds()
            return RecommendationMapper.interestFeeds(from: response)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }
    
    public func fetchPreferenceGenreNovels() async throws(RepositoryError) -> PreferenceGenreNovelState {
        let action = RecommendationAction.fetchPreferenceGenreNovels
        
        do {
            let response = try await service.getPreferenceGenreNovels()
            return RecommendationMapper.preferenceGenreNovels(from: response)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }
    
    public func fetchSosoPick() async throws(RepositoryError) -> [SosoPick] {
        let action = RecommendationAction.fetchSosoPick
        
        do {
            let response = try await service.getSosopickNovels()
            return RecommendationMapper.sosopickNovels(from: response)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    /// 로그인·프로필 저장 시 남겨둔 로컬 값을 그대로 읽는다(네트워크 없음).
    public func fetchCachedNickname() -> String? {
        appStorage.get(.nickname)
    }
}
