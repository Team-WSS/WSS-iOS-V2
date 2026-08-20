//
//  FeedFeatureFactory.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/4/26.
//

import Foundation
import SwiftUI

import BaseDomain
import FeedDomain
import SearchDomain
import CommentDomain
import SocialDomain
import ProfileDomain
import SocialDomain
import Logger

/// FeedFeature 모듈의 외부 진입점.
public enum FeedFeatureFactory {

    /// 실제 UseCase를 주입해 CreateFeedView를 생성한다.
    /// - Parameter connectedNovel: 이미 연결된 상태로 화면을 열고 싶을 때(예: 작품 상세의 "나도 한마디" —
    ///   `NovelDetailFeature/CLAUDE.md`의 `onCreateFeedTapped` 참고) 넘긴다. `nil`(기본값)이면 평소처럼
    ///   연결 작품 없이 빈 draft로 시작한다.
    @MainActor
    public static func makeCreateFeedView(
        createFeedUseCase: CreateFeedUseCase,
        searchNovelUseCase: SearchNovelUseCase,
        connectedNovel: ConnectedNovel? = nil
    ) -> some View {
        CreateFeedView(
            viewModel: CreateFeedViewModel(
                createFeedUseCase: createFeedUseCase,
                searchNovelUseCase: searchNovelUseCase,
                initialDraft: emptyDraft(connectedNovel: connectedNovel)
            )
        )
    }

    /// 기존 피드를 수정하는 CreateFeedView를 생성한다. `feedID`만 받고, 화면이 뜨자마자 자기 스스로
    /// 대상 피드를 불러와(`.load`) `draft`/첨부 이미지를 채운다 — 호출자가 미리 데이터를 준비해 넘길
    /// 필요가 없다(수정 진입이 빠르게 화면 전환부터 되고, 로드 중임을 이 화면 안에서 보여준다, #197).
    @MainActor
    public static func makeEditFeedView(
        feedID: FeedID,
        editFeedUseCase: EditFeedUseCase,
        searchNovelUseCase: SearchNovelUseCase,
        loadFeedDetailUseCase: LoadFeedDetailUseCase
    ) -> some View {
        CreateFeedView(
            viewModel: CreateFeedViewModel(
                mode: .edit(feedID),
                editFeedUseCase: editFeedUseCase,
                searchNovelUseCase: searchNovelUseCase,
                loadFeedDetailUseCase: loadFeedDetailUseCase,
                initialDraft: emptyDraft()
            )
        )
    }

    /// 네트워크 없이 ViewModel/View 동작만 확인하기 위한 임시 진입점.
    /// 제출 시 1초 후 성공으로 처리한다.
    @MainActor
    public static func makeCreateFeedPreviewView() -> some View {
        makeCreateFeedView(createFeedUseCase: StubCreateFeedUseCase(),
                           searchNovelUseCase: StubSearchNovelUseCase())
    }

    /// 실제 UseCase를 주입해 FeedDetailView를 생성한다.
    /// 진입 시 `feedID`만 받고, 상세/댓글은 화면에서 직접 load한다.
    @MainActor
    public static func makeFeedDetailView(
        feedID: FeedID,
        currentUserID: Int?,
        loadFeedDetailUseCase: LoadFeedDetailUseCase,
        feedLikeUseCase: FeedLikeUseCase,
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
        logger: Logger? = nil,
        onNovelTapped: @escaping (NovelID) -> Void,
        onEditFeedTapped: @escaping (FeedID) -> Void = { _ in }
    ) -> some View {
        FeedDetailView(
            viewModel: FeedDetailViewModel(
                feedID: feedID,
                currentUserID: currentUserID,
                loadFeedDetailUseCase: loadFeedDetailUseCase,
                feedLikeUsecase: feedLikeUseCase,
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
                logger: logger
            ),
            onNovelTapped: onNovelTapped,
            onEditFeedTapped: onEditFeedTapped
        )
    }

    /// 실제 UseCase를 주입해 SosoFeedView를 생성한다.
    /// - Parameters:
    ///   - onEditFeedTapped: 피드 수정 진입 콜백 — 내 글 threedots 드롭다운의 "수정하기". 대상 피드
    ///     `FeedID`만 넘긴다 — 실제 데이터 로드는 수정 화면 자신이 한다(`makeEditFeedView` 참고).
    ///     실제 화면 전환(`makeEditFeedView` 조립)은 호출자(App 조정 계층)가 수행한다.
    ///   - onFeedTapped: 피드 셀 탭(좋아요 등 안쪽 인터랙션 제외) → 피드 상세 진입 콜백.
    ///     실제 화면 전환(`makeFeedDetailView` 조립)은 호출자(App 조정 계층)가 수행한다.
    ///   - onCreateFeedTapped: 우상단 연필 아이콘 → 피드 작성 진입 콜백.
    ///     실제 화면 전환(`makeCreateFeedView` 조립)은 호출자(App 조정 계층)가 수행한다.
    ///   - onUserProfileTapped: 작성자 프로필(이미지+닉네임) 탭 → 유저 프로필 진입 콜백.
    ///     실제 화면 전환(`UserPageFactory.makeView` 조립)은 호출자(App 조정 계층)가 수행한다.
    ///   - onNovelTapped: 연결 작품 배너 탭 → 작품 상세 진입 콜백.
    ///     실제 화면 전환(`NovelDetailFactory` 조립)은 호출자(App 조정 계층)가 수행한다.
    @MainActor
    public static func makeSosoFeedView(
        loadMyFeedsUseCase: LoadMyFeedsUseCase,
        loadSosoFeedsUseCase: LoadSosoFeedsUseCase,
        feedLikeUseCase: FeedLikeUseCase,
        loadProfileUseCase: LoadProfileUseCase,
        deleteFeedUseCase: DeleteFeedUseCase,
        reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase,
        reportImproperFeedUseCase: ReportImproperFeedUseCase,
        logger: Logger? = nil,
        onEditFeedTapped: @escaping (FeedID) -> Void = { _ in },
        onFeedTapped: @escaping (FeedID) -> Void = { _ in },
        onCreateFeedTapped: @escaping () -> Void = {},
        onUserProfileTapped: @escaping (UserID) -> Void = { _ in },
        onNovelTapped: @escaping (NovelID) -> Void = { _ in }
    ) -> some View {
        SosoFeedView(
            viewModel: SosoFeedViewModel(
                loadMyFeedsUseCase: loadMyFeedsUseCase,
                loadsosoFeedsUseCase: loadSosoFeedsUseCase,
                feedLikeUseCase: feedLikeUseCase,
                loadProfileUseCase: loadProfileUseCase,
                deleteFeedUseCase: deleteFeedUseCase,
                reportSpoilerFeedUseCase: reportSpoilerFeedUseCase,
                reportImproperFeedUseCase: reportImproperFeedUseCase,
                logger: logger
            ),
            onEditFeedTapped: onEditFeedTapped,
            onFeedTapped: onFeedTapped,
            onCreateFeedTapped: onCreateFeedTapped,
            onUserProfileTapped: onUserProfileTapped,
            onNovelTapped: onNovelTapped
        )
    }

