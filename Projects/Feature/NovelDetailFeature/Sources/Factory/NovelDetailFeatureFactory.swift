//
//  NovelDetailFeatureFactory.swift
//  NovelDetailFeature
//
//  Created by YunhakLee on 7/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import FeedDomain
import NotificationDomain
import NovelDomain
import NovelReviewDomain
import SocialDomain
import Logger
import PushAuthorization
import Analytics

/// 소설 상세 화면의 유일한 public 진입점. opaque 반환 → View/VM은 internal 유지.
public enum NovelDetailFeatureFactory {

    /// - Parameters:
    ///   - loadFeedDetailUseCase: 재진입 시 **다녀온 셀만** 상세 API로 다시 맞추는 데 쓴다(#256 — 이 화면은
    ///     재진입에 피드 목록을 다시 받지 않는다). 구현 클래스명은 `DefaultLoadFeedUseCase`.
    ///   - needsFeedReloadForCreatedFeed: 이 화면발 피드 작성(`.createFeed` 라우트) 성공 복귀 신호(#256 —
    ///     호출자 탭 Root 로컬 `@State`의 Binding). true면 복귀 `onAppear`가 소비(false로 되돌림)하고 피드
    ///     섹션을 초기 로드처럼 리셋한다(새 글이 맨 위). 수정 완료엔 켜지 말 것(셀 동기화가 처리).
    ///   - onRoute: 화면 전환 의도 콜백 — 목적지·payload는 `NovelDetailRoute`(Navigation/) 참고.
    ///     실제 화면 조립·push는 호출자(App 조정 계층)가 exhaustive switch로 수행한다(#253).
    ///   - onAuthenticationRequired: 인증 만료(세션 죽음) 시 로그인 화면 진입 콜백 — 화면 내 모든 서버 호출 공통.
    ///     화면 전환 "의도"가 아니라 세션 이벤트라 `onRoute`에 합치지 않는다.
    ///   - pushAuthorizationChecker: 종 아이콘 탭 시 시스템 푸시 권한을 확인한다(`SettingFeature`의
    ///     "알림 설정" 메뉴와 동일 목적) — denied면 시트를 열지 않고 기기 설정 유도 알럿만 띄운다.
    @MainActor
    public static func makeView(
        novelID: NovelID,
        loadNovelUseCase: LoadNovelUseCase,
        novelInterestUseCase: NovelInterestUseCase,
        loadNovelFeedsUseCase: LoadNovelFeedsUseCase,
        loadFeedDetailUseCase: LoadFeedDetailUseCase,
        feedLikeUseCase: FeedLikeUseCase,
        deleteFeedUseCase: DeleteFeedUseCase,
        deleteNovelReviewUseCase: DeleteNovelReviewUseCase,
        reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase,
        reportImproperFeedUseCase: ReportImproperFeedUseCase,
        loadNotificationSettingUseCase: LoadNovelNotificationSettingUseCase,
        updateNotificationSettingUseCase: UpdateNovelNotificationSettingUseCase,
        onboardingHintUseCase: OnboardingHintUseCase,
        pushAuthorizationChecker: PushAuthorizationChecker,
        logger: Logger? = nil,
        analyticsTracker: AnalyticsTracker? = nil,
        needsFeedReloadForCreatedFeed: Binding<Bool> = .constant(false),
        onRoute: @escaping (NovelDetailRoute) -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        NovelDetailView(
            novelID: novelID,
            viewModel: NovelDetailViewModel(
                novelID: novelID,
                loadNovelUseCase: loadNovelUseCase,
                novelInterestUseCase: novelInterestUseCase,
                loadNovelFeedsUseCase: loadNovelFeedsUseCase,
                loadFeedDetailUseCase: loadFeedDetailUseCase,
                feedLikeUseCase: feedLikeUseCase,
                deleteFeedUseCase: deleteFeedUseCase,
                deleteNovelReviewUseCase: deleteNovelReviewUseCase,
                reportSpoilerFeedUseCase: reportSpoilerFeedUseCase,
                reportImproperFeedUseCase: reportImproperFeedUseCase,
                onboardingHintUseCase: onboardingHintUseCase,
                pushAuthorizationChecker: pushAuthorizationChecker,
                logger: logger,
                analyticsTracker: analyticsTracker
            ),
            loadNotificationSettingUseCase: loadNotificationSettingUseCase,
            updateNotificationSettingUseCase: updateNotificationSettingUseCase,
            logger: logger,
            analyticsTracker: analyticsTracker,
            needsFeedReloadForCreatedFeed: needsFeedReloadForCreatedFeed,
            onRoute: onRoute,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}
