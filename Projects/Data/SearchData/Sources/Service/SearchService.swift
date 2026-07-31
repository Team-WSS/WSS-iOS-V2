//
//  SearchService.swift
//  SearchData
//
//  Created by Seoyeon Choi on 7/20/26.
//

import Foundation
import Networking

public protocol SearchService {
    func getRecentSearchWords() async throws -> RecentSearchWordsResponse
    func deleteRecentSearchWord(id: Int) async throws
    func deleteAllRecentSearchWords() async throws
    func getAutoCompletionWords(searchText: String) async throws -> SearchAutoCompletionWordsResponse

    func getNormalSearchNovels(query: NormalSearchQuery) async throws -> SearchNovelsResponse
    func getDetailSearchNovels(query: DetailSearchQuery) async throws -> SearchNovelsResponse
}
