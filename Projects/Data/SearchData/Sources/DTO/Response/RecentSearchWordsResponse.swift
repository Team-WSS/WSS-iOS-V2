//
//  RecentSearchWordsResponse.swift
//  SearchData
//
//  Created by Seoyeon Choi on 7/20/26.
//

import Foundation

struct RecentSearchWordsResponse: Decodable {
    public let recentSearches: [RecentSearchWordResponse]
}

struct RecentSearchWordResponse: Decodable {
    public let id: Int
    public let keyword: String
}
