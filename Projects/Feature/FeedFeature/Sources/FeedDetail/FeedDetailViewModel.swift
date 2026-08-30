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
import ProfileDomain
import WSSComponent
import Logger

@Observable
@MainActor
final class FeedDetailViewModel {
    
    // MARK: - State

    public struct State {
        var detail: FeedDetail?
        var comments: [FeedComment]
        var isLoading: Bool
        var commentText: String
        /// 댓글 입력창에 표시할 로그인한 사용자의 프로필 이미지.
        /// TODO: 현재는 서버(`LoadProfileUseCase`)에서 매번 조회한다. 추후 userDefaults 로컬 캐시로 전환 예정.
        var currentUserProfileImageURL: URL?
        var editingCommentID: CommentID?
        var isSubmittingComment: Bool = false
        var didDeleteFeed: Bool = false
        /// 현재 떠 있는 알럿의 의미값. `nil`이면 알럿 없음 — View는 이 값 하나로 모든 알럿을 표현한다.
        var alert: AlertType?
        /// 피드 상세 조회가 `alert`로 표현되는 사유(존재하지 않음·접근 불가)가 아닌 다른 이유로
        /// 실패했는지 — 전면 실패 뷰(재시도 가능)로 표현한다.
        /// 댓글 조회의 동종 실패는 화면 전체를 덮지 않고 로그만 남긴다(부차 콘텐츠).
        var detailLoadFailed: Bool = false
        /// 피드/댓글 작성자 프로필 탭이 탈퇴 유저(`Author.accessibleUserId == nil`)를 가리킬 때 뜨는
        /// 안내 토스트(`WSSToastType.unknownUser`) — 둘 다 같은 화면·같은 의미라 상태를 공유한다
        /// (`SosoFeedViewModel.isUnavailableUserToastPresented`와 동일 패턴).
        var isUnavailableUserToastPresented = false
        /// 댓글 작성/수정/삭제·피드 삭제가 실패했을 때 뜨는 "네트워크 지연" 토스트(`WSSToastType.networkDelay`).
        /// V1은 이 실패들을 조용히 삼키지 않고 토스트로 알리고 전송 버튼을 재활성했다(#222 회귀 복원) —
        /// 콘텐츠는 멀쩡하고 그 행동만 실패한 "사용자 액션 실패"라 전면 뷰가 아니라 토스트로 표현한다
        /// ([Feature CLAUDE.md](../CLAUDE.md)의 로드 실패 표현 계약).
        var isActionFailedToastPresented = false
    }

    public func isMyComment(_ comment: FeedComment) -> Bool {
        guard let currentUserID, let authorID = comment.user.userId?.value else { return false }
        return currentUserID == authorID
    }

    public var isMyFeed: Bool {
        guard let currentUserID, let authorID = state.detail?.author.userId?.value else { return false }
        return currentUserID == authorID
    }

    public enum AlertType: Equatable {
        case reportSpoiler(commentID: CommentID?)
        case reportImproper(commentID: CommentID?)

        case reportSpoilerCompleted
        case reportImproperCompleted

        case deleteComment(CommentID)
        case deleteFeed

        /// 피드 상세/댓글 조회가 "존재하지 않음"(404) 또는 "접근 불가"(403 — 숨김·차단)로 실패함.
        /// 서버가 사유를 세분화해 내려줘도 이 화면은 하나의 알럿으로 뭉뚱그려 보여준다.
        case feedUnavailable
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

    private let loadProfileUseCase: LoadProfileUseCase

    private let logger: Logger?

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
        reportImproperCommentUseCase: ReportImproperCommentUseCase,
        loadProfileUseCase: LoadProfileUseCase,
        logger: Logger? = nil
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
        self.loadProfileUseCase = loadProfileUseCase
        self.logger = logger
    }

    
    // MARK: - Action
    
    public enum Action {
        case load
        case toggleLike
        case updateCommentText(String)
        case submitComment
        case beginEditingComment(CommentID)
        case cancelEditingComment

        /// 알럿 하나로 화면의 모든 확인/신고/완료 알럿을 표현한다 — present → (confirm | dismiss).
        case presentAlert(AlertType)
        case confirmAlert
        case dismissAlert

        /// View가 `Author.accessibleUserId == nil`(탈퇴 유저)로 판정해서 부른다 — 피드 헤더 프로필,
        /// 댓글 프로필 둘 다 같은 액션을 쓴다.
        case userProfileUnavailableTapped
        case dismissUnavailableUserToast

        case dismissActionFailedToast
    }

    public func handle(_ action: Action) async {
        switch action {
        case .load:
            Task { await loadFeed() }
            Task { await loadComments() }
            Task { await loadCurrentUserProfileImage() }

        case .updateCommentText(let text):
            state.commentText = text

        case .submitComment:
            guard !state.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            state.isSubmittingComment = true
            let didSucceed: Bool
            if let editingID = state.editingCommentID {
                didSucceed = await editComment(commentID: editingID)
            } else {
                didSucceed = await createComment()
            }
            state.isSubmittingComment = false
            // 실패 시 입력 내용·수정 모드를 그대로 두어(=전송 버튼 재활성) 재시도하게 하고 토스트로 알린다.
            // 성공했을 때만 입력을 비우고 목록을 갱신한다(V1 parity, #222).
            guard didSucceed else {
                state.isActionFailedToastPresented = true
                return
            }
            state.editingCommentID = nil
            state.commentText = ""
            Task { await loadComments() }

        case .beginEditingComment(let commentID):
            beginEditingComment(commentID: commentID)

        case .cancelEditingComment:
            state.editingCommentID = nil
            state.commentText = ""

        case .toggleLike:
            await toggleLike()

        case .presentAlert(let type):
            state.alert = type

        case .confirmAlert:
            await confirmAlert()

        case .dismissAlert:
            state.alert = nil

        case .userProfileUnavailableTapped:
            state.isUnavailableUserToastPresented = true

        case .dismissUnavailableUserToast:
            state.isUnavailableUserToastPresented = false

        case .dismissActionFailedToast:
            state.isActionFailedToastPresented = false
        }
    }

