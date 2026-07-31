//
//  SearchAction.swift
//  SearchData
//
//  Created by Seoyeon Choi on 7/20/26.
//

import Logger

public enum SearchAction {
    case fetchRecentSearchWords
    case removeRecentSearchWord(String)
    case clearRecentSearchWords
    case searchAutoCompletionWords
    case searchNovelByText(query: String)
    case searchNovelByFilter

    var name: String {
        switch self {
        case .fetchRecentSearchWords:                   "최근 검색어 조회"
        case .removeRecentSearchWord(let word):         "최근 검색어 단일 삭제: \(word)"
        case .clearRecentSearchWords:                   "최근 검색어 전체 삭제"
        case .searchAutoCompletionWords:                "검색어 자동완성 조회"
        case .searchNovelByText(let query):             "'\(query)' 텍스트 검색"
        case .searchNovelByFilter:                       "필터 검색"
        }
    }
}
