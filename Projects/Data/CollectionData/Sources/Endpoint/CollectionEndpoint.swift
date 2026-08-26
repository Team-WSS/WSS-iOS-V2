//
//  CollectionEndpoint.swift
//  CollectionData
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import Networking
import BaseData

enum CollectionEndpoint: Endpoint {
    case postCollection(SubmitCollectionRequest)
    case getCollectionDetail(collectionID: Int, CollectionDetailQuery)
    case putCollection(collectionID: Int, SubmitCollectionRequest)
    case deleteCollection(collectionID: Int)
    case putCollectionLike(collectionID: Int)
    case deleteCollectionLike(collectionID: Int)
    case getUserCollections(userID: Int, CollectionsQuery)
    case getLikedCollections(CollectionsQuery)

    var baseURL: URL {
        URL(string: NetworkingConfig.baseURL) ?? URL(string: "")!
    }

    var path: String {
        switch self {
        case .postCollection:
            return "/collections"
        case .getCollectionDetail(let collectionID, _),
             .putCollection(let collectionID, _),
             .deleteCollection(let collectionID):
            return "/collections/\(collectionID)"
        case .putCollectionLike(let collectionID),
             .deleteCollectionLike(let collectionID):
            return "/collections/\(collectionID)/likes"
        case .getUserCollections(let userID, _):
            return "/users/\(userID)/collections"
        case .getLikedCollections:
            return "/users/me/liked-collections"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .postCollection:
            return .post
        case .getCollectionDetail, .getUserCollections, .getLikedCollections:
            return .get
        case .putCollection, .putCollectionLike:
            return .put
        case .deleteCollection, .deleteCollectionLike:
            return .delete
        }
    }

    var query: QueryParameters {
        switch self {
        case .getCollectionDetail(_, let query):
            return .convertible(query)
        case .getUserCollections(_, let query):
            return .convertible(query)
        case .getLikedCollections(let query):
            return .convertible(query)
        default:
            return .none
        }
    }

    var body: RequestBody {
        switch self {
        case .postCollection(let request),
             .putCollection(_, let request):
            return .json(request)
        default:
            return .none
        }
    }

    var authorization: AuthorizationPolicy {
        switch self {
        // 공유 링크로 들어온 비로그인 조회자에게도 내려간다(소유자 정보 포함).
        // 토큰이 있으면 isMyCollection·isLiked가 채워지므로 있으면 붙인다.
        case .getCollectionDetail:
            return .usesTokenIfAvailable
        default:
            return .requireToken
        }
    }

    var additionalHeaders: [String: String]? { nil }
}
