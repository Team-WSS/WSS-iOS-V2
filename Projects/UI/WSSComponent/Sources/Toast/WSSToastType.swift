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
