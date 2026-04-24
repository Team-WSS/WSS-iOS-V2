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

public final class DefaultRecommendationRepository: RecommendationRepository {
    
    private let service: RecommendationService
    private let logger: DataLogger?
    
    public init(service: RecommendationService,
                logger: DataLogger? = nil) {
        self.service = service
        self.logger = logger
    }
    
    public func fetchTodayDiscoveries() async throws(RepositoryError) -> [TodayDiscovery] {
        let action = RecommendationAction.fetchTodayDiscoveries
        
        do {
            let response = try await service.getTodayDiscovery()
            return RecommendationMapper.todayDiscoveryNovels(from: response)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.text, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.text, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.text, error: error)
            throw .unknown
        }
    }
    
    public func fetchTrendingFeeds() async throws(RepositoryError) -> [TrendingFeed] {
        let action = RecommendationAction.fetchTrendingFeeds
        
        do {
            let response = try await service.getTrendingFeeds()
            return RecommendationMapper.trendingFeeds(from: response)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.text, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.text, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.text, error: error)
            throw .unknown
        }
    }
    
    public func fetchInterestFeeds() async throws(RepositoryError) -> InterestFeedState {
        let action = RecommendationAction.fetchInterestFeeds
        
        do {
            let response = try await service.getInterestFeeds()
            return RecommendationMapper.interestFeeds(from: response)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.text, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.text, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.text, error: error)
            throw .unknown
        }
    }
    
    public func fetchPreferenceGenreNovels() async throws(RepositoryError) -> PreferenceGenreNovelState {
        let action = RecommendationAction.fetchPreferenceGenreNovels
        
        do {
            let response = try await service.getPreferenceGenreNovels()
            return RecommendationMapper.preferenceGenreNovels(from: response)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.text, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.text, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.text, error: error)
            throw .unknown
        }
    }
    
    public func fetchSosoPick() async throws(RepositoryError) -> [SosoPick] {
        let action = RecommendationAction.fetchSosoPick
        
        do {
            let response = try await service.getSosopickNovels()
            return RecommendationMapper.sosopickNovels(from: response)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.text, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.text, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.text, error: error)
            throw .unknown
        }
    }
}
