//
//  SosoFeedDemoScene.swift
//  FeedFeatureDemo
//
//  Created by Seoyeon Choi on 6/21/26.
//

import SwiftUI

import FeedFeature
import FeedDomain
import BaseDomain
import ProfileDomain

import FeedData
import BaseData
import ProfileData

import Networking
import Logger

/// 피드 리스트(내 피드 + 소소피드) 화면 단독 데모.
struct SosoFeedDemoScene: View {

    private let loadMyFeedsUseCase: LoadMyFeedsUseCase
    private let loadSosoFeedsUseCase: LoadSosoFeedsUseCase
    private let feedLikeUseCase: FeedLikeUseCase
    private let loadProfileUseCase: LoadProfileUseCase

    init() {
        let client = NetworkingClient(tokenStore: DemoSessionTokenStore())
        let storage = UserDefaultsStorage()

        let feedRepository = FeedDataFactory.makeFeedRepository(
            client: client,
            logger: DataLogger(moduleName: "FeedData", underlying: OSLogger.feed)
        )
        let profileRepository = ProfileDataFactory.makeProfileRepository(
            client: client,
            localStorage: storage,
            logger: DataLogger(moduleName: "ProfileData", underlying: OSLogger.profile)
        )

        self.loadMyFeedsUseCase = DefaultLoadMyFeedsUseCase(feedRepository: feedRepository)
        self.loadSosoFeedsUseCase = DefaultLoadSosoFeedsUseCase(feedRepository: feedRepository)
        self.feedLikeUseCase = DefaultLikeUseCase(feedRepository: feedRepository)
        self.loadProfileUseCase = DefaultLoadProfileUseCase(profileRepository: profileRepository)
    }

    var body: some View {
        NavigationStack {
            FeedFeatureFactory.makeSosoFeedView(
                loadMyFeedsUseCase: loadMyFeedsUseCase,
                loadSosoFeedsUseCase: loadSosoFeedsUseCase,
                feedLikeUseCase: feedLikeUseCase,
                loadProfileUseCase: loadProfileUseCase
            )
        }
    }
}
