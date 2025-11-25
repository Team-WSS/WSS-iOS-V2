//
//  NotificationEndpoint.swift
//  NotificationData
//
//  Created by YunhakLee on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//


import Foundation
import Networking

enum NotificationEndpoint: Endpoint {
    
    // MARK: - 앱 내 알림
    
    case getNotifications(NotificationQeury)
    case getNotificationDetail(notificationId: Int)
    case getNotificationUnreadStatus
    case postNotificationRead(notificationId: Int)
    
    // MARK: - Push 알림
    
    case postFCMToken(FCMTokenRequest)
    case postPushNotificationSetting(PushNotificationSettingRequest)
    case getPushNotificationSetting
    
    var method: HTTPMethod {
        switch self {
        case .getNotifications:             return .get
        case .getNotificationDetail:        return .get
        case .getNotificationUnreadStatus:  return .get
        case .postNotificationRead:         return .post
        case .postFCMToken:                 return .post
        case .postPushNotificationSetting:  return .post
        case .getPushNotificationSetting:   return .get
        }
    }
    
    var baseURL: URL {
        // TODO: 컨피그 설정 후 baseURL 반영
        URL(string: "https://jsonplaceholder.typicode.com")!
    }
    
    var path: String {
        switch self {
        case .getNotifications:                 return "/notifications"
        case .getNotificationDetail(let id):    return "/notifications/\(id)"
        case .getNotificationUnreadStatus:      return "/notifications/unread"
        case .postNotificationRead(let id):     return "/notifications/\(id)/read"
        case .postFCMToken:                     return "/users/fcm-token"
        case .postPushNotificationSetting:      return "/users/push-settings"
        case .getPushNotificationSetting:       return "/users/push-settings"
            
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getNotifications(let query): return query.asQueryItems()
        default: return nil
        }
    }
    
    var headers: [String : String]? {
        ["Content-Type": "application/json",
         "Authorization": "Bearer " + "dummyAccessToken"]
    }
    
    var body: Data? {
        switch self {
        case .postFCMToken(let request): return request.asRequestBody()
        case .postPushNotificationSetting(let request): return request.asRequestBody()
        default:
            return nil
        }
    }
    
    var requireTokenRefresh: Bool { true }
}
