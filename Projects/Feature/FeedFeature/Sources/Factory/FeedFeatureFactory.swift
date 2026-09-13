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
import Logger
import Analytics

/// FeedFeature 모듈의 외부 진입점.
public enum FeedFeatureFactory {

    /// 실제 UseCase를 주입해 CreateFeedView를 생성한다.
    /// - Parameter connectedNovel: 이미 연결된 상태로 화면을 열고 싶을 때(예: 작품 상세의 "나도 한마디" —
    ///   `NovelDetailFeature/CLAUDE.md`의 `.createFeed` 라우트 참고) 넘긴다. `nil`(기본값)이면 평소처럼
    ///   연결 작품 없이 빈 draft로 시작한다.
    @MainActor
    public static func makeCreateFeedView(
        createFeedUseCase: CreateFeedUseCase,
        searchNovelUseCase: SearchNovelUseCase,
        appReviewUseCase: AppReviewRequestUseCase,
        connectedNovel: ConnectedNovel? = nil,
        analyticsTracker: AnalyticsTracker? = nil,
        // 기본값을 일부러 두지 않는다 — 작성 조립은 탭 Root 4곳에 복제돼 있어(App/CLAUDE.md "5곳" 경고),
        // 기본 no-op이 있으면 새 조립 지점이 완료 토스트를 말없이 빼먹어도 컴파일이 통과한다(#236 리뷰).
        onSubmitted: @escaping () -> Void
    ) -> some View {
        CreateFeedView(
            viewModel: CreateFeedViewModel(
                createFeedUseCase: createFeedUseCase,
                searchNovelUseCase: searchNovelUseCase,
                appReviewUseCase: appReviewUseCase,
                initialDraft: emptyDraft(connectedNovel: connectedNovel),
                analyticsTracker: analyticsTracker
            ),
            onSubmitted: onSubmitted
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
        loadFeedDetailUseCase: LoadFeedDetailUseCase,
        appReviewUseCase: AppReviewRequestUseCase,
        analyticsTracker: AnalyticsTracker? = nil,
        onSubmitted: @escaping () -> Void
    ) -> some View {
        CreateFeedView(
            viewModel: CreateFeedViewModel(
                mode: .edit(feedID),
                editFeedUseCase: editFeedUseCase,
                searchNovelUseCase: searchNovelUseCase,
                loadFeedDetailUseCase: loadFeedDetailUseCase,
                appReviewUseCase: appReviewUseCase,
                initialDraft: emptyDraft(),
                analyticsTracker: analyticsTracker
            ),
            onSubmitted: onSubmitted
        )
    }

    /// 네트워크 없이 ViewModel/View 동작만 확인하기 위한 임시 진입점.
    /// 제출 시 1초 후 성공으로 처리한다.
    @MainActor
    public static func makeCreateFeedPreviewView() -> some View {
        makeCreateFeedView(createFeedUseCase: StubCreateFeedUseCase(),
                           searchNovelUseCase: StubSearchNovelUseCase(),
                           appReviewUseCase: StubAppReviewRequestUseCase(),
                           onSubmitted: {})
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
        analyticsTracker: AnalyticsTracker? = nil,
        onRoute: @escaping (FeedDetailRoute) -> Void,
        onAuthenticationRequired: @escaping () -> Void = {}
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
                logger: logger,
                analyticsTracker: analyticsTracker
            ),
            onRoute: onRoute,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    /// 실제 UseCase를 주입해 SosoFeedView를 생성한다.
    /// - Parameters:
    ///   - loadFeedDetailUseCase: 재진입 시 **다녀온 셀만** 상세 API로 다시 맞추는 데 쓴다(이 화면은 재진입에
    ///     목록을 다시 받지 않는다 — 스크롤·길이 보존). 구현 클래스명은 `DefaultLoadFeedUseCase`.
    ///   - needsReloadForCreatedFeed: 피드 탭 연필 아이콘 작성 성공 복귀 신호(#256 — 호출자 탭 Root 로컬
    ///     `@State`의 Binding). true면 복귀 `onAppear`가 소비(false로 되돌림)하고 두 목록(내 피드/소소피드)을
    ///     초기 로드처럼 다시 받는다(새 글이 맨 위, 스크롤 최상단). 새 글은 이 신호로만 목록에 들어온다 —
    ///     수정 완료(셀 동기화가 처리)·작품 상세 경유 작성(그 화면이 자기 피드 섹션을 리셋)엔 켜지 말 것.
    ///   - scrollToTopSignal: 피드 탭바의 **현재(피드) 탭 재탭** 신호(증가하는 카운터). 값이 바뀌면 지금 보이는
    ///     서브탭(내 피드/소소피드)만 목록 최상단으로 스크롤한다 — 시스템 자동 동작이 상시 mount된 두 ScrollView
    ///     중 첫 번째(내 피드)에만 걸려 소소피드에선 안 먹는 문제를 우회한다(호출자 `MainTabView`가 커스텀
    ///     selection Binding으로 재탭을 감지해 올린다).
    ///   - onRoute: 화면 전환 의도 콜백 — 목적지·payload는 `SosoFeedRoute`(Navigation/) 참고.
    ///     실제 화면 조립·push는 호출자(App 조정 계층)가 exhaustive switch로 수행한다(#253).
    @MainActor
    public static func makeSosoFeedView(
        loadMyFeedsUseCase: LoadMyFeedsUseCase,
        loadSosoFeedsUseCase: LoadSosoFeedsUseCase,
        loadFeedDetailUseCase: LoadFeedDetailUseCase,
        feedLikeUseCase: FeedLikeUseCase,
        loadProfileUseCase: LoadProfileUseCase,
        deleteFeedUseCase: DeleteFeedUseCase,
        reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase,
        reportImproperFeedUseCase: ReportImproperFeedUseCase,
        logger: Logger? = nil,
        analyticsTracker: AnalyticsTracker? = nil,
        needsReloadForCreatedFeed: Binding<Bool> = .constant(false),
        scrollToTopSignal: Int = 0,
        onRoute: @escaping (SosoFeedRoute) -> Void
    ) -> some View {
        SosoFeedView(
            viewModel: SosoFeedViewModel(
                loadMyFeedsUseCase: loadMyFeedsUseCase,
                loadsosoFeedsUseCase: loadSosoFeedsUseCase,
                loadFeedDetailUseCase: loadFeedDetailUseCase,
                feedLikeUseCase: feedLikeUseCase,
                loadProfileUseCase: loadProfileUseCase,
                deleteFeedUseCase: deleteFeedUseCase,
                reportSpoilerFeedUseCase: reportSpoilerFeedUseCase,
                reportImproperFeedUseCase: reportImproperFeedUseCase,
                logger: logger,
                analyticsTracker: analyticsTracker
            ),
            needsReloadForCreatedFeed: needsReloadForCreatedFeed,
            scrollToTopSignal: scrollToTopSignal,
            onRoute: onRoute
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

/// 검증용 Stub — 프리뷰에선 리뷰 프롬프트를 띄우지 않는다.
private struct StubAppReviewRequestUseCase: AppReviewRequestUseCase {
    func recordEngagement() {}
    func shouldRequestReview() -> Bool { false }
    func markReviewRequested() {}
}

private struct StubSearchNovelUseCase: SearchNovelUseCase {
    func searchByText(
        _ query: String,
        page: Int,
        recordRecentSearch: Bool
    ) async throws(BaseDomain.RepositoryError) -> (Paginated<Novel>, Int) {
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
