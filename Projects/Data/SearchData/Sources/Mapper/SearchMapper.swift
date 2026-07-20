//
//  SearchMapper.swift
//  SearchData
//
//  Created by Seoyeon Choi on 7/20/26.
//

import Foundation

import SearchDomain
import BaseDomain

public enum SearchMapper {

    // MARK: - 최근 검색어

    public static func recentSearchWords(from dto: RecentSearchWordsResponse) -> [RecentSearchWord] {
        dto.recentSearches.map { recentSearchWord(from: $0) }
    }

    static func recentSearchWord(from dto: RecentSearchWordResponse) -> RecentSearchWord {
        RecentSearchWord(id: SearchWordID(dto.id),
                         title: dto.keyword)
    }

    // MARK: - 검색어 자동완성

    public static func searchAutoCompletionWords(from dto: SearchAutoCompletionWordsResponse) -> [SearchAutoCompletionWord] {
        dto.keywords.map { SearchAutoCompletionWord(word: $0) }
    }
}
