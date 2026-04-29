//
//  NotificationEndpoint.swift
//  NotificationData
//
//  Created by YunhakLee on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//


import Foundation
import Networking
import BaseData

enum NotificationEndpoint: Endpoint {
     
    case getNotifications(NotificationQuery)
    case getNotificationDetail(notificationId: Int)
    case getNotificationUnreadStatus
    case postNotificationRead(notificationId: Int)
    
    var method: HTTPMethod {
        switch self {
        case .getNotifications:             return .get
        case .getNotificationDetail:        return .get
        case .getNotificationUnreadStatus:  return .get
        case .postNotificationRead:         return .post
        }
    }
    
    var baseURL: URL {
        // TODO: 컨피그 설정 후 baseURL 반영
        URL(string: NetworkingConfig.baseURL)!
    }
    
    var path: String {
        switch self {
        case .getNotifications:                 return "/notifications"
        case .getNotificationDetail(let id):    return "/notifications/\(id)"
        case .getNotificationUnreadStatus:      return "/notifications/unread"
        case .postNotificationRead(let id):     return "/notifications/\(id)/read"
            
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getNotifications(let query): return query.asQueryItems()
        default: return nil
        }
    }
    
}
