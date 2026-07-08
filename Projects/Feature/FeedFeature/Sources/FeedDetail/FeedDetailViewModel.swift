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

@Observable
@MainActor
public final class FeedDetailViewModel {
    
    // MARK: - State

    public struct State {
        var detail: FeedDetail?
        var comments: [FeedComment]
        var isLoading: Bool
        var commentText: String
        var editingCommentID: CommentID?
        var isSubmittingComment: Bool = false
        var didDeleteFeed: Bool = false
        var alert: AlertType?
    }

    public func isMyComment(_ comment: FeedComment) -> Bool {
        guard let currentUserID, let authorID = comment.user.userId?.value else { return false }
        return currentUserID == authorID
    }

    public var isMyFeed: Bool {
        guard let currentUserID, let authorID = state.detail?.author.userId?.value else { return false }
        return currentUserID == authorID
    }

    public var editingDraft: FeedDraft? {
        guard let detail = state.detail else { return nil }
        return FeedDraft(
            content: detail.feedContent,
            isSpoiler: detail.isSpoiler,
            isPrivate: !detail.isPublic,
            connectedNovel: detail.connectedNovel?.basicInfo,
            attachedImages: []
        )
    }
    
    public enum AlertType: Equatable {
        case reportSpoiler(commentID: CommentID?)
        case reportImproper(commentID: CommentID?)

        case reportSpoilerCompleted
        case reportImproperCompleted

        case deleteComment(CommentID)
        case deleteFeed
    }

    // MARK: - Properties

    public private(set) var state: State

    private let feedID: FeedID

    /// 로그인한 사용자 ID. App/Demo(DI)가 로컬 저장소에서 읽어 주입한다. 비로그인 시 nil.
    private let currentUserID: Int?

    private let loadFeedDetailUseCase: LoadFeedDetailUseCase
    private let feedLikeUsecase: FeedLikeUseCase
    private let deleteFeedUseCase: DeleteFeedUseCase

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
        currentUserID: Int?,
        loadFeedDetailUseCase: LoadFeedDetailUseCase,
        feedLikeUsecase: FeedLikeUseCase,
        deleteFeedUseCase: DeleteFeedUseCase,
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
        self.currentUserID = currentUserID
        self.state = State(detail: nil,
                           comments: [],
                           isLoading: false,
                           commentText: "",
                           editingCommentID: nil)
        self.loadFeedDetailUseCase = loadFeedDetailUseCase
        self.feedLikeUsecase = feedLikeUsecase
        self.deleteFeedUseCase = deleteFeedUseCase
        self.loadCommentsUseCase = loadCommentsUseCase
        self.createCommentUseCase = createCommentUseCase
        self.deleteCommentUseCase = deleteCommentUseCase
        self.editCommentUseCase = editCommentUseCase
        self.reportSpoilerFeedUseCase = reportSpoilerFeedUseCase
        self.reportImproperFeedUseCase = reportImproperFeedUseCase
        self.reportSpoilerCommentUseCase = reportSpoilerCommentUseCase
        self.reportImproperCommentUseCase = reportImproperCommentUseCase
    }

    
    // MARK: - Action
    
    public enum Action {
        case load
        case toggleLike
        case deleteFeed
        case updateCommentText(String)
        case submitComment
        case deleteComment(CommentID)
        case beginEditingComment(CommentID)
        case cancelEditingComment
        case reportSpoilerFeed
        case reportImproperFeed
        case reportSpoilerComment(CommentID)
        case reportImproperComment(CommentID)
    }

    public func handle(_ action: Action) async {
        switch action {
        case .load:
            Task { await loadFeed() }
            Task { await loadComments() }

        case .updateCommentText(let text):
            state.commentText = text

        case .submitComment:
            guard !state.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            state.isSubmittingComment = true
            if let editingID = state.editingCommentID {
                await editComment(commentID: editingID)
            } else {
                await createComment()
            }
            state.isSubmittingComment = false
            state.editingCommentID = nil
            state.commentText = ""
            Task { await loadComments() }

        case .deleteFeed:
            await deleteFeed()

        case .deleteComment(let commentID):
            await deleteComment(commentID: commentID)

        case .beginEditingComment(let commentID):
            beginEditingComment(commentID: commentID)

        case .cancelEditingComment:
            state.editingCommentID = nil
            state.commentText = ""

        case .toggleLike:
            await toggleLike()

        case .reportSpoilerFeed:
            try? await reportSpoilerFeedUseCase.execute(id: feedID)

        case .reportImproperFeed:
            try? await reportImproperFeedUseCase.execute(id: feedID)

        case .reportSpoilerComment(let commentID):
            try? await reportSpoilerCommentUseCase.execute(feedID: feedID, commentID: commentID)

        case .reportImproperComment(let commentID):
            try? await reportImproperCommentUseCase.execute(feedID: feedID, commentID: commentID)
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
    
    private func deleteFeed() async {
        do {
            try await deleteFeedUseCase.execute(feedID: feedID)
            state.didDeleteFeed = true
        } catch {

        }
    }

    private func createComment() async {
        let draft = CommentDraft(content: state.commentText)

        do {
            try await createCommentUseCase.execute(feedID: feedID, draft)
            state.detail?.addCommentCount()
        } catch {

        }
    }

    /// 대상 댓글의 본문을 입력바에 채우고 수정 모드로 전환한다.
    /// 댓글 목록에 없는 ID가 들어오면 무시.
    private func beginEditingComment(commentID: CommentID) {
        guard let comment = state.comments.first(where: { $0.id == commentID }) else { return }
        state.editingCommentID = commentID
        state.commentText = comment.content
    }

    /// 삭제 성공 시 목록에서 제거하고 피드의 댓글 카운트도 감소시킨다.
    private func deleteComment(commentID: CommentID) async {
        do {
            try await deleteCommentUseCase.execute(commentID: commentID, feedID: feedID)
            state.comments.removeAll { $0.id == commentID }
            state.detail?.removeCommentCount()
        } catch {

        }
    }
    
    private func editComment(commentID: CommentID) async {
        do {
            let draft = CommentDraft(content: state.commentText)
            try await editCommentUseCase.execute(commentID: commentID,
                                             feedID: feedID, draft)
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
