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
    
    var baseURL: URL { URL(string: NetworkingConfig.baseURL)! }
    
    var path: String {
        switch self {
        case .getNotifications:                 return "/notifications"
        case .getNotificationDetail(let id):    return "/notifications/\(id)"
        case .getNotificationUnreadStatus:      return "/notifications/unread"
        case .postNotificationRead(let id):     return "/notifications/\(id)/read"
            
        }
    }
    
    var query: QueryParameters {
        switch self {
        case .getNotifications(let query): return .convertible(query)
        default: return .none
        }
    }

    var additionalHeaders: [String: String]? { nil }

    var body: RequestBody { .none }

    var authorization: AuthorizationPolicy { .requireToken }
}
