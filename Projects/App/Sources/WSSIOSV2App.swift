import SwiftUI

import KakaoSDKAuth
import KakaoSDKCommon

@main
struct WSSIOSV2App: App {

    init() {
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
