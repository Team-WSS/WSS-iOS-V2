//
//  NovelReviewFeatureDemoApp.swift
//  NovelReviewFeatureDemo
//
//  Created by YunhakLee on 6/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import DesignSystem
import NovelReviewDomain
import NovelReviewFeature

@main
struct NovelReviewFeatureDemoApp: App {
    init() {
        // 커스텀 폰트(Pretendard) 등록. 없으면 applyWSSFont의 UIFont(name:)! 가 nil → 크래시.
        // 프리뷰는 이 Demo 앱을 호스트로 띄우므로 여기서 등록하면 프리뷰도 함께 해결된다.
        DesignSystemFontFamily.registerAllCustomFonts()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                NovelReviewFactory.makeView(
                    novelID: NovelID(1),
                    title: "당신의 이해를 돕기 위하여",
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
