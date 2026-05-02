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
            
        case .getMyFeeds(_, let query):
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
         "Authorization": "Bearer " + "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhY2Nlc3MiLCJpYXQiOjE3Nzc3MTU0NjcsImV4cCI6MTc3NzcxNzI2NywidXNlcklkIjoxMDAzM30.lqDVRk_QO418B_r8P2DVWVy0c6iTbQ9MfuMUvmjbZqM"]
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
