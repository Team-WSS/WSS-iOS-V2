import SwiftUI

import KakaoSDKAuth
import KakaoSDKCommon

import DesignSystem

@main
struct WSSIOSV2App: App {

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
            ContentView()
                .onOpenURL { url in
                    _ = AuthController.handleOpenUrl(url: url)
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
