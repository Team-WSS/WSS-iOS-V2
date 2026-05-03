//
//  KeywordService.swift
//  BaseData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

protocol KeywordService {
    func searchKeyword(_ request: SearchKeywordRequest) async throws -> KeywordGroupsResponse
}
