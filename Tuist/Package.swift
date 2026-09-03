// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

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
        ]
    )
#endif

let package = Package(
    name: "WSS-iOS-V2",
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-spm.git", exact: "4.5.1"),
        .package(url: "https://github.com/kakao/kakao-ios-sdk.git", exact: "2.28.0"),
        // FCM 푸시 알림(#243). FirebaseMessaging 프로덕트만 App 타깃에서 .external로 링크한다
        // (Analytics 등은 제외 — 최소 의존). 버전은 V1(운영)과 동일하게 고정.
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", exact: "11.7.0")
    ]
)
