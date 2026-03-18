//
//  ProfileVisibility.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

public struct ProfileVisibility: Equatable {
    public let isPublic: Bool
    public init(isPublic: Bool) { self.isPublic = isPublic }
}
