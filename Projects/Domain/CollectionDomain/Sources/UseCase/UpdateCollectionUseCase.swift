//
//  UpdateCollectionUseCase.swift
//  CollectionDomain
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol UpdateCollectionUseCase: Sendable {
    /// 컬렉션을 수정한다. 부분 수정이 아니라 초안 전체를 덮어쓴다 —
    /// 작품 목록도 통째로 다시 보내므로, 화면은 편집 결과 전체를 담은 초안을 넘겨야 한다.
    func execute(id: CollectionID, draft: CollectionDraft) async throws(RepositoryError)
}

public final class DefaultUpdateCollectionUseCase: UpdateCollectionUseCase {

    private let collectionRepository: CollectionRepository

    public init(collectionRepository: CollectionRepository) {
        self.collectionRepository = collectionRepository
    }

    public func execute(id: CollectionID, draft: CollectionDraft) async throws(RepositoryError) {
        try await collectionRepository.updateCollection(id: id, draft: draft)
    }
}
