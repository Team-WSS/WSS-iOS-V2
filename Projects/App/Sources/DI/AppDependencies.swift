//
//  AppDependencies.swift
//  WSS-iOS
//
//  Created by Guryss on 8/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain
import AuthDomain
import CollectionDomain
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
import SplashDomain
import BaseData
import AuthData
import CollectionData
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
import SplashData
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
    let novelNotificationRepository: NovelNotificationRepository
    let collectionRepository: any CollectionRepository
    let feedRepository: FeedRepository
    let socialRepository: SocialRepository
    let novelRepository: NovelRepository
    /// 내 서재 필터·정렬 로컬 영속화(#221) — 서버 조회(`novelRepository`)와 별개 계약이라 따로 조립한다.
    let myLibraryFilterRepository: MyLibraryFilterRepository
    let keywordRepository: KeywordRepository
    let novelReviewRepository: NovelReviewRepository
    let commentRepository: CommentRepository
    let searchRepository: any RecentSearchRepository & SearchAutoCompletionRepository & SearchNovelRepository
    let pushSettingRepository: PushSettingRepository
    /// 1회성 온보딩 힌트 플래그(#221) — 순수 로컬(UserDefaults)이라 네트워크 client 없이 조립한다.
    let onboardingHintRepository: OnboardingHintRepository
    /// 앱스토어 평점 요청 게이팅(#221, 피드·감상평 공유) — 순수 로컬(UserDefaults + Bundle 버전).
    let appReviewRequestRepository: AppReviewRequestRepository
    /// 런치 부트스트랩 게이트(강제 업데이트→세션→약관) 판정 — `ContentView`의 스플래시가
    /// `DefaultBootstrapAppUseCase`로 감싸 호출한다(#236, #225 배선).
    let launchGateRepository: LaunchGateRepository
    /// 런치 부수 태스크 4종(users/me·FCM·키워드·홈 프리페치) — 위와 같은 UseCase로 묶인다.
    let launchTaskRepository: LaunchTaskRepository
    /// 피드 작성 완료 → 피드 탭 목록 재로드 신호(앱 전역). Repository가 아니라 App 조정 계층 소유의
    /// 화면 간 상태라 여기 두되, 4탭 Root가 공유해야 해서 `AppDependencies`에 실어 나른다.
    let feedListInvalidation = FeedListInvalidation()

    init() {
        let logger = ConsoleLogger()
        self.logger = logger

        let tokenStore = DefaultTokenStore()

        // 재발급(/reissue) 전용 URLSession엔 요청 타임아웃 10초를 건다(기본 60초). 재발급 대기
        // (`SessionRefreshCoordinator`의 `await task.value`)는 취소에 반응하지 않아, 만료 토큰 + 느린 망이면
        // 스플래시 게이트 예산(4초)을 넘겨도 빠져나오지 못하고 URLSession 타임아웃까지 잠긴다
        // (#225 리뷰, `SplashDomain/CLAUDE.md`). 작은 JSON POST 하나라 10초면 충분하고, 타임아웃으로
        // 실패하면 coordinator가 "통신 실패 = 토큰 보존·원 에러 전파"로 처리해 세션이 끊기지 않는다.
        let refresherSessionConfiguration = URLSessionConfiguration.default
        refresherSessionConfiguration.timeoutIntervalForRequest = 10
        let refresherClient = NetworkingClient(
            urlSession: URLSession(configuration: refresherSessionConfiguration),
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
            appStorage: UserDefaultsStorage(),
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
        // 홈 프리페치 store는 반드시 **소비하는 쪽(이 recommendationRepository)에만** 주입한다.
        // 프리페치를 실행하는 쪽(launchTaskRepository)에 같은 인스턴스를 주면 프리페치의
        // fetch가 빈 슬롯을 consume해 소비 창을 닫고 fill이 폐기된다 — store가 영영 안 채워지고
        // 런치마다 추천 API 3개만 버려진다(#225 리뷰, `SplashData/CLAUDE.md`).
        // 반대로 여기만 주고 저쪽 조립을 빼먹으면 프리페치 자체가 안 돈다 — 두 조립은 짝이다(아래
        // launchTaskRepository 참조).
        let prefetchStore = HomePrefetchStore()
        self.recommendationRepository = RecommendationDataFactory.makeRepository(
            network: client,
            logger: DataLogger(moduleName: "RecommendationData", underlying: logger),
            prefetchStore: prefetchStore
        )
        self.notificationRepository = NotificationDataFactory.makeNotificationRepository(
            client: client,
            logger: DataLogger(moduleName: "NotificationData", underlying: logger)
        )
        self.novelNotificationRepository = NotificationDataFactory.makeNovelNotificationRepository(
            client: client,
            logger: DataLogger(moduleName: "NotificationData", underlying: logger)
        )
        self.collectionRepository = CollectionDataFactory.makeRepository(
            network: client,
            logger: DataLogger(moduleName: "CollectionData", underlying: logger)
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
        self.myLibraryFilterRepository = NovelDataFactory.makeMyLibraryFilterRepository(
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
        self.onboardingHintRepository = DefaultOnboardingHintRepository(appStorage: UserDefaultsStorage())
        self.appReviewRequestRepository = DefaultAppReviewRequestRepository(appStorage: UserDefaultsStorage())

        // 푸시(#243): FCM 런타임 허브(App 레이어의 PushNotificationCenter)에 "토큰 서버 등록" 훅과
        // "로그인 여부"를 주입한다. Firebase 자체는 App(PushNotificationCenter/AppDelegate)에만 있고,
        // 여기선 Domain UseCase(RegisterDeviceTokenUseCase)와 세션 판정만 넘긴다. 세션이 끝나 이
        // AppDependencies가 재조립되면 새 UseCase/tokenStore로 다시 주입된다.
        let registerDeviceTokenUseCase = DefaultRegisterDeviceTokenUseCase(repository: pushSettingRepository)
        PushNotificationCenter.shared.configure(
            registerDeviceToken: { devicePushToken in
                try? await registerDeviceTokenUseCase.execute(devicePushToken: devicePushToken)
            },
            isLoggedIn: { (try? tokenStore.accessToken()) != nil }
        )

        // 런치 부트스트랩(#225 모듈, #236 배선) — 기존 저장소·정책에 위임하는 composite 조립.
        // appUpdateRepository는 이 게이트만 쓰므로 프로퍼티로 열지 않는다(다른 소비자가 생기면 승격).
        self.launchGateRepository = SplashDataFactory.makeLaunchGateRepository(
            tokenStore: tokenStore,
            appUpdateRepository: SettingDataFactory.makeAppUpdateRepository(
                client: client,
                logger: DataLogger(moduleName: "SettingData", underlying: logger)
            ),
            versionProvider: SettingDataFactory.makeAppVersionProvider(),
            termsAgreementRepository: termsAgreementRepository
        )
        // 프리페치를 실행하는 쪽 추천 레포는 store를 주입하지 않은 **별도 인스턴스**여야 한다
        // (위 prefetchStore 주석의 짝 — 같은 인스턴스를 넘기면 프리페치가 스스로를 무효화한다).
        // deviceTokenProvider는 App 레이어 FCM 허브에서 현재 토큰을 당겨온다(#243) — 권한 허용 상태에서만
        // 토큰을 만들어 주고, 미허용/실패면 nil을 돌려 부트스트랩이 등록을 조용히 건너뛴다(세션 있을 때만 호출됨).
        self.launchTaskRepository = SplashDataFactory.makeLaunchTaskRepository(
            profileRepository: profileRepository,
            pushSettingRepository: pushSettingRepository,
            deviceTokenProvider: { await PushNotificationCenter.shared.currentDevicePushToken() },
            keywordRepository: keywordRepository,
            recommendationRepository: RecommendationDataFactory.makeRepository(
                network: client,
                logger: DataLogger(moduleName: "RecommendationData", underlying: logger)
            ),
            prefetchStore: prefetchStore
        )

        // 키워드는 로컬 파일 캐시(`KeywordCache`)를 여러 도메인(서재 필터·프로필 취향·검색 등)이
        // 그대로 읽어 쓰는 구조라(BaseData/CLAUDE.md), 캐시가 비어있으면 그 화면들이 전부 빈 목록으로
        // 보인다 — 앱이 뜰 때(= AppDependencies가 조립되는 시점, 프로세스당 1회) 한 번 서버와 동기화해
        // 채워둔다. `syncKeywords()`는 내부에서 실패를 전부 삼키고 로깅만 하는 계약이라(throws 없음)
        // 여기서도 결과를 기다리거나 실패를 처리하지 않는다 — 화면 진입을 막지 않는 fire-and-forget.
        // 세션이 있는 런치에선 부트스트랩 부수 태스크(launchTaskRepository.syncKeywords)와 겹쳐 2회
        // 동기화되지만 허용한다(#236) — 부트스트랩은 세션 없으면 태스크를 안 돌리므로, 이 호출을 빼면
        // "비로그인 런치 → 로그인" 경로에서 키워드 캐시가 다음 런치까지 빈 채로 남는다.
        Task { await keywordRepository.syncKeywords() }
    }
}
