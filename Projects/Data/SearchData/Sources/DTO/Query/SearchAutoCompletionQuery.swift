//
//  SearchAutoCompletionQuery.swift
//  SearchData
//
//  Created by Seoyeon Choi on 7/20/26.
//

import Foundation
import Networking

struct SearchAutoCompletionQuery: QueryItemConvertible {
    public let query: String
    public let size: Int

    public init(query: String, size: Int) {
        self.query = query
        self.size = size
    }
}
