//
//  LoadCollectionsUseCase.swift
//  CollectionDomain
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadCollectionsUseCase {
    /// 사용자별 컬렉션 목록을 가져온다. 본인 목록에는 나만 보는 컬렉션이 함께 오고,
    /// 다른 사용자 목록에는 공개 컬렉션만 오므로 화면에서 따로 거를 필요가 없다.
    /// - Parameter cursor: 직전 응답의 `nextCursor`. 첫 페이지는 nil.
    /// - Returns: (커서 페이지, 전체 컬렉션 수)
    func execute(userID: UserID, cursor: String?, size: Int) async throws(RepositoryError) -> (CursorPaginated<CollectionCard>, Int)
}

public final class DefaultLoadCollectionsUseCase: LoadCollectionsUseCase {

    private let collectionRepository: CollectionRepository

    public init(collectionRepository: CollectionRepository) {
        self.collectionRepository = collectionRepository
    }

    public func execute(userID: UserID, cursor: String?, size: Int) async throws(RepositoryError) -> (CursorPaginated<CollectionCard>, Int) {
        try await collectionRepository.fetchCollections(userID: userID, cursor: cursor, size: size)
    }
}
