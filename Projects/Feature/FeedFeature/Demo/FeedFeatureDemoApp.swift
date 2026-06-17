//
//  FeedFeatureDemoApp.swift
//  FeedFeatureDemo
//
//  Created by Seoyeon Choi on 6/4/26.
//

import SwiftUI

import DesignSystem
import FeedFeature
import FeedDomain
import NovelDomain
import FeedData
import NovelData
import BaseData
import Networking
import Logger

@main
struct FeedFeatureDemoApp: App {

    private let createFeedUseCase: CreateFeedUseCase
    private let searchNovelUseCase: SearchNovelUseCase

    init() {
        DesignSystemFontFamily.registerAllCustomFonts()

        let storage = UserDefaultsStorage()
        storage.set(.userID, 10033)

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

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                FeedFeatureFactory.makeCreateFeedView(
                    createFeedUseCase: createFeedUseCase,
                    searchNovelUseCase: searchNovelUseCase
                )
            }
        }
    }
}
