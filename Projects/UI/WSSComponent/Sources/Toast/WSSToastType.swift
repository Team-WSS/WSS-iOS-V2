//
//  WSSToastType.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import SwiftUI
import DesignSystem

public enum WSSToastType {
    case blockUser(nickname: String)
    case unknownUser
    case deleteBlockUser(nickname: String)
    /// 타유저 프로필의 컬렉션 섹션 — 컬렉션이 0개인 상대의 타이틀 행을 탭했을 때 안내
    /// (`UserPageFeature`, 사용자 확정).
    case noCollections
    /// 이미 신고한 피드에 같은 종류(스포일러/부적절)의 신고를 다시 시도했을 때(#255 QA —
    /// 서버 `REPORT-002` → `RepositoryError.alreadyReported`).
    case alreadyReportedFeed
    /// 이미 신고한 댓글에 같은 종류의 신고를 다시 시도했을 때(#255 QA — 서버 `REPORT-004` →
    /// `RepositoryError.alreadyReported`). 피드/댓글 문구를 분리해달라는 요청으로 `alreadyReportedFeed`와 나뉜다.
    case alreadyReportedComment

    case novelAlreadyConnected
    case selectionOverLimit(count: Int)
    case limitAddImage(limitCount: Int)
    case novelReviewed
    case novelReviewDeleted
    case feedEdited
    
    case changePublic
    case changePrivate
    case changeInfo
    case editProfile
    
    case networkDelay
    case unknownError
}
