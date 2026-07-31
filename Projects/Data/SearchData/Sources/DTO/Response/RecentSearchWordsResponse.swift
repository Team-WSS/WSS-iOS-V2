//
//  RecentSearchWordsResponse.swift
//  SearchData
//
//  Created by Seoyeon Choi on 7/20/26.
//

import Foundation

public struct RecentSearchWordsResponse: Decodable {
    public let recentSearches: [RecentSearchWordResponse]
}

public struct RecentSearchWordResponse: Decodable {
    public let id: Int
    public let keyword: String
}
