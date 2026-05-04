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

    func load() throws(CacheError) -> KeywordGroupsResponse {
        guard let data = try? Data(contentsOf: fileURL) else {
            throw .fileNotFound
        }
        guard let decoded = try? JSONDecoder().decode(KeywordGroupsResponse.self, from: data) else {
            throw .decodingFailed
        }
        return decoded
    }

    func save(_ response: KeywordGroupsResponse) throws(CacheError) {
        guard let data = try? JSONEncoder().encode(response) else {
            throw .encodingFailed
        }
        guard let _ = try? data.write(to: fileURL, options: .atomic) else {
            throw .writeFailed
        }
    }
}
