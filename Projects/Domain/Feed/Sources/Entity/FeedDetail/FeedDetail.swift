//
//  FeedDetail.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct FeedDetail {
    
    public let userId: UserID
    
    public private(set) var userProfileImageURL: URL?
    public private(set) var userName: String
    public private(set) var createdDate: String
    public private(set) var isModified: Bool
    
    public private(set) var feedContent: String
    public private(set) var feedImageURLs: [URL?]
    
    public private(set) var connectedNovel: ConnectedNovelDetail?
    
    public private(set) var likeCount: Int
    public private(set) var isLiked: Bool
    public private(set) var commentCount: Int
    
    //MARK: - Policy
    
    
}
