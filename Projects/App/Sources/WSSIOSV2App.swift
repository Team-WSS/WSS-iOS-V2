import SwiftUI

import KakaoSDKAuth
import KakaoSDKCommon

import BaseDomain
import DesignSystem

@main
struct WSSIOSV2App: App {

    /// 앱 밖에서 들어온 딥링크(`websoso://…`, #228)를 `MainTabView`가 소비할 때까지 들고 있는다 —
    /// 로그아웃 상태(온보딩 루트)로 링크를 열면 로그인이 끝나 메인 탭이 뜨는 순간 이어서 처리된다.
    @State private var pendingDeepLink: DeepLink?

    /// 원격 알림(FCM/APNs, #243)용 UIKit 진입점. 순수 SwiftUI 앱엔 `application(_:didRegister…)` 등
    /// 시스템 콜백을 받을 자리가 없어 어댑터로 `AppDelegate`를 붙인다 — Firebase 배선은 그 안에 있다.
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        // 커스텀 폰트(Pretendard) 등록. 없으면 applyWSSFont의 UIFont(name:)! 가 nil → 크래시.
        DesignSystemFontFamily.registerAllCustomFonts()

        // 탭바 **글씨** 색(선택 wssBlack / 비선택 wssGray200)을 UIKit 어피어런스 프록시로 앱 시작 시
        // 1회 설정한다 — SwiftUI TabView가 비선택 색 공개 API를 안 줘서다. 탭 **아이콘** 색은 여기가
        // 아니라 `MainTabView`가 상태별로 색을 구운 `.alwaysOriginal` 이미지로 직접 그린다(iOS 26 새
        // 탭바가 어피어런스의 비선택 아이콘 채널을 무시해서 — 아래 `configureTabBarAppearance` 주석 참고).
        configureTabBarAppearance()

        // 카카오 로그인(OnboardingFeature) 진입 전에 반드시 앱 시작 시 한 번 초기화돼야 한다.
        guard let kakaoAppKey = Bundle.main.infoDictionary?["KAKAO_APP_KEY"] as? String,
              !kakaoAppKey.isEmpty else {
            assertionFailure("KAKAO_APP_KEY가 Info.plist에 없습니다.")
            return
        }
        KakaoSDK.initSDK(appKey: kakaoAppKey)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(pendingDeepLink: $pendingDeepLink)
                .onOpenURL { url in
                    // 우리 딥링크(`websoso://…`, 카카오톡 공유 카드의 "앱에서 보기"
                    // `kakao{APP_KEY}://kakaolink?collectionId=…`, #228)를 먼저 `DeepLink.init?(url:)`로 풀고,
                    // 아니면 카카오 로그인 콜백(`kakao{APP_KEY}://oauth…`)인지 SDK에 묻는다. 카카오 콜백은 host가
                    // `oauth`라 `DeepLink`가 nil을 돌려주니 순서는 어느 쪽이든 동작하지만, `isKakaoTalkLoginUrl`이
                    // 앱 키 미설정 시 `try!`로 죽는 SDK 경로라 순수 파서를 앞에 둔다. 둘 다 아니면 조용히 무시.
                    if let deepLink = DeepLink(url: url) {
                        pendingDeepLink = deepLink
                        return
                    }
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                }
        }
    }
}

private extension WSSIOSV2App {
    func configureTabBarAppearance() {
        let selectedColor = UIColor(Color.wssBlack)
        let unselectedColor = UIColor(Color.wssGray200)

        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        // 이 어피어런스가 실제로 담당하는 건 **글씨(제목) 색**이다. 아이콘 색은 `MainTabView`가 baked
        // 이미지로 직접 그린다(아래 설명). iconColor도 같이 세팅해두지만, iOS 26에선 baked 이미지에 밀려
        // 무의미하고 iOS 18 이하에서만 아이콘 폴백으로 남는다(둘 다 같은 색이라 충돌 없음).
        //
        // ⚠️ iOS 26 새(Liquid Glass) 탭바 실측(#221): 어피어런스의 **비선택(`normal`) 채널이 통째로
        // 무시**된다 — `normal.iconColor`/`normal.titleTextAttributes`/`unselectedItemTintColor`에 빨강을
        // 넣어도 비선택 탭이 계속 기본 label색(검정)으로 그려졌다(선택 채널만 먹음). 그래서 비선택
        // **아이콘**은 여기서 못 고치고 `MainTabView`가 색을 구운 `.alwaysOriginal` 이미지로 대신 그린다.
        // 비선택 **글씨**는 iOS 26에선 결국 검정으로 남는다(플랫폼 제약 — 여기까지 gray200으로 맞추려면
        // `UIDesignRequiresCompatibility`로 앱 전체를 iOS 18 외형으로 돌리는 수밖에 없어, 그 앱 전역
        // 영향 때문에 채택하지 않았다). iOS 18 이하에선 이 `normal`이 정상 동작해 아이콘·글씨 모두 gray200.
        for itemAppearance in [
            appearance.stackedLayoutAppearance,
            appearance.inlineLayoutAppearance,
            appearance.compactInlineLayoutAppearance
        ] {
            itemAppearance.selected.iconColor = selectedColor
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
            itemAppearance.normal.iconColor = unselectedColor
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: unselectedColor]
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        // 레거시 프로퍼티 이중 보강 — iOS 버전에 따라 어피어런스 객체만으론 색이 덜 먹는 경우가 있어
        // (#196 실측) 같이 건다. 단 iOS 26에선 `unselectedItemTintColor`도 무시된다(위 참고).
        UITabBar.appearance().tintColor = selectedColor
        UITabBar.appearance().unselectedItemTintColor = unselectedColor
    }
}
