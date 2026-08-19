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
        productTypes: [
            "KakaoSDKCommon": .framework,
            "KakaoSDKAuth": .framework,
            "KakaoSDKUser": .framework,
            "Alamofire": .framework
        ]
    )
#endif

let package = Package(
    name: "WSS-iOS-V2",
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-spm.git", exact: "4.5.1"),
        .package(url: "https://github.com/kakao/kakao-ios-sdk.git", exact: "2.28.0")
    ]
)