    private static func emptyDraft(connectedNovel: ConnectedNovel? = nil) -> FeedDraft {
        FeedDraft(
            content: "",
            isSpoiler: false,
            isPrivate: false,
            connectedNovel: connectedNovel,
            attachedImages: []
        )
    }
}

/// 검증용 Stub — 항상 1초 후 성공.
private struct StubCreateFeedUseCase: CreateFeedUseCase {
    func execute(_ draft: FeedDraft, imageDatas: [Data]) async throws(RepositoryError) {
        try? await Task.sleep(for: .seconds(1))
    }
}

private struct StubSearchNovelUseCase: SearchNovelUseCase {
    func searchByText(_ query: String, page: Int) async throws(BaseDomain.RepositoryError) -> (Paginated<Novel>, Int) {
        return (Paginated(items: stubNovels, hasNext: false), 0)
    }

    func searchByFilter(_ filter: SearchDomain.SearchFilter, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        return (Paginated(items: [], hasNext: false), 0)
    }
}

let stubNovels: [Novel] = [
    Novel(
        id: NovelID(1),
        thumbnailImage: URL(string: "https://i.pinimg.com/736x/58/0a/13/580a13692bdefec82fc37cdc8e87e331.jpg"),
        title: "회귀한 천재 마법사",
        authors: ["김작가"],
        genres: [],
        interestCount: 12543,
        rating: 4.8,
        ratingCount: 3214
    ),
    Novel(
        id: NovelID(2),
        thumbnailImage: URL(string: "https://i.pinimg.com/736x/12/49/04/124904e3933472601d83f8ff771def50.jpg"),
        title: "멸망한 세계의 검신",
        authors: ["이판타지"],
        genres: [],
        interestCount: 8932,
        rating: 4.6,
        ratingCount: 1875
    ),
    Novel(
        id: NovelID(3),
        thumbnailImage: URL(string: "https://i.pinimg.com/736x/fc/11/ed/fc11ed1b94cc32feefc9e40f1b2d8f65.jpg"),
        title: "재벌집 막내아들",
        authors: ["산경"],
        genres: [],
        interestCount: 25431,
        rating: 4.9,
        ratingCount: 10234
    ),
    Novel(
        id: NovelID(4),
        thumbnailImage: URL(string: "https://i.pinimg.com/1200x/b9/94/6e/b9946e9db54c175c490b54dfd40adc41.jpg"),
        title: "나 혼자만 레벨업",
        authors: ["추공"],
        genres: [],
        interestCount: 51234,
        rating: 4.9,
        ratingCount: 25431
    ),
    Novel(
        id: NovelID(5),
        thumbnailImage: URL(string: "https://i.pinimg.com/1200x/d6/49/7a/d6497aefa2800044f63cbf66889fb4df.jpg"),
        title: "전지적 독자 시점",
        authors: ["싱숑"],
        genres: [],
        interestCount: 43892,
        rating: 4.8,
        ratingCount: 19876
    ),
    Novel(
        id: NovelID(6),
        thumbnailImage: URL(string: "https://i.pinimg.com/1200x/20/55/03/20550396102b05d92c4a04f9136352d5.jpg"),
        title: "아카데미의 천재 검술가",
        authors: ["홍길동", "김철수"],
        genres: [],
        interestCount: 7234,
        rating: 4.3,
        ratingCount: 912
    ),
    Novel(
        id: NovelID(7),
        thumbnailImage: URL(string: "https://i.pinimg.com/736x/01/7b/8d/017b8dd944076cb85da607fe2d94237a.jpg"),
        title: "21세기 대군 부인",
        authors: ["박작가"],
        genres: [],
        interestCount: 16782,
        rating: 4.7,
        ratingCount: 3842
    ),
    Novel(
        id: NovelID(8),
        thumbnailImage: URL(string: "https://i.pinimg.com/736x/69/80/22/69802233c6656902b1eedb94f6b338b2.jpg"),
        title: "망겜의 성기사",
        authors: ["최작가"],
        genres: [],
        interestCount: 5321,
        rating: 4.1,
        ratingCount: 623
    )]