    //MARK: - Custom Method

    private func loadFeed() async {
        state.isLoading = true
        state.detailLoadFailed = false
        defer { state.isLoading = false }

        do {
            let feed = try await loadFeedDetailUseCase.execute(feedID: feedID)
            state.detail = feed
        } catch {
            if isFeedUnavailable(error) {
                state.alert = .feedUnavailable
            } else {
                logger?.error("FeedDetail fetchFeedDetail 실패: \(String(describing: error))")
                state.detailLoadFailed = true
            }
        }
    }

    private func loadComments() async {
        do {
            let comments = try await loadCommentsUseCase.execute(feedID: feedID)
            state.comments = comments
        } catch {
            if isFeedUnavailable(error) {
                state.alert = .feedUnavailable
            } else {
                logger?.error("FeedDetail loadComments 실패: \(String(describing: error))")
            }
        }
    }

    /// 댓글 입력창 프로필 이미지 — 부차 콘텐츠라 실패해도 로그만 남기고 기본(회색) 표시로 둔다.
    private func loadCurrentUserProfileImage() async {
        do {
            let profile = try await loadProfileUseCase.execute(target: .me)
            state.currentUserProfileImageURL = profile.characterImage
        } catch {
            logger?.error("FeedDetail loadCurrentUserProfileImage 실패: \(String(describing: error))")
        }
    }

    /// `.notFound`(삭제됨)·`.forbidden`(숨김·차단)은 서버가 사유를 세분화해도 이 화면에서는
    /// 하나의 "피드를 찾을 수 없어요" 알럿으로 뭉뚱그린다.
    private func isFeedUnavailable(_ error: RepositoryError) -> Bool {
        error == .notFound || error == .forbidden
    }

    /// 현재 떠 있는 알럿(`state.alert`)의 "확인" 버튼 동작. 신고류는 완료 알럿으로 전환하고,
    /// 그 외(삭제·안내)는 실행 후 알럿을 닫는다.
    private func confirmAlert() async {
        guard let alert = state.alert else { return }
        switch alert {
        case .reportSpoiler(let commentID):
            await reportSpoiler(commentID: commentID)
            state.alert = .reportSpoilerCompleted

        case .reportImproper(let commentID):
            await reportImproper(commentID: commentID)
            state.alert = .reportImproperCompleted

        case .reportSpoilerCompleted, .reportImproperCompleted, .feedUnavailable:
            state.alert = nil

        case .deleteComment(let commentID):
            await deleteComment(commentID: commentID)
            state.alert = nil

        case .deleteFeed:
            await deleteFeed()
            state.alert = nil
        }
    }

    /// `commentID`가 있으면 댓글 신고, 없으면 피드 자체 신고.
    private func reportSpoiler(commentID: CommentID?) async {
        if let commentID {
            try? await reportSpoilerCommentUseCase.execute(feedID: feedID, commentID: commentID)
        } else {
            try? await reportSpoilerFeedUseCase.execute(id: feedID)
        }
    }

    /// `commentID`가 있으면 댓글 신고, 없으면 피드 자체 신고.
    private func reportImproper(commentID: CommentID?) async {
        if let commentID {
            try? await reportImproperCommentUseCase.execute(feedID: feedID, commentID: commentID)
        } else {
            try? await reportImproperFeedUseCase.execute(id: feedID)
        }
    }

    private func deleteFeed() async {
        do {
            try await deleteFeedUseCase.execute(feedID: feedID)
            state.didDeleteFeed = true
        } catch {
            logger?.error("FeedDetail deleteFeed 실패: \(String(describing: error))")
            state.isActionFailedToastPresented = true
        }
    }

    /// 성공하면 true. 실패 시 로그 + false를 돌려줘 호출부(`submitComment`)가 입력을 보존하고 토스트를 띄운다.
    private func createComment() async -> Bool {
        let draft = CommentDraft(content: state.commentText)

        do {
            try await createCommentUseCase.execute(feedID: feedID, draft)
            state.detail?.addCommentCount()
            return true
        } catch {
            logger?.error("FeedDetail createComment 실패: \(String(describing: error))")
            return false
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
            logger?.error("FeedDetail deleteComment 실패: \(String(describing: error))")
            state.isActionFailedToastPresented = true
        }
    }

    /// 성공하면 true. 실패 시 로그 + false를 돌려줘 호출부(`submitComment`)가 입력을 보존하고 토스트를 띄운다.
    private func editComment(commentID: CommentID) async -> Bool {
        do {
            let draft = CommentDraft(content: state.commentText)
            try await editCommentUseCase.execute(commentID: commentID,
                                             feedID: feedID, draft)
            return true
        } catch {
            logger?.error("FeedDetail editComment 실패: \(String(describing: error))")
            return false
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
