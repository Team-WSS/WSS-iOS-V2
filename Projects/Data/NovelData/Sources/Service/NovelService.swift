//
//  NovelService.swift
//  NovelData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

protocol NovelService: Sendable {
    func getUserLibraryNovels(userID: Int,
                              query: UserLibraryQuery) async throws -> UserLibraryNovelsResponse
    func getUserLibraryNovelsV2(userID: Int,
                                query: UserLibraryV2Query) async throws -> UserLibraryNovelsV2Response
    func getUserLibraryKeywords(userID: Int) async throws -> LibraryKeywordsResponse

    func getNovelBasicInfo(novelID: Int) async throws -> NovelBasicResponse
    func getNovelDetailInfo(novelID: Int) async throws -> NovelInfoResponse
    
    func getUserRegisteredNovelStats(userID: Int) async throws -> UserRegisteredNovelStatesResponse
    
    func postNovelInterest(novelID: Int) async throws
    func deleteNovelInterest(novelID: Int) async throws
}
