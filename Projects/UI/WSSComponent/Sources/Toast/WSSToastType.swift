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
}
