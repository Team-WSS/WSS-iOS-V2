//
//  CreateCollectionUseCase.swift
//  CollectionDomain
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol CreateCollectionUseCase: Sendable {
    /// 초안으로 컬렉션을 만든다.
    ///
    /// 제출 가능 여부(`CollectionDraft.isSubmittable`) 판단은 화면 몫이다 —
    /// 완료 버튼을 잠그는 것도 같은 규칙이라 여기서 다시 막으면 규칙이 두 곳으로 갈린다.
    /// - Returns: 생성된 컬렉션 ID
    func execute(_ draft: CollectionDraft) async throws(RepositoryError) -> CollectionID
}

public final class DefaultCreateCollectionUseCase: CreateCollectionUseCase {

    private let collectionRepository: CollectionRepository

    public init(collectionRepository: CollectionRepository) {
        self.collectionRepository = collectionRepository
    }

    public func execute(_ draft: CollectionDraft) async throws(RepositoryError) -> CollectionID {
        try await collectionRepository.createCollection(draft)
    }
}
