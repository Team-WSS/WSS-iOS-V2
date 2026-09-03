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
import CommentDomain
import ProfileDomain
import SocialDomain

import FeedData
import BaseData
import CommentData
import ProfileData
import SocialData

import Networking
import Logger

/// 피드 리스트(내 피드 + 소소피드) 화면 단독 데모. 셀을 탭하면 실서버 피드 상세를 push한다 —
/// 재진입 시 목록 재조회 없이 **다녀온 셀만** 상세로 동기화되는지(스크롤 유지·좋아요/댓글수/삭제 반영)를
/// 앱 로그인 없이 확인하기 위한 배선(테스트 API 키 사용).
struct SosoFeedDemoScene: View {

    @State private var openedFeedID: FeedID?

    private let currentUserID: Int?

    private let loadMyFeedsUseCase: LoadMyFeedsUseCase
    private let loadSosoFeedsUseCase: LoadSosoFeedsUseCase
    private let loadFeedDetailUseCase: LoadFeedDetailUseCase
    private let feedLikeUseCase: FeedLikeUseCase
    private let loadProfileUseCase: LoadProfileUseCase
    private let deleteFeedUseCase: DeleteFeedUseCase
    private let reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase
    private let reportImproperFeedUseCase: ReportImproperFeedUseCase

    // 피드 상세 push용
    private let loadCommentsUseCase: LoadCommentsUseCase
    private let createCommentUseCase: CreateCommentUseCase
    private let editCommentUseCase: EditCommentUseCase
    private let deleteCommentUseCase: DeleteCommentUseCase
    private let reportSpoilerCommentUseCase: ReportSpoilerCommentUseCase
    private let reportImproperCommentUseCase: ReportImproperCommentUseCase

    init() {
        let client = NetworkingClient(tokenStore: DemoSessionTokenStore())
        let storage = UserDefaultsStorage()
        self.currentUserID = storage.get(.userID)

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
        let commentRepository = CommentDataFactory.makeCommentRepository(
            client: client,
            logger: DataLogger(moduleName: "CommentData", underlying: OSLogger.comment)
        )

        self.loadMyFeedsUseCase = DefaultLoadMyFeedsUseCase(feedRepository: feedRepository)
        self.loadSosoFeedsUseCase = DefaultLoadSosoFeedsUseCase(feedRepository: feedRepository)
        self.loadFeedDetailUseCase = DefaultLoadFeedUseCase(feedRepository: feedRepository)
        self.feedLikeUseCase = DefaultLikeUseCase(feedRepository: feedRepository)
        self.loadProfileUseCase = DefaultLoadProfileUseCase(profileRepository: profileRepository)
        self.deleteFeedUseCase = DefaultDeleteFeedUseCase(repository: feedRepository)
        self.reportSpoilerFeedUseCase = DefaultReportSpoilerFeedUseCase(repository: socialRepository)
        self.reportImproperFeedUseCase = DefaultReportImproperFeedUseCase(repository: socialRepository)

        self.loadCommentsUseCase = DefaultLoadCommentsUseCase(repository: commentRepository)
        self.createCommentUseCase = DefaultCreateCommentUseCase(repository: commentRepository)
        self.editCommentUseCase = DefaultEditCommentUseCase(repository: commentRepository)
        self.deleteCommentUseCase = DefaultDeleteCommentUseCase(repository: commentRepository)
        self.reportSpoilerCommentUseCase = DefaultReportSpoilerCommentUseCase(repository: socialRepository)
        self.reportImproperCommentUseCase = DefaultReportImproperCommentUseCase(repository: socialRepository)
    }

    var body: some View {
        NavigationStack {
            FeedFeatureFactory.makeSosoFeedView(
                loadMyFeedsUseCase: loadMyFeedsUseCase,
                loadSosoFeedsUseCase: loadSosoFeedsUseCase,
                loadFeedDetailUseCase: loadFeedDetailUseCase,
                feedLikeUseCase: feedLikeUseCase,
                loadProfileUseCase: loadProfileUseCase,
                deleteFeedUseCase: deleteFeedUseCase,
                reportSpoilerFeedUseCase: reportSpoilerFeedUseCase,
                reportImproperFeedUseCase: reportImproperFeedUseCase,
                logger: OSLogger.feed,
                onEditFeedTapped: { print("피드 수정 진입: \($0)") },
                onFeedTapped: { openedFeedID = $0 }
            )
            .navigationDestination(item: $openedFeedID) { feedID in
                FeedFeatureFactory.makeFeedDetailView(
                    feedID: feedID,
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
                    reportImproperCommentUseCase: reportImproperCommentUseCase,
                    loadProfileUseCase: loadProfileUseCase,
                    logger: OSLogger.feed,
                    onNovelTapped: { print("작품 상세 진입: \($0)") }
                )
            }
        }
    }
}
