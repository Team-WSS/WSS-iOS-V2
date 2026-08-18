//
//  LoadLikedCollectionsUseCase.swift
//  CollectionDomain
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadLikedCollectionsUseCase {
    /// 좋아요한 컬렉션 목록을 가져온다. 좋아요한 시점 최신순.
    /// - Parameter cursor: 직전 응답의 `nextCursor`. 첫 페이지는 nil.
    /// - Returns: (커서 페이지, 전체 좋아요한 컬렉션 수)
    func execute(cursor: String?, size: Int) async throws(RepositoryError) -> (CursorPaginated<CollectionCard>, Int)
}

public final class DefaultLoadLikedCollectionsUseCase: LoadLikedCollectionsUseCase {

    private let collectionRepository: CollectionRepository

    public init(collectionRepository: CollectionRepository) {
        self.collectionRepository = collectionRepository
    }

    public func execute(cursor: String?, size: Int) async throws(RepositoryError) -> (CursorPaginated<CollectionCard>, Int) {
        try await collectionRepository.fetchLikedCollections(cursor: cursor, size: size)
    }
}
