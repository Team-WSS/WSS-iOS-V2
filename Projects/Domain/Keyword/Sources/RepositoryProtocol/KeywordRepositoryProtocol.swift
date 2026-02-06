//
//  KeywordRepositoryProtocol.swift
//  KeywordDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

public protocol KeywordRepositoryProtocol {
    func fetchKeyword(_ query: String?) async throws -> [KeywordGroup]
}
