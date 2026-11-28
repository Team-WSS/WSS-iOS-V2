//
//  LoadRandomPublicCollectionsUseCase.swift
//  CollectionDomain
//
//  Created by YunhakLee on 11/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadRandomPublicCollectionsUseCase: Sendable {
    /// 모든 사용자의 공개 컬렉션 중 무작위로 최대 `size`개를 가져온다(홈 "컬렉션 모음.zip" 섹션).
    ///
    /// 무작위 조회는 페이지네이션이 없어 커서를 받지 않고 배열만 돌려준다.
    /// 요청마다 새로 고르므로 새로고침하면 다른 컬렉션이 나올 수 있다(매번 달라진다는 보장은 없다).
    func execute(size: Int) async throws(RepositoryError) -> [CollectionCard]
}

public final class DefaultLoadRandomPublicCollectionsUseCase: LoadRandomPublicCollectionsUseCase {

    private let collectionRepository: CollectionRepository

    public init(collectionRepository: CollectionRepository) {
        self.collectionRepository = collectionRepository
    }

    public func execute(size: Int) async throws(RepositoryError) -> [CollectionCard] {
        try await collectionRepository.fetchPublicCollections(sort: .random, cursor: nil, size: size).items
    }
}
