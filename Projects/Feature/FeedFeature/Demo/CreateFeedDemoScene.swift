//
//  CreateFeedDemoScene.swift
//  FeedFeatureDemo
//
//  Created by Seoyeon Choi on 6/4/26.
//

import SwiftUI

import FeedFeature
import FeedDomain
import NovelDomain
import BaseData

import FeedData
import NovelData

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
        FeedFeatureFactory.makeCreateFeedView(
            createFeedUseCase: createFeedUseCase,
            searchNovelUseCase: searchNovelUseCase
        )
    }
}
