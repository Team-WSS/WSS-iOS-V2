//
//  PushEndpoint.swift
//  NotificationData
//
//  Created by YunhakLee on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//


import Foundation
import Networking
import BaseData

enum PushEndpoint: Endpoint {
    
    case postFCMToken(FCMTokenRequest)
    case postPushNotificationSetting(PushNotificationSettingRequest)
    case getPushNotificationSetting
    
    var method: HTTPMethod {
        switch self {
        case .postFCMToken:                 return .post
        case .postPushNotificationSetting:  return .post
        case .getPushNotificationSetting:   return .get
        }
    }
    
    var baseURL: URL {
        // TODO: 컨피그 설정 후 baseURL 반영
        URL(string: NetworkingConfig.baseURL)!
    }
    
    var path: String {
        switch self {
        case .postFCMToken:                     return "/users/fcm-token"
        case .postPushNotificationSetting:      return "/users/push-settings"
        case .getPushNotificationSetting:       return "/users/push-settings"
            
        }
    }
    
    var queryItems: [URLQueryItem]? { nil }
    
    var headers: [String : String]? {
        [ "Content-Type": "application/json",
          "Authorization": "Bearer " + NetworkingConfig.testApiKey
        ]
    }
    
    var body: Data? {
        switch self {
        case .postFCMToken(let request): return request.asRequestBody()
        case .postPushNotificationSetting(let request): return request.asRequestBody()
        default:
            return nil
        }
    }
}
