//
//  AppDependencies.swift
//  WSS-iOS
//
//  Created by Guryss on 8/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain
import AuthDomain
import CommentDomain
import FeedDomain
import NotificationDomain
import NovelDomain
import NovelReviewDomain
import ProfileDomain
import RecommendationDomain
import SearchDomain
import SettingDomain
import SocialDomain
import BaseData
import AuthData
import CommentData
import FeedData
import NotificationData
import NovelData
import NovelReviewData
import ProfileData
import RecommendationData
import SearchData
import SettingData
import SocialData
import Logger
import Networking

/// App(DI)의 유일한 조립 지점 — Data 구현체와 Domain 프로토콜이 만나는 곳.
/// 온보딩 플로우 + 로그인 이후 진입하는 메인 탭(홈/피드/서재/My)이 필요로 하는 Repository까지 조립한다.
///
/// **NetworkingClient가 2개인 이유(무한 재귀 방지)**: `refresherClient`는 토큰 갱신 자체를 요청하는
/// 전용 client라 `authSessionRefresher`를 물리지 않는다 — 물리면 "갱신 요청 401 → 갱신 시도 → 그 요청도
/// 401 → ..."로 재귀한다(`AuthData/CLAUDE.md` 경고). 실제 API 호출은 전부 `client`(갱신 훅 연결됨)로 나간다.
/// 두 client는 같은 `tokenStore`(Keychain 기반)를 공유해 갱신된 토큰이 즉시 반영된다.
@MainActor
final class AppDependencies {

    let logger: Logger
    let authRepository: AuthRepository
    let termsAgreementRepository: TermsAgreementRepository
    let profileRepository: ProfileRepository
    let recommendationRepository: RecommendationRepository
    let notificationRepository: NotificationRepository
    let feedRepository: FeedRepository
    let socialRepository: SocialRepository
    let novelRepository: NovelRepository
    let keywordRepository: KeywordRepository
    let novelReviewRepository: NovelReviewRepository
    let commentRepository: CommentRepository
    let searchRepository: any RecentSearchRepository & SearchAutoCompletionRepository & SearchNovelRepository
    let pushSettingRepository: PushSettingRepository

    init() {
        let logger = ConsoleLogger()
        self.logger = logger

        let tokenStore = DefaultTokenStore()

        let refresherClient = NetworkingClient(
            logger: DefaultNetworkLogger(base: logger),
            tokenStore: tokenStore
        )
        let sessionRefresher = AuthDataFactory.makeSessionRefresher(
            client: refresherClient,
            tokenStore: tokenStore,
            logger: DataLogger(moduleName: "AuthData", underlying: logger)
        )

        let client = NetworkingClient(
            logger: DefaultNetworkLogger(base: logger),
            tokenStore: tokenStore,
            authSessionRefresher: sessionRefresher
        )

        self.authRepository = AuthDataFactory.makeRepository(
            client: client,
            tokenStore: tokenStore,
            deviceIdentifierStore: DefaultDeviceIdentifierStore(),
            logger: DataLogger(moduleName: "AuthData", underlying: logger)
        )
        self.termsAgreementRepository = SettingDataFactory.makeTermsAgreementRepository(
            client: client,
            logger: DataLogger(moduleName: "SettingData", underlying: logger)
        )
        self.profileRepository = ProfileDataFactory.makeProfileRepository(
            client: client,
            localStorage: UserDefaultsStorage(),
            logger: DataLogger(moduleName: "ProfileData", underlying: logger)
        )
        self.recommendationRepository = RecommendationDataFactory.makeRepository(
            network: client,
            logger: DataLogger(moduleName: "RecommendationData", underlying: logger)
        )
        self.notificationRepository = NotificationDataFactory.makeNotificationRepository(
            client: client,
            logger: DataLogger(moduleName: "NotificationData", underlying: logger)
        )
        self.feedRepository = FeedDataFactory.makeFeedRepository(
            client: client,
            logger: DataLogger(moduleName: "FeedData", underlying: logger)
        )
        self.socialRepository = SocialDataFactory.makeSocialRepository(
            client: client,
            logger: DataLogger(moduleName: "SocialData", underlying: logger)
        )
        self.novelRepository = NovelDataFactory.makeNovelRepository(
            client: client,
            appStorage: UserDefaultsStorage(),
            logger: DataLogger(moduleName: "NovelData", underlying: logger)
        )
        self.keywordRepository = KeywordDataFactory.makeRepository(
            client: client,
            logger: DataLogger(moduleName: "BaseData", underlying: logger)
        )
        self.novelReviewRepository = NovelReviewDataFactory.makeRepository(
            client: client,
            logger: DataLogger(moduleName: "NovelReviewData", underlying: logger)
        )
        self.commentRepository = CommentDataFactory.makeCommentRepository(
            client: client,
            logger: DataLogger(moduleName: "CommentData", underlying: logger)
        )
        self.searchRepository = SearchDataFactory.makeRepository(
            network: client,
            logger: DataLogger(moduleName: "SearchData", underlying: logger)
        )
        self.pushSettingRepository = NotificationDataFactory.makePushSettingRepository(
            client: client,
            logger: DataLogger(moduleName: "NotificationData", underlying: logger)
        )

        // 키워드는 로컬 파일 캐시(`KeywordCache`)를 여러 도메인(서재 필터·프로필 취향·검색 등)이
        // 그대로 읽어 쓰는 구조라(BaseData/CLAUDE.md), 캐시가 비어있으면 그 화면들이 전부 빈 목록으로
        // 보인다 — 앱이 뜰 때(= AppDependencies가 조립되는 시점, 프로세스당 1회) 한 번 서버와 동기화해
        // 채워둔다. `syncKeywords()`는 내부에서 실패를 전부 삼키고 로깅만 하는 계약이라(throws 없음)
        // 여기서도 결과를 기다리거나 실패를 처리하지 않는다 — 화면 진입을 막지 않는 fire-and-forget.
        Task { await keywordRepository.syncKeywords() }
    }
}
