//
//  FeedListDemoView.swift
//  FeedFeatureDemo
//
//  Created by Seoyeon Choi on 6/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import FeedFeature
import FeedDomain
import ProfileDomain
import SocialDomain

struct FeedListDemoView: View {

    private let loadMyFeedsUseCase: LoadMyFeedsUseCase
    private let loadSosoFeedsUseCase: LoadSosoFeedsUseCase
    private let feedLikeUseCase: FeedLikeUseCase
    private let loadProfileUseCase: LoadProfileUseCase
    private let deleteFeedUseCase: DeleteFeedUseCase
    private let reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase
    private let reportImproperFeedUseCase: ReportImproperFeedUseCase

    public init(
        loadMyFeedsUseCase: LoadMyFeedsUseCase,
        loadSosoFeedsUseCase: LoadSosoFeedsUseCase,
        feedLikeUseCase: FeedLikeUseCase,
        loadProfileUseCase: LoadProfileUseCase,
        deleteFeedUseCase: DeleteFeedUseCase,
        reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase,
        reportImproperFeedUseCase: ReportImproperFeedUseCase
    ) {
        self.loadMyFeedsUseCase = loadMyFeedsUseCase
        self.loadSosoFeedsUseCase = loadSosoFeedsUseCase
        self.feedLikeUseCase = feedLikeUseCase
        self.loadProfileUseCase = loadProfileUseCase
        self.deleteFeedUseCase = deleteFeedUseCase
        self.reportSpoilerFeedUseCase = reportSpoilerFeedUseCase
        self.reportImproperFeedUseCase = reportImproperFeedUseCase
    }

    var body: some View {
        FeedFeatureFactory.makeSosoFeedView(
            loadMyFeedsUseCase: loadMyFeedsUseCase,
            loadSosoFeedsUseCase: loadSosoFeedsUseCase,
            feedLikeUseCase: feedLikeUseCase,
            loadProfileUseCase: loadProfileUseCase,
            deleteFeedUseCase: deleteFeedUseCase,
            reportSpoilerFeedUseCase: reportSpoilerFeedUseCase,
            reportImproperFeedUseCase: reportImproperFeedUseCase
        )
    }
}
