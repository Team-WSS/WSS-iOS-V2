//
//  NovelService.swift
//  NovelData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol NovelService {
    func getUserLibraryNovels(userID: Int,
                              query: UserLibraryQuery) async throws -> UserLibraryNovelsResponse
    
    func getNovelBasicInfo(novelID: Int) async throws -> NovelBasicResponse
    func getNovelDetailInfo(novelID: Int) async throws -> NovelInfoResponse
    
    func getUserRegisteredNovelStats(userID: Int) async throws -> UserRegisteredNovelStatesResponse
    
    func postNovelInterest(novelID: Int) async throws
    func deleteNovelInterest(novelID: Int) async throws
    
    func getNormalSearchNovels(query: NormalSearchQuery) async throws -> SearchNovelsResponse
    func getDetailSearchNovels(query: DetailSearchQuery) async throws -> SearchNovelsResponse
}
