//
//  NovelReviewAssembly.swift
//  WSS-iOS
//
//  Created by Guryss on 8/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NovelReviewDomain
import NovelReviewFeature

/// 작품 평가(`NovelReviewFeatureFactory`) 조립 — 홈/피드/서재 세 탭의 작품 상세가 전부 같은 방식으로
/// push해서(#197) 공용으로 뽑았다(`NovelDetailAssembly`/`FeedDetailAssembly`/`SearchAssembly`와 같은
/// 이유). `title`은 호출자가 `NovelDetailFeature`의 `onReviewTapped(NovelInformation, ReadingStatus)`
/// 콜백에서 받은 `NovelInformation.novel.title`을 그대로 넘긴다(진입 이전 화면이 이미 아는 값이라
/// `NovelReviewFeatureFactory`가 새로 조회하지 않는다).
@MainActor
enum NovelReviewAssembly {
    static func makeView(
        novelID: NovelID,
        title: String,
        status: ReadingStatus,
        dependencies: AppDependencies,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        NovelReviewFeatureFactory.makeView(
            novelID: novelID,
            title: title,
            status: status,
            loadUseCase: DefaultLoadNovelReviewDraftUseCase(repository: dependencies.novelReviewRepository),
            saveUseCase: DefaultSaveNovelReviewUseCase(repository: dependencies.novelReviewRepository),
            logger: dependencies.logger,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}
