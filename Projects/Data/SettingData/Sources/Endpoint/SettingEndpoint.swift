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
    
    case getAppMinimumVersion(AppMinimumVersionQuery)
    
    var method: HTTPMethod {
        switch self {
        case .getTermSetting:           return .get
        case .patchTermSetting:         return .patch
        case .getAppMinimumVersion:     return .get
        }
    }
    
    var baseURL: URL {
        // TODO: 컨피그 설정 후 baseURL 반영
        URL(string: NetworkingConfig.baseURL)!
    }
    
    var path: String {
        switch self {
        case .getTermSetting:               return "/users/terms-settings"
        case .patchTermSetting:             return "/users/terms-settings"
        case .getAppMinimumVersion:         return "/minimum-version"
        }
    }

    var query: QueryParameters { .none }

    var additionalHeaders: [String: String]? { nil }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getAppMinimumVersion(let query): return query.asQueryItems()
        default: return nil
        }
    }
    
    var body: RequestBody {
        switch self {
        case .patchTermSetting(let request):        return .json(request)
        default:
            return .none
        }
    }
    
    var authorization: AuthorizationPolicy {
        switch self {
        case .getAppMinimumVersion: return .withoutToken
        default: return .requiresToken
        }
    }
}
