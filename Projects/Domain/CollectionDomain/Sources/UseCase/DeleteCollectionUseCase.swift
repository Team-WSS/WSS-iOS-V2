//
//  DeleteCollectionUseCase.swift
//  CollectionDomain
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol DeleteCollectionUseCase: Sendable {
    /// 컬렉션을 삭제한다. 담긴 작품 자체는 지워지지 않는다(컬렉션에서 빠질 뿐).
    func execute(id: CollectionID) async throws(RepositoryError)
}

public final class DefaultDeleteCollectionUseCase: DeleteCollectionUseCase {

    private let collectionRepository: CollectionRepository

    public init(collectionRepository: CollectionRepository) {
        self.collectionRepository = collectionRepository
    }

    public func execute(id: CollectionID) async throws(RepositoryError) {
        try await collectionRepository.deleteCollection(id: id)
    }
}
