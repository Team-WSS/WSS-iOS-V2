//
//  TotalFeedPolicy.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public extension TotalFeedEntity {
    
    func isMyFeed(myID: UserID) -> Bool {
        author.userId == myID
    }
    
    var isPrivate: Bool {
        !isPublic
    }
    
    var hasImage: Bool {
        imageCount > 0 && thumbnailImageURL != nil
    }
    
    var roundedRating: Float? {
        if let rating = connectedNovel?.rating {
            return round(rating * 10) / 10
        }
        else { return nil }
    }
}
