//
//  DefaultSearchService.swift
//  SearchData
//
//  Created by Seoyeon Choi on 7/20/26.
//

import Foundation
import Networking

public struct DefaultSearchService: SearchService {

    private static let autoCompletionSize = 10

    private let network: NetworkingRequestable

    init(network: NetworkingRequestable) {
        self.network = network
    }

    public func getRecentSearchWords() async throws -> RecentSearchWordsResponse {
        try await network.request(
            SearchEndpoint.getRecentSearchWords,
            decodeTo: RecentSearchWordsResponse.self
        )
    }

    public func deleteRecentSearchWord(id: Int) async throws {
        _ = try await network.request(SearchEndpoint.deleteRecentSearchWord(id: id))
    }

    public func deleteAllRecentSearchWords() async throws {
        _ = try await network.request(SearchEndpoint.deleteAllRecentSearchWords)
    }

    public func getAutoCompletionWords(searchText: String) async throws -> SearchAutoCompletionWordsResponse {
        try await network.request(
            SearchEndpoint.getAutoCompletionWords(
                SearchAutoCompletionQuery(query: searchText, size: Self.autoCompletionSize)
            ),
            decodeTo: SearchAutoCompletionWordsResponse.self
        )
    }

    public func getNormalSearchNovels(query: NormalSearchQuery) async throws -> SearchNovelsResponse {
        try await network.request(SearchEndpoint.getNormalSearchResult(query), decodeTo: SearchNovelsResponse.self)
    }

    public func getDetailSearchNovels(query: DetailSearchQuery) async throws -> SearchNovelsResponse {
        try await network.request(SearchEndpoint.getDetailSearchResult(query), decodeTo: SearchNovelsResponse.self)
    }
}
