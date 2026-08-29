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

    init() {
        // 커스텀 폰트(Pretendard) 등록. 없으면 applyWSSFont의 UIFont(name:)! 가 nil → 크래시.
        DesignSystemFontFamily.registerAllCustomFonts()

        // 탭바 선택/비선택 색상(아이콘+글씨) — SwiftUI TabView는 비선택 색을 지정하는 공개 API가
        // 없어(iOS 17 기준) UIKit 어피어런스 프록시로 앱 시작 시 1회 설정한다. `MainTabView`의
        // `.renderingMode(.template)` 아이콘과 짝을 이뤄야 iconColor 틴트가 실제로 먹는다.
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
                    // 카카오 로그인 콜백(`kakao{APP_KEY}://oauth…`)은 SDK에 넘기고, 나머지는 우리 딥링크로
                    // 해석한다 — `websoso://…`와 카카오톡 공유 카드의 "앱에서 보기"
                    // (`kakao{APP_KEY}://kakaolink?collectionId=…`, #228) 둘 다 `DeepLink.init?(url:)`이
                    // 풀고, 형식에 안 맞는 URL은 조용히 무시한다.
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                        return
                    }
                    if let deepLink = DeepLink(url: url) {
                        pendingDeepLink = deepLink
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

        // `UITabBarAppearance`의 iconColor만으로는 iOS 버전에 따라 비선택 아이콘이 시스템 기본색(검정)으로
        // 남는 경우가 있어(#196 실측 — 비선택 탭이 계속 검정으로 보임), 더 오래되고 더 직접적인 레거시
        // 프로퍼티로 이중 보강한다. 이쪽이 비선택 색상엔 더 안정적으로 먹는다.
        UITabBar.appearance().tintColor = selectedColor
        UITabBar.appearance().unselectedItemTintColor = unselectedColor
    }
}
