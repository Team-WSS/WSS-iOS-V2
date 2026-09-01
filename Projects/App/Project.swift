import ProjectDescription

import ConfigurationPlugin
import DependencyPlugin
import EnvironmentPlugin

//MARK: - Configurations

// ⚠️ App 타깃 전용 서명·아이콘 설정이다 — Project 레벨 settings(아래)엔 절대 쓰지 않는다. Project
// 레벨에 두면 WSS-iOSTests 등 다른 타깃이 자기 bundle id와 안 맞는 PROVISIONING_PROFILE_SPECIFIER
// ("match AppStore <App bundle id>")를 그대로 상속해버린다(2026-08-29 wss-pr-reviewer가 생성된
// pbxproj로 실측 — WSS-iOSTests가 이 값을 상속하고 있었다). App 타깃의 settings(아래)에만 물릴 것.
let appSigningConfigurations: [Configuration] = [
    .debug(name: .debug,
           settings: [
               "PRODUCT_BUNDLE_IDENTIFIER": .string(env.debugBundleId),
               "CODE_SIGN_STYLE": "Manual",
               "CODE_SIGN_IDENTITY": "Apple Development",
               "CODE_SIGN_IDENTITY[sdk=iphoneos*]": "iPhone Distribution",
               "DEVELOPMENT_TEAM": "",
               "DEVELOPMENT_TEAM[sdk=iphoneos*]": .string(env.appleDeveloperTeamID),
               "PROVISIONING_PROFILE_SPECIFIER": "",
               "PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]": .string("match AppStore \(env.debugBundleId)"),
               // Debug 빌드는 홈 화면에서 운영 앱과 구분되도록 별도 아이콘 세트를 쓴다
               // (Resources/Assets.xcassets/AppIcon-Debug.appiconset, 사용자가 실제 이미지 교체 예정).
               "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon-Debug",
               // 홈 화면 표시 이름(Info.plist의 CFBundleDisplayName이 참조) — 운영 앱과 구분되도록 별도
               // 문구. PRODUCT_NAME(내부 CFBundleName·실행파일명)은 그대로 두고 이 키만 Debug/Release로 나눈다.
               "APP_DISPLAY_NAME": "웹소소 개발용",
           ],
           xcconfig: .relativeToXCConfig(type: .dev, name: env.targetName)),
    .release(name: .release,
           settings: [
               "PRODUCT_BUNDLE_IDENTIFIER": .string(env.releaseBundleId),
               "CODE_SIGN_STYLE": "Manual",
               "CODE_SIGN_IDENTITY": "Apple Development",
               "CODE_SIGN_IDENTITY[sdk=iphoneos*]": "iPhone Distribution",
               "DEVELOPMENT_TEAM": "",
               "DEVELOPMENT_TEAM[sdk=iphoneos*]": .string(env.appleDeveloperTeamID),
               "PROVISIONING_PROFILE_SPECIFIER": "",
               "PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]": .string("match AppStore \(env.releaseBundleId)"),
               // 운영 아이콘(V1과 동일, Resources/Assets.xcassets/AppIcon.appiconset).
               "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
               // 홈 화면 표시 이름(Info.plist의 CFBundleDisplayName이 참조) — 운영 앱 정식 이름.
               "APP_DISPLAY_NAME": "웹소소",
           ],
           xcconfig: .relativeToXCConfig(type: .prod, name: env.targetName))
]

// Project 레벨엔 이름·xcconfig만 있는 "빈" configuration을 둔다 — 코드사이닝·아이콘 키는 위
// appSigningConfigurations에만 있고 여기 없으므로, App 외 타깃(WSS-iOSTests)은 이 값들을 상속하지
// 않고 Xcode 기본(Automatic 서명 등)으로 남는다.
let projectConfigurations: [Configuration] = [
    .debug(name: .debug, xcconfig: .relativeToXCConfig(type: .dev, name: env.targetName)),
    .release(name: .release, xcconfig: .relativeToXCConfig(type: .prod, name: env.targetName))
]

//MARK: - Settings

let settings: Settings =
    .settings(
        base: env.baseSetting,
        configurations: projectConfigurations
    )

// App 타깃 전용 버전 정보(Apple Generic Versioning) — env.baseSetting은 전 모듈이 공유해서 여기 안
// 넣고 App 타깃 settings에만 병합한다. fastlane의 increment_build_number(agvtool 기반, Fastfile의
// increment_build_number_with_date)가 이 설정 없이는 "Apple Generic Versioning is not enabled"로
// 실패한다(2026-08-29 archive-debug 스킬 첫 실행에서 실측). MARKETING_VERSION은 Debug 앱 식별자의
// 기존 TestFlight 최신 버전에 맞춘 초기값 — 이후 정식 버전업 시 갱신할 것.
// TARGETED_DEVICE_FAMILY(iPhone 전용)는 V1과 동일 — App Store Connect 업로드 검증이 iPad용 아이콘·
// 방향 키를 요구하는 걸 피한다(2026-08-29 실측, V1 project.pbxproj 대조로 확인: TARGETED_DEVICE_FAMILY = 1).
let appBaseSettings: SettingsDictionary = env.baseSetting.merging([
    "MARKETING_VERSION": "1.9.4",
    "CURRENT_PROJECT_VERSION": "1",
    "VERSIONING_SYSTEM": "apple-generic",
    "TARGETED_DEVICE_FAMILY": "1",
]) { _, new in new }

// MARK: - Targets

let targets: [Target] = [
    .target(
        name: env.targetName,
        destinations: .iOS,
        product: .app,
        productName: env.appName,
        bundleId: env.releaseBundleId,
        infoPlist: .file(path: "Support/Info.plist"),
        sources: ["Sources/**"],
        // ⚠️ 이게 빠져있어 Resources/Assets.xcassets(앱 아이콘 포함)가 빌드에 전혀 안 들어가고
        // 있었다 — 시뮬레이터 빌드는 아이콘이 없어도 통과해 안 드러났고, App Store Connect 업로드
        // 검증에서야 "Missing required icon file"로 처음 발각됐다(2026-08-29 archive-debug 스킬 실측).
        resources: ["Resources/**"],
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
            .module(.feature(.collection)),
            // 런치 스플래시(부트스트랩 게이트: 강제 업데이트→세션→약관) 조립(#236).
            .module(.feature(.splash)),
            .module(.domain(.splash)),
            .module(.data(.splash))
        ],
        settings: .settings(
            // App 타깃 전용 서명·버전 설정(appSigningConfigurations/appBaseSettings, 위 정의 참고).
            // ⚠️ MARKETING_VERSION(→ Support/Info.plist의 CFBundleShortVersionString)이 비면 카카오
            // SDK가 kakaolink 필수 파라미터 appver를 못 채워 카카오톡 공유가 "Core parameter(s) missing"
            // 으로 거부된다(#228 실기기 실측) — appBaseSettings가 항상 값을 채워두는 이유 중 하나다.
            base: appBaseSettings,
            configurations: appSigningConfigurations),
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
