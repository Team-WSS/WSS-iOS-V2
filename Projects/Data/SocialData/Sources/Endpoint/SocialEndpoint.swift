//
//  SocialEndpoint.swift
//  SocialData
//
//  Created by YunhakLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking
import BaseData

enum SocialEndpoint: Endpoint {

    case blockUser(userID: Int)
    case unblockUser(blockId: Int)
    case getBlockedUsers
    case reportSpoilerFeed(feedID: Int)
    case reportImproperFeed(feedID: Int)
    case reportSpoilerComment(feedID: Int, commentID: Int)
    case reportImproperComment(feedID: Int, commentID: Int)

    var method: HTTPMethod {
        switch self {
        case .blockUser:             return .post
        case .unblockUser:           return .delete
        case .getBlockedUsers:       return .get
        case .reportSpoilerFeed:     return .post
        case .reportImproperFeed:    return .post
        case .reportSpoilerComment:  return .post
        case .reportImproperComment: return .post
        }
    }

    var baseURL: URL {
        URL(string: NetworkingConfig.baseURL) ?? URL(string: "")!
    }

    var path: String {
        switch self {
        case .blockUser:
            return "/blocks"
        case .unblockUser(let blockId):
            return "/blocks/\(blockId)"
        case .getBlockedUsers:
            return "/blocks"
        case .reportSpoilerFeed(let feedID):
            return "/feeds/\(feedID)/spoiler"
        case .reportImproperFeed(let feedID):
            return "/feeds/\(feedID)/impertinence"
        case .reportSpoilerComment(let feedID, let commentID):
            return "/feeds/\(feedID)/comments/\(commentID)/spoiler"
        case .reportImproperComment(let feedID, let commentID):
            return "/feeds/\(feedID)/comments/\(commentID)/impertinence"
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .blockUser(let userID):
            return [URLQueryItem(name: "userId", value: String(userID))]
        default:
            return nil
        }
    }

    var headers: [String: String]? {
        ["Content-Type": "application/json",
         "Authorization": "Bearer " + "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhY2Nlc3MiLCJpYXQiOjE3Nzc2MzE5ODUsImV4cCI6MTc3NzYzMzc4NSwidXNlcklkIjoxMDAzM30.shLM9DXSzNvP6YO5WDDQ3WLqnfiCi-M6htmJ2Zi_u6g"]
    }

    var body: Data? { nil }

    var requireTokenRefresh: Bool { true }
}
