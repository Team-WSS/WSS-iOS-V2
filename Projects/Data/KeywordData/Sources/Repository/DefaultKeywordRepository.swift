//
//  DefaultKeywordRepository.swift
//  KeywordData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import KeywordDomain
import BaseDomain
import BaseData

public struct DefaultKeywordRepository: KeywordRepository {
    
    private let keywordService: KeywordService
    private let logger: DataLogger?
    
    init(
        keywordService: KeywordService,
        logger: DataLogger?
    ) {
        self.keywordService = keywordService
        self.logger = logger
    }
    
    // 전체 키워드 조회
    public func fetchKeywords() async throws(RepositoryError) -> [KeywordGroup] {
        let action = KeywordAction.searchByText
        
        do {
            let query = SearchKeywordRequest(query: "")
            let response = try await keywordService.searchKeyword(query)
            return KeywordMapper.keywordGroups(from: response)
        } catch let error as NetworkingError{
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
    
    // 특정 키워드 검색
    public func searchKeywords(_ query: String) async throws(RepositoryError) -> [KeywordGroup] {
        let action = KeywordAction.searchByFilter
        
        do {
            let request = SearchKeywordRequest(query: query)
            let response = try await keywordService.searchKeyword(request)
            return KeywordMapper.keywordGroups(from: response)
        } catch let error as NetworkingError{
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
