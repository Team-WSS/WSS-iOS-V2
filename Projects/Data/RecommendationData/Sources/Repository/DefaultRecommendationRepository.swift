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

struct DefaultRecommendationRepository: RecommendationRepository {
    
    private let service: RecommendationService
    private let appStorage: AppStorage
    private let logger: DataLogger?
    /// 런치 부트스트랩이 채워두는 single-shot 프리페치 저장고(#225). 주입 안 되면(nil) 항상 네트워크.
    private let prefetchStore: HomePrefetchStore?

    public init(service: RecommendationService,
                appStorage: AppStorage,
                logger: DataLogger?,
                prefetchStore: HomePrefetchStore? = nil) {
        self.service = service
        self.appStorage = appStorage
        self.logger = logger
        self.prefetchStore = prefetchStore
    }

    public func fetchTodayDiscoveries() async throws(RepositoryError) -> [TodayDiscovery] {
        // 부트스트랩 프리페치가 착지해 있으면 소비(single-shot — 이후 호출은 전부 네트워크).
        if let prefetched = await prefetchStore?.consumeTodayDiscoveries() {
            return prefetched
        }

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
        // 부트스트랩 프리페치가 착지해 있으면 소비(single-shot — 이후 호출은 전부 네트워크).
        if let prefetched = await prefetchStore?.consumeTrendingFeeds() {
            return prefetched
        }

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
