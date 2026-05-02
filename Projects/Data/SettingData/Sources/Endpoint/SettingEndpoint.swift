//
//  SettingEndpoint.swift
//  SettingData
//
//  Created by YunhakLee on 4/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation
import Networking
import BaseData

enum SettingEndpoint: Endpoint {
    
    // MARK: - Term
    
    case getTermSetting
    case patchTermSetting(TermSettingRequest)
    
    // MARK: - ForceUpdate
    
    case getAppMinimumVersion
    
    var method: HTTPMethod {
        switch self {
        case .getTermSetting:           return .get
        case .patchTermSetting:         return .patch
        case .getAppMinimumVersion:     return .get
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
        case .patchTermSetting(let request):        return request.asRequestBody()
        default:
            return nil
        }
    }
    
    var requireTokenRefresh: Bool { true }
}
