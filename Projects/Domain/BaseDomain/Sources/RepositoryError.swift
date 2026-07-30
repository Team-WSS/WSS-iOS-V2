//
//  RepositoryError.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 2/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public enum RepositoryError: Error, Equatable {
    case networkUnavailable
    case authenticationRequired
    case serverUnavailable
    case invalidData
    case notFound
    /// 리소스는 존재하나 접근이 거부됨(HTTP 403 — 숨김 처리, 차단 등).
    case forbidden
    case unknown
}
