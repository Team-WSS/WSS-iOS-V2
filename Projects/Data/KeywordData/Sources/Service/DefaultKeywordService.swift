//
//  DefaultKeywordService.swift
//  KeywordData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

public struct DefaultKeywordService: KeywordService {

    private let client: NetworkingRequestable

    init(client: NetworkingRequestable) {
        self.client = client
    }

    func searchKeyword(_ request: SearchKeywordRequest) async throws -> KeywordGroupsResponse {
        let endpoint = KeywordEndpoint.searchKeywords(request)
        return try await client.request(endpoint,
                                        decodeTo: KeywordGroupsResponse.self)
    }
}
