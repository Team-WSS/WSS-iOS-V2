//
//  SettingEndpoint.swift
//  SettingData
//
//  Created by YunhakLee on 4/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


//
//  SettingEndpoint.swift
//  SettingData
//
//  Created by YunhakLee on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//


import Foundation
import Networking

enum SettingEndpoint: Endpoint {
    
    // MARK: - Term
    
    case getTermSetting
    case patchTermSetting(TermSettingRequest)
    
    // MARK: - ForceUpdate
    
    case getAppMinimumVersion
    
    //MARK: - ProfileVisibility
    
    case getProfileVisibility
    case patchProfileVisibility(ProfileVisibilityRequest)
    
    // MARK: - Push 알림
    
    case postPushNotificationSetting(PushNotificationSettingRequest)
    case getPushNotificationSetting
    
    var method: HTTPMethod {
        switch self {
        case .getTermSetting:           return .get
        case .patchTermSetting:         return .patch
        case .getAppMinimumVersion:     return .get
        case .getProfileVisibility:     return .get
        case .patchProfileVisibility:   return .patch
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
        case .getTermSetting:               return "/users/terms-settings"
        case .patchTermSetting:             return "/users/terms-settings"
        case .getAppMinimumVersion:         return "/minimum-version"
        case .getProfileVisibility:         return "/users/profile-status"
        case .patchProfileVisibility:       return "/users/profile-status"
        case .postPushNotificationSetting:  return "/users/push-settings"
        case .getPushNotificationSetting:   return "/users/push-settings"
        }
    }
    
    var queryItems: [URLQueryItem]? { nil }
    
    var headers: [String : String]? {
        ["Content-Type": "application/json",
         "Authorization": "Bearer " + "dummyAccessToken"]
    }
    
    var body: Data? {
        switch self {
        case .patchTermSetting(let request):        return request.asRequestBody()
        case .patchProfileVisibility(let request):  return request.asRequestBody()
        case .postPushNotificationSetting(let request): return request.asRequestBody()
        default:
            return nil
        }
    }
    
    var requireTokenRefresh: Bool { true }
}
