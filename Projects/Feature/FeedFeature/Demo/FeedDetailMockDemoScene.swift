//
//  FeedDetailMockDemoScene.swift
//  FeedFeatureDemo
//
//  피드 상세 화면을 **dev 서버 없이** 띄우는 오프라인 데모.
//  FeedDetailDemoScene은 실서버(NetworkingClient + 토큰)로만 동작해 시뮬레이터에서
//  네트워크가 막히면 화면 자체가 안 뜬다 — 이 씬은 mock UseCase를 주입해 그 의존을 끊는다.
//
//  #222 parity 복원 중 아래 두 가지를 눈으로 확인하기 위한 데모:
//   1) 조용한 실패 → "네트워크 지연" 토스트 + 입력 보존 (create/edit/delete UseCase가 일부러 throw)
//   3) 무변경 재전송 가드 → 빈 입력·수정 모드 무변경이면 전송 버튼 비활성
//

import SwiftUI

import FeedFeature
import BaseDomain
import FeedDomain
import CommentDomain
import SocialDomain
import ProfileDomain

/// 피드 상세 오프라인 데모. 진입 시 곧바로 상세 화면을 push한다(mock 데이터).
struct FeedDetailMockDemoScene: View {

    /// 로그인 유저로 가정하는 id. 피드/댓글 작성자와 같은 값이라 "내 글/내 댓글"로 취급된다
    /// (→ 피드·댓글 드롭다운에 "수정/삭제"가 뜨고, 댓글 수정 모드 진입이 가능해 #3을 확인할 수 있다).
    private let currentUserID = 2

    var body: some View {
        NavigationStack {
            FeedFeatureFactory.makeFeedDetailView(
                feedID: FeedID(1),
                currentUserID: currentUserID,
                loadFeedDetailUseCase: DemoMockLoadFeedDetailUseCase(),
                feedLikeUseCase: DemoMockFeedLikeUseCase(),
                deleteFeedUseCase: DemoMockFailingDeleteFeedUseCase(),
                loadCommentsUseCase: DemoMockLoadCommentsUseCase(),
                createCommentUseCase: DemoMockFailingCreateCommentUseCase(),
                deleteCommentUseCase: DemoMockFailingDeleteCommentUseCase(),
                editCommentUseCase: DemoMockFailingEditCommentUseCase(),
                reportSpoilerFeedUseCase: DemoMockReportSpoilerFeedUseCase(),
                reportImproperFeedUseCase: DemoMockReportImproperFeedUseCase(),
                reportSpoilerCommentUseCase: DemoMockReportSpoilerCommentUseCase(),
                reportImproperCommentUseCase: DemoMockReportImproperCommentUseCase(),
                loadProfileUseCase: DemoMockLoadProfileUseCase(),
                onNovelTapped: { print("작품 상세 진입: \($0)") }
            )
        }
    }
}

// MARK: - Mock UseCases (오프라인 데모 전용)

private struct DemoMockLoadFeedDetailUseCase: LoadFeedDetailUseCase {
    func execute(feedID: FeedID) async throws(RepositoryError) -> FeedDetail {
        FeedDetail(
            id: feedID,
            author: Author(
                userId: UserID(2),
                nickname: "구리구리스",
                profileImage: nil
            ),
            createdDate: "2026년 8월 30일",
            isModified: false,
            feedContent: "여주가 세계를 구함 이름이 나여주입니다ㅋㅋㅋ\n\n읽던 소설이 세계멸망 엔딩나서 댓글 달았다가 그 세계의 본인에게 빙의하게 되었는데, S급 힐러에 세계관 관련 중요 스킬까지 얻고 시작하는 스토리.",
            feedImageURLs: [],
            connectedNovel: nil,
            likeCount: 123,
            isLiked: true,
            commentCount: 1,
            isSpoiler: false,
            isPublic: true
        )
    }
}

private struct DemoMockLoadCommentsUseCase: LoadCommentsUseCase {
    func execute(feedID: FeedID) async throws(RepositoryError) -> [FeedComment] {
        [
            FeedComment(
                id: CommentID(1),
                user: Author(userId: UserID(2), nickname: "구리구리스", profileImage: nil),
                createdDate: "방금 전",
                content: "내가 쓴 댓글 — 수정 모드에서 안 바꾸면 전송 비활성(#3)",
                isModified: false,
                isSpoiler: false,
                isBlocked: false,
                isHidden: false
            )
        ]
    }
}

private struct DemoMockFeedLikeUseCase: FeedLikeUseCase {
    func like(feedID: FeedID) async throws(RepositoryError) { }
    func unlike(feedID: FeedID) async throws(RepositoryError) { }
}

/// #1 재현용 — 삭제가 항상 실패해 "네트워크 지연" 토스트를 띄운다.
private struct DemoMockFailingDeleteFeedUseCase: DeleteFeedUseCase {
    func execute(feedID: FeedID) async throws(RepositoryError) { throw .networkUnavailable }
}

/// #1 재현용 — 댓글 작성이 항상 실패해 입력 내용을 보존하고 토스트를 띄운다.
private struct DemoMockFailingCreateCommentUseCase: CreateCommentUseCase {
    func execute(feedID: FeedID, _ draft: CommentDraft) async throws(RepositoryError) { throw .networkUnavailable }
}

/// #1 재현용 — 댓글 수정이 항상 실패해 수정 모드/입력을 보존하고 토스트를 띄운다.
private struct DemoMockFailingEditCommentUseCase: EditCommentUseCase {
    func execute(commentID: CommentID, feedID: FeedID, _ draft: CommentDraft) async throws(RepositoryError) { throw .networkUnavailable }
}

/// #1 재현용 — 댓글 삭제가 항상 실패해 토스트를 띄운다.
private struct DemoMockFailingDeleteCommentUseCase: DeleteCommentUseCase {
    func execute(commentID: CommentID, feedID: FeedID) async throws(RepositoryError) { throw .networkUnavailable }
}

private struct DemoMockReportSpoilerFeedUseCase: ReportSpoilerFeedUseCase {
    func execute(id: FeedID) async throws(RepositoryError) { }
}

private struct DemoMockReportImproperFeedUseCase: ReportImproperFeedUseCase {
    func execute(id: FeedID) async throws(RepositoryError) { }
}

private struct DemoMockReportSpoilerCommentUseCase: ReportSpoilerCommentUseCase {
    func execute(feedID: FeedID, commentID: CommentID) async throws(RepositoryError) { }
}

private struct DemoMockReportImproperCommentUseCase: ReportImproperCommentUseCase {
    func execute(feedID: FeedID, commentID: CommentID) async throws(RepositoryError) { }
}

private struct DemoMockLoadProfileUseCase: LoadProfileUseCase {
    func execute(target: ProfileTarget) async throws(RepositoryError) -> Profile {
        Profile(
            nickname: "구리구리스",
            introduction: "",
            characterImage: nil,
            isPublic: true,
            genrePreferences: []
        )
    }
}
