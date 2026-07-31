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
                searchNovelUseCase: searchNovelUseCase
            )
        }
    }
}
