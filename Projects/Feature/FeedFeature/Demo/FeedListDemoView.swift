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

struct FeedListDemoView: View {

    private let loadMyFeedsUseCase: LoadMyFeedsUseCase
    private let loadSosoFeedsUseCase: LoadSosoFeedsUseCase
    private let feedLikeUseCase: FeedLikeUseCase
    private let loadProfileUseCase: LoadProfileUseCase

    public init(
        loadMyFeedsUseCase: LoadMyFeedsUseCase,
        loadSosoFeedsUseCase: LoadSosoFeedsUseCase,
        feedLikeUseCase: FeedLikeUseCase,
        loadProfileUseCase: LoadProfileUseCase
    ) {
        self.loadMyFeedsUseCase = loadMyFeedsUseCase
        self.loadSosoFeedsUseCase = loadSosoFeedsUseCase
        self.feedLikeUseCase = feedLikeUseCase
        self.loadProfileUseCase = loadProfileUseCase
    }

    var body: some View {
        FeedFeatureFactory.makeSosoFeedView(
            loadMyFeedsUseCase: loadMyFeedsUseCase,
            loadSosoFeedsUseCase: loadSosoFeedsUseCase,
            feedLikeUseCase: feedLikeUseCase,
            loadProfileUseCase: loadProfileUseCase
        )
    }
}
