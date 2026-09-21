//
//  MockSaveNovelReviewUseCase.swift
//  NovelReviewDomain
//
//  Created by Codex on 8/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import NovelReviewDomain
import BaseDomain

/// Feature ViewModel 테스트용 공유 Mock — 결과는 `saveResult`로 주입, 저장 호출은 `savedDrafts`로 추적한다.
public final class MockSaveNovelReviewUseCase: SaveNovelReviewUseCase {
    public var saveResult: Result<Void, RepositoryError> = .success(())
    public private(set) var savedDrafts: [NovelReviewDraft] = []

    public init() {}

    public func execute(draft: NovelReviewDraft) async throws(RepositoryError) {
        savedDrafts.append(draft)
        switch saveResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}
