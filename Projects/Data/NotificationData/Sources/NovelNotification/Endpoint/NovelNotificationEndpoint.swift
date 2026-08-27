//
//  NovelNotificationEndpoint.swift
//  NotificationData
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking
import BaseData

enum NovelNotificationEndpoint: Endpoint {

    case getSubscriptions(NovelNotificationSubscriptionsQuery)
    case deleteSubscriptions(NovelNotificationUnsubscribeRequest)

    var method: HTTPMethod {
        switch self {
        case .getSubscriptions:     return .get
        case .deleteSubscriptions:  return .delete
        }
    }

    var baseURL: URL { URL(string: NetworkingConfig.baseURL)! }

    var path: String {
        switch self {
        case .getSubscriptions, .deleteSubscriptions:
            return "/users/me/notification/novels"
        }
    }

    var query: QueryParameters {
        switch self {
        case .getSubscriptions(let query): return .convertible(query)
        case .deleteSubscriptions:         return .none
        }
    }

    var additionalHeaders: [String: String]? { nil }

    var body: RequestBody {
        switch self {
        case .getSubscriptions:                    return .none
        case .deleteSubscriptions(let request):    return .json(request)
        }
    }

    var authorization: AuthorizationPolicy { .requireToken }
}
