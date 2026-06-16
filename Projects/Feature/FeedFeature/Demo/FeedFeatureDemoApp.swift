//
//  FeedFeatureDemoApp.swift
//  FeedFeatureDemo
//
//  Created by Seoyeon Choi on 6/4/26.
//

import SwiftUI

import BaseDomain
import FeedDomain
import CommentDomain
import SocialDomain

import BaseData
import FeedData
import CommentData
import SocialData

import Logger
import Networking

import DesignSystem
import FeedFeature

@main
struct FeedFeatureDemoApp: App {
    init() {
        DesignSystemFontFamily.registerAllCustomFonts()
    }
    var body: some Scene {
        WindowGroup {
            FeedFeatureDemoRootView()
        }
    }
}

/// 실제 API에 연결된 FeedDetailView를 단독 검증하기 위한 임시 진입 화면.
/// 검증 후에는 CreateFeed 데모처럼 stub 진입점으로 되돌릴 수 있다.
private struct FeedFeatureDemoRootView: View {

    @State private var feedIDText: String = "1"
    @State private var pushedFeedID: FeedID?

    private let loadFeedDetailUseCase: LoadFeedDetailUseCase
    private let feedLikeUseCase: FeedLikeUseCase
    private let loadCommentsUseCase: LoadCommentsUseCase
    private let createCommentUseCase: CreateCommentUseCase
    private let deleteCommentUseCase: DeleteCommentUseCase
    private let editCommentUseCase: EditCommentUseCase
    private let reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase
    private let reportImproperFeedUseCase: ReportImproperFeedUseCase
    private let reportSpoilerCommentUseCase: ReportSpoilerCommentUseCase
    private let reportImproperCommentUseCase: ReportImproperCommentUseCase

    init() {
        let consoleLogger = ConsoleLogger()
        let tokenStore = DemoSessionTokenStore()
        let networkLogger = DefaultNetworkLogger(base: consoleLogger, showBody: true, showHost: false)
        let client = NetworkingClient(logger: networkLogger, tokenStore: tokenStore)

        let feedRepository = FeedDataFactory.makeFeedRepository(
            client: client,
            logger: DataLogger(moduleName: "Feed", underlying: consoleLogger)
        )
        let commentRepository = CommentDataFactory.makeRepository(
            client: client,
            logger: DataLogger(moduleName: "Comment", underlying: consoleLogger)
        )
        let socialRepository = SocialDataFactory.makeSocialRepository(
            client: client,
            underlying: consoleLogger
        )

        self.loadFeedDetailUseCase = DefaultLoadFeedUseCase(feedRepository: feedRepository)
        self.feedLikeUseCase = DefaultLikeUseCase(feedRepository: feedRepository)
        self.loadCommentsUseCase = DefaultLoadCommentsUseCase(repository: commentRepository)
        self.createCommentUseCase = DefaultCreateCommentUseCase(repository: commentRepository)
        self.deleteCommentUseCase = DefaultDeleteCommentUseCase(repository: commentRepository)
        self.editCommentUseCase = DefaultEditCommentUseCase(repository: commentRepository)
        self.reportSpoilerFeedUseCase = DefaultReportSpoilerFeedUseCase(repository: socialRepository)
        self.reportImproperFeedUseCase = DefaultReportImproperFeedUseCase(repository: socialRepository)
        self.reportSpoilerCommentUseCase = DefaultReportSpoilerCommentUseCase(repository: socialRepository)
        self.reportImproperCommentUseCase = DefaultReportImproperCommentUseCase(repository: socialRepository)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Feed Detail Demo")
                    .font(.title2.bold())

                TextField("feed ID", text: $feedIDText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Button("이 피드 보기") {
                    guard let raw = Int(feedIDText) else { return }
                    pushedFeedID = FeedID(raw)
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("FeedFeature Demo")
            .navigationDestination(item: $pushedFeedID) { feedID in
                FeedFeatureFactory.makeFeedDetailView(
                    feedID: feedID,
                    loadFeedDetailUseCase: loadFeedDetailUseCase,
                    feedLikeUseCase: feedLikeUseCase,
                    loadCommentsUseCase: loadCommentsUseCase,
                    createCommentUseCase: createCommentUseCase,
                    deleteCommentUseCase: deleteCommentUseCase,
                    editCommentUseCase: editCommentUseCase,
                    reportSpoilerFeedUseCase: reportSpoilerFeedUseCase,
                    reportImproperFeedUseCase: reportImproperFeedUseCase,
                    reportSpoilerCommentUseCase: reportSpoilerCommentUseCase,
                    reportImproperCommentUseCase: reportImproperCommentUseCase
                )
            }
        }
    }
}
