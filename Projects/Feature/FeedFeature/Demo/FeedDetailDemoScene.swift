//
//  FeedDetailDemoScene.swift
//  FeedFeatureDemo
//
//  Created by Seoyeon Choi on 6/21/26.
//

import SwiftUI

import FeedFeature
import FeedDomain
import BaseDomain
import CommentDomain
import SocialDomain

import FeedData
import BaseData
import CommentData
import SocialData

import Networking
import Logger

/// 피드 상세 화면 단독 데모. 진입 시 텍스트필드로 feedID를 입력받아 push.
struct FeedDetailDemoScene: View {

    @State private var feedIDText: String = "4641"
    @State private var openedFeedID: Int?

    private let currentUserID: Int?

    private let loadFeedDetailUseCase: LoadFeedDetailUseCase
    private let feedLikeUseCase: FeedLikeUseCase
    private let deleteFeedUseCase: DeleteFeedUseCase

    private let loadCommentsUseCase: LoadCommentsUseCase
    private let createCommentUseCase: CreateCommentUseCase
    private let editCommentUseCase: EditCommentUseCase
    private let deleteCommentUseCase: DeleteCommentUseCase

    private let reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase
    private let reportImproperFeedUseCase: ReportImproperFeedUseCase
    private let reportSpoilerCommentUseCase: ReportSpoilerCommentUseCase
    private let reportImproperCommentUseCase: ReportImproperCommentUseCase

    init() {
        let storage = UserDefaultsStorage()
        self.currentUserID = storage.get(.userID)

        let client = NetworkingClient(tokenStore: DemoSessionTokenStore())

        let feedRepository = FeedDataFactory.makeFeedRepository(
            client: client,
            logger: DataLogger(moduleName: "FeedData", underlying: OSLogger.feed)
        )

        let commentRepository = CommentDataFactory.makeCommentRepository(
            client: client,
            logger: DataLogger(moduleName: "CommentData", underlying: OSLogger.comment)
        )

        let socialRepository = SocialDataFactory.makeSocialRepository(
            client: client,
            logger: DataLogger(moduleName: "SocialData", underlying: OSLogger.social)
        )

        self.loadFeedDetailUseCase = DefaultLoadFeedUseCase(feedRepository: feedRepository)
        self.feedLikeUseCase = DefaultLikeUseCase(feedRepository: feedRepository)
        self.deleteFeedUseCase = DefaultDeleteFeedUseCase(repository: feedRepository)

        self.loadCommentsUseCase = DefaultLoadCommentsUseCase(repository: commentRepository)
        self.createCommentUseCase = DefaultCreateCommentUseCase(repository: commentRepository)
        self.editCommentUseCase = DefaultEditCommentUseCase(repository: commentRepository)
        self.deleteCommentUseCase = DefaultDeleteCommentUseCase(repository: commentRepository)

        self.reportSpoilerFeedUseCase = DefaultReportSpoilerFeedUseCase(repository: socialRepository)
        self.reportImproperFeedUseCase = DefaultReportImproperFeedUseCase(repository: socialRepository)
        self.reportSpoilerCommentUseCase = DefaultReportSpoilerCommentUseCase(repository: socialRepository)
        self.reportImproperCommentUseCase = DefaultReportImproperCommentUseCase(repository: socialRepository)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("FeedDetail Demo")
                    .font(.title2.bold())

                TextField("feedID", text: $feedIDText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)

                Button {
                    if let id = Int(feedIDText) {
                        openedFeedID = id
                    }
                } label: {
                    Text("피드 열기")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(Int(feedIDText) == nil)

                Spacer()
            }
            .padding(20)
            .navigationTitle("피드 상세 데모")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $openedFeedID) { id in
                FeedFeatureFactory.makeFeedDetailView(
                    feedID: FeedID(id),
                    currentUserID: currentUserID,
                    loadFeedDetailUseCase: loadFeedDetailUseCase,
                    feedLikeUseCase: feedLikeUseCase,
                    deleteFeedUseCase: deleteFeedUseCase,
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
