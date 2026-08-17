//
//  NovelNotificationSettingEndpoint.swift
//  NotificationData
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking
import BaseData

enum NovelNotificationSettingEndpoint: Endpoint {

    case getNotificationSetting(novelID: Int)
    case putNotificationSetting(novelID: Int, request: NovelNotificationSettingRequest)

    var method: HTTPMethod {
        switch self {
        case .getNotificationSetting: return .get
        case .putNotificationSetting: return .put
        }
    }

    var baseURL: URL { URL(string: NetworkingConfig.baseURL)! }

    var path: String {
        switch self {
        case .getNotificationSetting(let novelID):
            return "/novels/\(novelID)/notification"
        case .putNotificationSetting(let novelID, _):
            return "/novels/\(novelID)/notification"
        }
    }

    var query: QueryParameters { .none }

    var additionalHeaders: [String: String]? { nil }

    var body: RequestBody {
        switch self {
        case .getNotificationSetting:
            return .none
        case .putNotificationSetting(_, let request):
            return .json(request)
        }
    }

    var authorization: AuthorizationPolicy { .requireToken }
}
