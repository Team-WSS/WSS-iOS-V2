//
//  CollectionAction.swift
//  CollectionData
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import Logger

enum CollectionAction {
    case fetchCollectionPreviews(userID: Int)
    case fetchCollections(userID: Int)
    case fetchLikedCollections
    case fetchCollectionDetail(collectionID: Int)
    case createCollection
    case updateCollection(collectionID: Int)
    case deleteCollection(collectionID: Int)
    case likeCollection(collectionID: Int)
    case unlikeCollection(collectionID: Int)

    var name: String {
        switch self {
        case .fetchCollectionPreviews(let userID):      "마이페이지 컬렉션 미리보기 조회: \(userID)"
        case .fetchCollections(let userID):             "컬렉션 목록 조회: \(userID)"
        case .fetchLikedCollections:                    "좋아요한 컬렉션 목록 조회"
        case .fetchCollectionDetail(let collectionID):  "컬렉션 상세 조회: \(collectionID)"
        case .createCollection:                         "컬렉션 생성"
        case .updateCollection(let collectionID):       "컬렉션 수정: \(collectionID)"
        case .deleteCollection(let collectionID):       "컬렉션 삭제: \(collectionID)"
        case .likeCollection(let collectionID):         "컬렉션 좋아요 등록: \(collectionID)"
        case .unlikeCollection(let collectionID):       "컬렉션 좋아요 취소: \(collectionID)"
        }
    }
}
