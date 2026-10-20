//
//  LoadPublicCollectionsUseCase.swift
//  CollectionDomain
//
//  Created by Guryss on 9/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadPublicCollectionsUseCase: Sendable {
    /// 모든 사용자의 공개 컬렉션을 최신순으로 가져온다.
    /// 홈 섹션은 첫 페이지만(`size` 10), 전체 컬렉션뷰는 커서로 이어서 부른다.
    /// - Parameter cursor: 직전 응답의 `nextCursor`. 첫 페이지는 nil.
    func execute(cursor: String?, size: Int) async throws(RepositoryError) -> CursorPaginated<CollectionCard>
}

public final class DefaultLoadPublicCollectionsUseCase: LoadPublicCollectionsUseCase {

    private let collectionRepository: CollectionRepository

    public init(collectionRepository: CollectionRepository) {
        self.collectionRepository = collectionRepository
    }

    public func execute(cursor: String?, size: Int) async throws(RepositoryError) -> CursorPaginated<CollectionCard> {
        try await collectionRepository.fetchPublicCollections(cursor: cursor, size: size)
    }
}
