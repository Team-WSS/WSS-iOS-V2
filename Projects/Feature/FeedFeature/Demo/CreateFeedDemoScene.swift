//
//  CreateFeedDemoScene.swift
//  FeedFeatureDemo
//
//  Created by Seoyeon Choi on 6/21/26.
//

import SwiftUI

import FeedFeature
import FeedDomain
import NovelDomain
import BaseDomain

import FeedData
import NovelData
import BaseData

import Networking
import Logger

/// 피드 작성 화면 단독 데모.
struct CreateFeedDemoScene: View {

    private let createFeedUseCase: CreateFeedUseCase
    private let searchNovelUseCase: SearchNovelUseCase

    init() {
        let storage = UserDefaultsStorage()

        let client = NetworkingClient(tokenStore: DemoSessionTokenStore())

        let feedRepository = FeedDataFactory.makeFeedRepository(
            client: client,
            logger: DataLogger(moduleName: "FeedData", underlying: OSLogger.feed)
        )

        let novelRepository = NovelDataFactory.makeNovelRepository(
            client: client,
            appStorage: storage,
            logger: DataLogger(moduleName: "NovelData", underlying: OSLogger.novel)
        )

        self.createFeedUseCase = DefaultCreateFeedUseCase(repository: feedRepository)
        self.searchNovelUseCase = DefaultSearchNovelUseCase(novelRepository: novelRepository)
    }

    var body: some View {
        NavigationStack {
            FeedFeatureFactory.makeCreateFeedView(
                createFeedUseCase: createFeedUseCase,
                searchNovelUseCase: searchNovelUseCase
            )
        }
    }
}
