import SwiftUI

import KakaoSDKAuth
import KakaoSDKCommon

import DesignSystem

@main
struct WSSIOSV2App: App {

    init() {
        // 커스텀 폰트(Pretendard) 등록. 없으면 applyWSSFont의 UIFont(name:)! 가 nil → 크래시.
        DesignSystemFontFamily.registerAllCustomFonts()

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
