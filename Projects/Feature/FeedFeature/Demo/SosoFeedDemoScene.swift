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
import SocialDomain

import FeedData
import BaseData
import ProfileData
import SocialData

import Networking
import Logger

/// 피드 리스트(내 피드 + 소소피드) 화면 단독 데모.
struct SosoFeedDemoScene: View {

    private let loadMyFeedsUseCase: LoadMyFeedsUseCase
    private let loadSosoFeedsUseCase: LoadSosoFeedsUseCase
    private let feedLikeUseCase: FeedLikeUseCase
    private let loadProfileUseCase: LoadProfileUseCase
    private let deleteFeedUseCase: DeleteFeedUseCase
    private let reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase
    private let reportImproperFeedUseCase: ReportImproperFeedUseCase

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
        let socialRepository = SocialDataFactory.makeSocialRepository(
            client: client,
            logger: DataLogger(moduleName: "SocialData", underlying: OSLogger.social)
        )

        self.loadMyFeedsUseCase = DefaultLoadMyFeedsUseCase(feedRepository: feedRepository)
        self.loadSosoFeedsUseCase = DefaultLoadSosoFeedsUseCase(feedRepository: feedRepository)
        self.feedLikeUseCase = DefaultLikeUseCase(feedRepository: feedRepository)
        self.loadProfileUseCase = DefaultLoadProfileUseCase(profileRepository: profileRepository)
        self.deleteFeedUseCase = DefaultDeleteFeedUseCase(repository: feedRepository)
        self.reportSpoilerFeedUseCase = DefaultReportSpoilerFeedUseCase(repository: socialRepository)
        self.reportImproperFeedUseCase = DefaultReportImproperFeedUseCase(repository: socialRepository)
    }

    var body: some View {
        NavigationStack {
            FeedFeatureFactory.makeSosoFeedView(
                loadMyFeedsUseCase: loadMyFeedsUseCase,
                loadSosoFeedsUseCase: loadSosoFeedsUseCase,
                feedLikeUseCase: feedLikeUseCase,
                loadProfileUseCase: loadProfileUseCase,
                deleteFeedUseCase: deleteFeedUseCase,
                reportSpoilerFeedUseCase: reportSpoilerFeedUseCase,
                reportImproperFeedUseCase: reportImproperFeedUseCase,
                logger: OSLogger.feed,
                onEditFeedTapped: { print("피드 수정 진입: \($0)") }
            )
        }
    }
}
