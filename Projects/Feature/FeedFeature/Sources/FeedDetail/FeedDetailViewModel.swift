//
//  FeedDetailViewModel.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/12/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import FeedDomain
import CommentDomain
import SocialDomain
import WSSComponent

/// 피드 상세 화면 ViewModel.
///
/// `FeedDetail` 엔티티의 표시값 변환 + nullable 분기를 단일 진입점에서 처리한다.
@Observable
@MainActor
public final class FeedDetailViewModel {
    
    // MARK: - State

    public struct State {
        var detail: FeedDetail?
        var comments: [FeedComment]
        var isLoading: Bool
    }

    public struct ConnectedNovelDisplay {
        public let imageURL: URL?
        public let title: String
        public let description: String
        public let genre: NovelGenre
        public let totalRating: Float
        public let feedUserRating: Float
    }

    public var header: FeedHeader? {
        guard let detail = state.detail else { return nil }
        return FeedHeader(
            profileImageURL: detail.author.profileImage,
            nickname: detail.author.nickname,
            createdDate: detail.createdDate,
            isEdited: detail.isModified
        )
    }

    public var hasAttachedImages: Bool {
        state.detail?.feedImageURLs.isEmpty == false
    }

    public var attachedImageURLs: [URL?] {
        state.detail?.feedImageURLs ?? []
    }

    // MARK: - Properties

    public private(set) var state: State

    private let feedID: FeedID

    private let loadFeedDetailUseCase: LoadFeedDetailUseCase
    private let feedLikeUsecase: FeedLikeUseCase

    private let loadCommentsUseCase: LoadCommentsUseCase
    private let createCommentUseCase: CreateCommentUseCase
    private let deleteCommentUseCase: DeleteCommentUseCase
    private let editCommentUseCase: EditCommentUseCase
    
    private let reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase
    private let reportImproperFeedUseCase: ReportImproperFeedUseCase
    private let reportSpoilerCommentUseCase: ReportSpoilerCommentUseCase
    private let reportImproperCommentUseCase: ReportImproperCommentUseCase

    // MARK: - Init

    public init(
        feedID: FeedID,
        loadFeedDetailUseCase: LoadFeedDetailUseCase,
        feedLikeUsecase: FeedLikeUseCase,
        loadCommentsUseCase: LoadCommentsUseCase,
        createCommentUseCase: CreateCommentUseCase,
        deleteCommentUseCase: DeleteCommentUseCase,
        editCommentUseCase: EditCommentUseCase,
        reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase,
        reportImproperFeedUseCase: ReportImproperFeedUseCase,
        reportSpoilerCommentUseCase: ReportSpoilerCommentUseCase,
        reportImproperCommentUseCase: ReportImproperCommentUseCase
    ) {
        self.feedID = feedID
        self.state = State(detail: nil,
                           comments: [],
                           isLoading: false)
        self.loadFeedDetailUseCase = loadFeedDetailUseCase
        self.feedLikeUsecase = feedLikeUsecase
        self.loadCommentsUseCase = loadCommentsUseCase
        self.createCommentUseCase = createCommentUseCase
        self.deleteCommentUseCase = deleteCommentUseCase
        self.editCommentUseCase = editCommentUseCase
        self.reportSpoilerFeedUseCase = reportSpoilerFeedUseCase
        self.reportImproperFeedUseCase = reportImproperFeedUseCase
        self.reportSpoilerCommentUseCase = reportSpoilerCommentUseCase
        self.reportImproperCommentUseCase = reportImproperCommentUseCase
    }

    /// nil이면 연결 작품 블록을 렌더링하지 않는다.
    public var connectedNovel: ConnectedNovelDisplay? {
        guard let novel = state.detail?.connectedNovel else { return nil }
        return ConnectedNovelDisplay(
            imageURL: novel.thumbnailImageURL,
            title: novel.basicInfo.title,
            description: novel.descirption,
            genre: novel.basicInfo.genre,
            totalRating: novel.basicInfo.rating ?? 0,
            feedUserRating: novel.feedWriterRating ?? 0
        )
    }
    
    // MARK: - Action
    
    public enum Action {
        case load
        case toggleLike
    }
    
    public func handle(_ action: Action) async {
        switch action {
        case .load:
            Task { await loadFeed() }
            Task {await loadComments() }
        case .toggleLike:
            await toggleLike()
        }
    }

    //MARK: - Custom Method

    private func loadFeed() async {
        state.isLoading = true
        defer { state.isLoading = false }

        do {
            let feed = try await loadFeedDetailUseCase.execute(feedID: feedID)
            state.detail = feed
        } catch {
            
        }
    }

    private func loadComments() async {
        do {
            let comments = try await loadCommentsUseCase.execute(feedID: feedID)
            state.comments = comments
        } catch {

        }
    }

    /// 낙관적 업데이트: 먼저 엔티티를 토글해 즉시 UI를 반영하고,
    /// 서버 호출이 실패하면 동일한 토글을 한 번 더 호출해 이전 상태로 되돌린다.
    private func toggleLike() async {
        guard state.detail != nil else { return }

        let wasLiked = state.detail!.isLiked
        try? state.detail!.toggleLike()

        do {
            if wasLiked {
                try await feedLikeUsecase.unlike(feedID: feedID)
            } else {
                try await feedLikeUsecase.like(feedID: feedID)
            }
        } catch {
            try? state.detail!.toggleLike()
        }
    }
}
