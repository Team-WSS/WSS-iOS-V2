// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        // Customize the product types for specific package product
        // Default is .staticFramework
        // productTypes: ["Alamofire": .framework,]
        //
        // KakaoSDK*는 dynamic framework로 강제한다 — static이면 OnboardingFeature.framework와
        // OnboardingFeatureDemo(및 향후 App)가 각자 별도 정적 사본을 갖게 되어, 한쪽에서 호출한
        // KakaoSDK.initSDK(appKey:)가 다른 쪽 사본엔 반영되지 않는다(objc 클래스 중복 경고 +
        // "initSDK(appKey:) must be initialized" 런타임 크래시로 실측). Alamofire는 KakaoSDK의
        // 전이 의존성이라 함께 dynamic으로 맞춰야 완전히 해소된다.
        // Share/Template(컬렉션 카카오톡 공유 카드, #228)도 같은 이유로 dynamic — CollectionFeature.framework가
        // 호출하고 App/Demo가 초기화한다.
        // Firebase(FCM, #243)는 별도 지정 없이 기본값 .staticFramework로 둔다 — Firebase 공식 권장이
        // 정적 링크이고, FirebaseMessaging만 쓰면 무거운 GoogleAppMeasurement(.xcframework) 계열을
        // 안 끌어와 static으로 문제없이 링크된다(Kakao처럼 dynamic 싱글턴 공유 이슈도 없음).
        productTypes: [
            "KakaoSDKCommon": .framework,
            "KakaoSDKAuth": .framework,
            "KakaoSDKUser": .framework,
            "KakaoSDKShare": .framework,
            "KakaoSDKTemplate": .framework,
            "Alamofire": .framework
        ],
        // 외부 패키지 deployment target을 앱과 동일한 17.0으로 강제 오버라이드한다 — 패키지들이
        // 매니페스트의 최소 타깃(13.1 등)을 그대로 쓰면 Xcode 26.6+(지원 하한 iOS 15.0)에서
        // 전 패키지 타깃이 "supported deployment target versions" 하드 에러로 빌드가 깨진다.
        baseSettings: .settings(
            base: ["IPHONEOS_DEPLOYMENT_TARGET": "17.0"]
        )
        // ⚠️ 위 baseSettings로도 SPM 리소스 번들(PrivacyInfo 등) 합성 타깃 15개엔 13.1이 남는다 —
        // Tuist가 번들 타깃엔 패키지 매니페스트의 최소 타깃을 모델 레벨로 직접 복사해서
        // PackageSettings(baseSettings/targetSettings)로 못 덮는다(tuist/tuist#11163, 실측 확인).
        // CLI xcodebuild는 통과하지만 Xcode IDE 빌드는 하드 에러 → tuist generate 후
        // Scripts/patch-spm-deployment-target.sh 실행으로 해결한다.
    )
#endif

let package = Package(
    name: "WSS-iOS-V2",
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-spm.git", exact: "4.5.1"),
        .package(url: "https://github.com/kakao/kakao-ios-sdk.git", exact: "2.28.0"),
        // FCM 푸시 알림(#243). FirebaseMessaging 프로덕트만 App 타깃에서 .external로 링크한다
        // (Analytics 등은 제외 — 최소 의존). 버전은 V1(운영)과 동일하게 고정.
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", exact: "11.7.0"),
        // Amplitude·Microsoft Clarity 애널리틱스(#249) — App 레이어에만 격리해서 링크한다
        // (Core/Analytics는 AnalyticsTracker 프로토콜만 노출, 이 SDK들을 모른다). Release 스킴에서만
        // 실제로 초기화한다(Debug는 이벤트를 안 쏨, `AppDependencies` 참고).
        .package(url: "https://github.com/amplitude/Amplitude-Swift.git", exact: "1.18.8"),
        .package(url: "https://github.com/microsoft/clarity-apps.git", exact: "4.0.0")
    ]
)
