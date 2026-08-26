//
//  CollectionLikeUseCase.swift
//  CollectionDomain
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol CollectionLikeUseCase {
    func like(id: CollectionID) async throws(RepositoryError)
    func unlike(id: CollectionID) async throws(RepositoryError)
}

public final class DefaultCollectionLikeUseCase: CollectionLikeUseCase {

    private let collectionRepository: CollectionRepository

    public init(collectionRepository: CollectionRepository) {
        self.collectionRepository = collectionRepository
    }

    /// 서버가 멱등이라 이미 좋아요한 컬렉션에 다시 보내도 204다 —
    /// 화면은 현재 상태를 확신하지 못해도 "좋아요 상태로 만든다"는 의도만 보내면 된다.
    public func like(id: CollectionID) async throws(RepositoryError) {
        try await collectionRepository.likeCollection(id: id)
    }

    public func unlike(id: CollectionID) async throws(RepositoryError) {
        try await collectionRepository.unlikeCollection(id: id)
    }
}
