//
//  RepositoryError.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 2/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public enum RepositoryError: Error, Equatable, Sendable {
    case networkUnavailable
    case authenticationRequired
    case serverUnavailable
    case invalidData
    case notFound
    /// 리소스는 존재하나 접근이 거부됨(HTTP 403 — 숨김 처리, 차단 등).
    case forbidden
    /// 대상 리소스가 비공개로 설정되어 있어 접근할 수 없음(예: 상대가 프로필을 비공개로 전환).
    /// 인증 문제(`authenticationRequired`)와 달리 재로그인으로 해결되지 않는다.
    case privateProfile
    case unknown
}
