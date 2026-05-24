//
//  FeedEndpoint.swift
//  FeedData
//
//  Created by Lee Wonsun on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking
import BaseData

enum FeedEndpoint: Endpoint {
    case postFeed(request: SubmitFeedRequest)
    case patchFeed(feedID: Int, request: SubmitFeedRequest)
    case deleteFeed(feedID: Int)
    case getFeedDetail(feedID: Int)
    case getSosoFeeds(query: GetSosoFeedsQuery)
    case getUserFeeds(userID: Int, query: GetUserFeedsQuery)
    case getMyFeeds(userID: Int, query: GetUserFeedsQuery)
    case getNovelFeeds(novelID: Int, lastFeedID: Int, size: Int)
    case postLike(feedID: Int)
    case deleteLike(feedID: Int)

    var method: HTTPMethod {
        switch self {
        case .postFeed:         return .post
        case .patchFeed:        return .put
        case .deleteFeed:       return .delete
        case .getFeedDetail:    return .get
        case .getSosoFeeds:     return .get
        case .getUserFeeds:     return .get
        case .getMyFeeds:       return .get
        case .getNovelFeeds:    return .get
        case .postLike:         return .post
        case .deleteLike:       return .delete
        }
    }

    var baseURL: URL {
        URL(string: NetworkingConfig.baseURL) ?? URL(string: "")!
    }

    var path: String {
        switch self {
        case .postFeed:
            return "/feeds"
        case .patchFeed(let feedID, _):
            return "/feeds/\(feedID)"
        case .deleteFeed(let feedID):
            return "/feeds/\(feedID)"
        case .getFeedDetail(let feedID):
            return "/feeds/\(feedID)"
        case .getSosoFeeds:
            return "/feeds"
        case .getUserFeeds(let userID, _):
            return "/users/\(userID)/feeds"
        case .getMyFeeds(let userID, _):
            return "/users/\(userID)/feeds"
        case .getNovelFeeds(let novelID, _, _):
            return "/novels/\(novelID)/feeds"
        case .postLike(let feedID):
            return "/feeds/\(feedID)/likes"
        case .deleteLike(let feedID):
            return "/feeds/\(feedID)/likes"
        }
    }

    var query: QueryParameters {
        switch self {
        case .getSosoFeeds(let query): return .convertible(query)
        case .getUserFeeds(_, let query): return .convertible(query)
        case .getMyFeeds(_, let query): return .convertible(query)
        default: return .none
        }
    }
    
    var body: RequestBody {
        switch self {
        case let .postFeed(request),
             let .patchFeed(_, request):
            return .multipart(
                MultipartFormData(parts: [
                    .json(keyName: "feed", value: request)
                ] + request.imageDatas.map {
                    .imageData(keyName: "images", data: $0)
                })
            )
        default:
            return .none
        }
    }

    var authorization: AuthorizationPolicy {
        return .usesTokenIfAvailable
    }
    
    var additionalHeaders: [String : String]? {
        nil
    }
}
