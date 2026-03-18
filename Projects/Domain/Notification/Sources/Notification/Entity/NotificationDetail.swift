//
//  NotificationDetail.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

public struct NotificationDetail: Equatable {
    public let title: String
    public let createdAtText: String
    public let body: String
    
    public init(title: String, createdAtText: String, body: String) {
        self.title = title
        self.createdAtText = createdAtText
        self.body = body
    }
}
