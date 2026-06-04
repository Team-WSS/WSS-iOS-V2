//
//  NovelReviewFeatureDemoApp.swift
//  NovelReviewFeatureDemo
//
//  Created by YunhakLee on 6/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NovelReviewDomain
import NovelReviewFeature

@main
struct NovelReviewFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                NovelReviewFactory.makeView(
                    novelID: NovelID(1),
                    loadUseCase: DemoLoadNovelReviewDraftUseCase(),
                    saveUseCase: DemoSaveNovelReviewUseCase()
                )
            }
        }
    }
}

// MARK: - Demo UseCases
// Feature Demo는 Data를 의존하지 않으므로 인메모리 Mock으로 흐름만 시연한다.
// 실제 Repository 연결(NovelReviewData)은 App(DI)이 담당한다.

private struct DemoLoadNovelReviewDraftUseCase: LoadNovelReviewDraftUseCase {
    func execute(novelID: NovelID) async throws(RepositoryError) -> NovelReviewDraft? {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return NovelReviewDraft(
            novelID: novelID,
            status: .watched,
            attractivePoints: [.character, .vibe]
        )
    }
}

private struct DemoSaveNovelReviewUseCase: SaveNovelReviewUseCase {
    func execute(draft: NovelReviewDraft) async throws(RepositoryError) {
        try? await Task.sleep(nanoseconds: 800_000_000)
    }
}
