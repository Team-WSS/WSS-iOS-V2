//
//  KeywordCache.swift
//  BaseData
//
//  Created by Seoyeon Choi on 5/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

struct KeywordCache {
    private let fileURL: URL

    init() {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.fileURL = cacheDir.appendingPathComponent("keywords.json")
    }
    
    func load() -> KeywordGroupsResponse? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(KeywordGroupsResponse.self, from: data)
    }

    func save(_ response: KeywordGroupsResponse) {
        guard let data = try? JSONEncoder().encode(response) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
