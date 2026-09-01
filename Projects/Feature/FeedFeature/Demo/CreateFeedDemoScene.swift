//
//  CreateFeedDemoScene.swift
//  FeedFeatureDemo
//
//  Created by Seoyeon Choi on 6/21/26.
//

import SwiftUI

import FeedFeature
import FeedDomain
import SearchDomain
import BaseDomain

import FeedData
import SearchData
import BaseData

import Networking
import Logger

/// 피드 작성 화면 단독 데모.
struct CreateFeedDemoScene: View {

    private let createFeedUseCase: CreateFeedUseCase
    private let searchNovelUseCase: SearchNovelUseCase
    private let appReviewUseCase: AppReviewRequestUseCase = DemoAppReviewRequestUseCase()

    init() {
        let client = NetworkingClient(tokenStore: DemoSessionTokenStore())

        let feedRepository = FeedDataFactory.makeFeedRepository(
            client: client,
            logger: DataLogger(moduleName: "FeedData", underlying: OSLogger.feed)
        )

        let searchRepository = SearchDataFactory.makeRepository(
            network: client,
            logger: DataLogger(moduleName: "SearchData", underlying: OSLogger.search)
        )

        self.createFeedUseCase = DefaultCreateFeedUseCase(repository: feedRepository)
        self.searchNovelUseCase = DefaultSearchNovelUseCase(searchNovelRepository: searchRepository)
    }

    var body: some View {
        NavigationStack {
            FeedFeatureFactory.makeCreateFeedView(
                createFeedUseCase: createFeedUseCase,
                searchNovelUseCase: searchNovelUseCase,
                appReviewUseCase: appReviewUseCase
            )
        }
    }
}

/// 데모용 인메모리 리뷰 게이트 — 첫 저장 성공에 바로 프롬프트가 뜨도록 임계치 1(실앱은 3).
private final class DemoAppReviewRequestUseCase: AppReviewRequestUseCase, @unchecked Sendable {
    private var count = 0
    private var requested = false
    func recordEngagement() { count += 1 }
    func shouldRequestReview() -> Bool { count >= 1 && !requested }
    func markReviewRequested() { requested = true }
}
