//
//  FeedEndpoint.swift
//  FeedData
//
//  Created by Lee Wonsun on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

enum FeedEndpoint: Endpoint {
    
    // TODO: getMyFeeds는 API가 UserFeeds랑 동일한데 userID에 본인 id 넣는게 맞나용
    
    case postFeed(request: SubmitFeedRequest)
    case patchFeed(feedID: Int, request: SubmitFeedRequest)
    case deleteFeed(feedID: Int)
    case getFeedDetail(feedID: Int)
    case getSosoFeeds(query: GetSosoFeedsQuery)
    case getUserFeeds(userID: Int, query: GetUserFeedsQuery)
    case getMyFeeds(genres: [String], visibilityType: String, sortType: String, lastFeedID: Int)
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
        // TODO: 컨피그 설정 후 baseURL 반영
        URL(string: "")!
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
        case .getMyFeeds:
            return "/users/me/feeds"
        case .getNovelFeeds(let novelID, _, _):
            return "/novels/\(novelID)/feeds"
        case .postLike(let feedID):
            return "/feeds/\(feedID)/likes"
        case .deleteLike(let feedID):
            return "/feeds/\(feedID)/likes"
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .getSosoFeeds(let query):
            var items: [URLQueryItem] = [
                URLQueryItem(name: "lastFeedId", value: "\(query.lastFeedID)"),
                URLQueryItem(name: "size", value: "\(query.size)"),
                URLQueryItem(name: "feedsOption", value: query.option)
            ]
            if let category = query.category { items.append(URLQueryItem(name: "category", value: category)) }
            return items
            
        case .getUserFeeds(_, let query):
            var items: [URLQueryItem] = [
                URLQueryItem(name: "lastFeedId", value: "\(query.lastFeedID)"),
                URLQueryItem(name: "size", value: "\(query.size)")
            ]
            if let isVisible = query.isVisible { items.append(URLQueryItem(name: "isVisible", value: "\(isVisible)")) }
            if let isUnVisible = query.isUnVisible { items.append(URLQueryItem(name: "isUnVisible", value: "\(isUnVisible)")) }
            if let genreNames = query.genreNames, !genreNames.isEmpty {
                items.append(URLQueryItem(name: "genreNames", value: genreNames.joined(separator: ",")))
            }
            if let sortCriteria = query.sortCriteria { items.append(URLQueryItem(name: "sortCriteria", value: sortCriteria)) }
            return items
            
        case .getMyFeeds(let genres, let visibilityType, let sortType, let lastFeedID):
            return [
                URLQueryItem(name: "lastFeedId", value: "\(lastFeedID)"),
                URLQueryItem(name: "genres", value: genres.joined(separator: ",")),
                URLQueryItem(name: "visibilityType", value: visibilityType),
                URLQueryItem(name: "sortType", value: sortType)
            ]
            
        case .getNovelFeeds(_, let lastFeedID, let size):
            return [
                URLQueryItem(name: "lastFeedId", value: "\(lastFeedID)"),
                URLQueryItem(name: "size", value: "\(size)")
            ]
        default:
            return nil
        }
    }

    var headers: [String: String]? {
        // TODO: postFeed, patchFeed는 multipart/form-data로 변경 필요
        ["Content-Type": "application/json",
         "Authorization": "Bearer " + "dummyAccessToken"]
    }

    var body: Data? {
        switch self {
        case .postFeed(let request):
            // TODO: multipart/form-data로 변경 필요 (feed: JSON part, images: image/* part)
            return try? JSONEncoder().encode(request)
        case .patchFeed(_, let request):
            // TODO: multipart/form-data로 변경 필요 (feed: JSON part, images: image/* part)
            return try? JSONEncoder().encode(request)
        default:
            return nil
        }
    }

    var requireTokenRefresh: Bool { true }
}
