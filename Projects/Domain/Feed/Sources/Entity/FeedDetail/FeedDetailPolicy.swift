//
//  FeedDetailPolicy.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public extension FeedDetailEntity {
    
    //MARK: - Image
    
    static func imageDisplayStyle(for count: Int) -> ImageDisplayStyle {
        switch count {
        case 0: return .none
        case 1: return .single
        default: return .horizontalScroll
        }
    }
    
    //MARK: - More Action
    
    static func availableMoreActions(isMyFeed: Bool) -> FeedMoreAction {
        isMyFeed ? .myFeed : .otherUserFeed
    }
}

public enum ImageDisplayStyle {
    case none
    case single
    case horizontalScroll
}

public enum FeedMoreAction {
    case myFeed
    case otherUserFeed
}
