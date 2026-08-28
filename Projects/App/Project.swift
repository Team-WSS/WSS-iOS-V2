import ProjectDescription

import ConfigurationPlugin
import DependencyPlugin
import EnvironmentPlugin

//MARK: - Configurations

let configurations: [Configuration] = [
    .debug(name: .debug,
           xcconfig: .relativeToXCConfig(type: .dev, name: env.targetName)),
    .release(name: .release,
           xcconfig: .relativeToXCConfig(type: .prod, name: env.targetName))
]

//MARK: - Settings

let settings: Settings =
    .settings(
        base: env.baseSetting,
        configurations: configurations
    )

// MARK: - Targets

let targets: [Target] = [
    .target(
        name: env.targetName,
        destinations: .iOS,
        product: .app,
        productName: env.appName,
        bundleId: "\(env.organizationName).\(env.targetName)",
        infoPlist: .file(path: "Support/Info.plist"),
        sources: ["Sources/**"],
        // Apple 로그인(SignInWithAppleButton) capability. 없으면 인증 시도 시 실패한다.
        entitlements: .file(path: "Support/WSS-iOS.entitlements"),
        // KakaoSDK.initSDK(appKey:) 앱 진입점 초기화 + AuthController.handleOpenUrl용.
        dependencies: [
            .external(name: "KakaoSDKCommon"),
            .external(name: "KakaoSDKAuth"),
            // 온보딩 플로우 조립(App이 유일한 DI 지점) — Feature + Domain(UseCase 타입) + Data(Factory 구현체) + Core.
            .module(.feature(.onboarding)),
            .module(.domain(.base)),
            .module(.domain(.auth)),
            .module(.domain(.setting)),
            .module(.domain(.profile)),
            .module(.data(.base)),
            .module(.data(.auth)),
            .module(.data(.setting)),
            .module(.data(.profile)),
            .module(.core(.networking)),
            .module(.core(.logger)),
            .module(.ui(.designSystem)),
            // 온보딩 완료 후 진입하는 메인 탭(홈/피드/서재/My) 조립.
            .module(.feature(.home)),
            .module(.feature(.feed)),
            .module(.feature(.library)),
            .module(.feature(.userPage)),
            .module(.domain(.recommendation)),
            .module(.feature(.notification)),
            .module(.domain(.notification)),
            .module(.domain(.feed)),
            .module(.domain(.social)),
            .module(.domain(.novel)),
            .module(.data(.recommendation)),
            .module(.data(.notification)),
            .module(.data(.feed)),
            .module(.data(.social)),
            .module(.data(.novel)),
            // 홈에서 작품 카드 탭 → 작품 상세 진입.
            .module(.feature(.novelDetail)),
            // 작품 상세의 평가 상태바 탭 → 작품 평가 진입.
            .module(.feature(.novelReview)),
            .module(.domain(.novelReview)),
            .module(.data(.novelReview)),
            // 홈에서 추천글 탭 → 피드 상세, 서치바 탭 → 일반 검색 진입.
            .module(.feature(.search)),
            .module(.domain(.search)),
            .module(.domain(.comment)),
            .module(.data(.search)),
            .module(.data(.comment)),
            // 홈의 상세탐색 배너 → 필터 화면의 "키워드" 탭 콘텐츠 주입(SearchFeature는 KeywordFeature를
            // 모른다 — KeywordTabContentBuilder로 App이 조립해 값으로 건네준다).
            .module(.feature(.keyword)),
            // 서재에서 알림 관리 → 설정의 알림 설정 화면 진입.
            .module(.feature(.setting)),
            // 설정 화면의 푸시 권한 상태 확인.
            .module(.core(.pushAuthorization)),
            // 마이페이지/유저페이지 컬렉션 섹션 미리보기 + 마이페이지의 컬렉션 목록/생성/수정/상세
            // 화면 전환(#201, MypageRootView가 조립).
            .module(.domain(.collection)),
            .module(.data(.collection)),
            .module(.feature(.collection))
        ],
        settings: .settings(
            base: env.baseSetting,
            configurations: configurations),
    ),
    .target(
        name: env.targetTestName,
        destinations: .iOS,
        product: .unitTests,
        bundleId: "\(env.organizationName).\(env.targetName)Tests",
        infoPlist: .file(path: "Support/Info.plist"),
        sources: ["Tests/**"],
        resources: [],
        dependencies: [.target(name: env.targetName)]
    ),
]

//MARK: - Schemes

let schemes: [Scheme] = [
    .scheme(
        name: "\(env.targetName)-DEBUG",
        shared: true,
        buildAction: .buildAction(targets: ["\(env.targetName)"]),
        testAction: TestAction.targets(
            ["\(env.targetTestName)"],
            configuration: .debug,
            options: TestActionOptions.options(
                coverage: true,
                codeCoverageTargets: ["\(env.targetName)"]
            )
        ),
        runAction: .runAction(configuration: .debug),
        archiveAction: .archiveAction(configuration: .debug),
        profileAction: .profileAction(configuration: .debug),
        analyzeAction: .analyzeAction(configuration: .debug)
    ),
    .scheme(
        name: "\(env.targetName)-RELEASE",
        shared: true,
        buildAction: .buildAction(targets: ["\(env.targetName)"]),
        testAction: nil,
        runAction: .runAction(configuration: .release),
        archiveAction: .archiveAction(configuration: .release),
        profileAction: .profileAction(configuration: .release),
        analyzeAction: .analyzeAction(configuration: .release)
    )
]

//MARK: - Project

let project = Project(
    name: env.targetName,
    settings: settings,
    targets: targets,
    schemes: schemes,
    additionalFiles: [
        "../../Config/Config_Shared.xcconfig"
    ]
)
