//
//  MockLoadNovelReviewDraftUseCase.swift
//  NovelReviewDomain
//
//  Created by Codex on 8/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import NovelReviewDomain
import BaseDomain

/// Feature ViewModel 테스트용 공유 Mock — 결과는 `loadResult`로 주입, 입력은 `loadedNovelIDs`로 추적한다.
/// (비동기 경합처럼 "실행을 멈춰 세워야 하는" 특수 시나리오는 각 테스트가 전용 fake를 따로 둔다.)
public final class MockLoadNovelReviewDraftUseCase: LoadNovelReviewDraftUseCase {
    public var loadResult: Result<NovelReviewDraft?, RepositoryError> = .success(nil)
    public private(set) var loadedNovelIDs: [NovelID] = []

    public init() {}

    public func execute(novelID: NovelID) async throws(RepositoryError) -> NovelReviewDraft? {
        loadedNovelIDs.append(novelID)
        switch loadResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}
