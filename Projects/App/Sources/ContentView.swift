import SwiftUI

import BaseDomain

/// 앱 루트 — 온보딩(로그인~가입) ↔ 홈, 두 플로우를 전환한다.
/// `AppDependencies`는 두 플로우가 같은 토큰(로그인 직후 저장된 것)으로 인증 API를 불러야 하므로
/// 여기 한 번만 만들어 아래로 내려준다(플로우별로 따로 만들면 서로 다른 `TokenStore` 인스턴스를
/// 갖게 될 일은 없지만, `NetworkingClient`·Repository를 중복 조립하게 된다).
public struct ContentView: View {
    private enum Route {
        case onboarding
        case main
    }

    @State private var dependencies = AppDependencies()
    @State private var route: Route = .main
    /// 앱 밖에서 들어온 딥링크(`WSSIOSV2App.onOpenURL`) — `MainTabView`가 소비한다. 온보딩 중엔 그대로
    /// 들고 있다가 `.main`으로 전환되는 순간 이어서 처리된다(공개 컬렉션은 서버가 비로그인 조회를
    /// 허용하지만, 앱 게이트가 메인 탭을 온보딩으로 되돌리므로 로그인 뒤 연결이 현실적이다). 토큰 없는
    /// 콜드 스타트는 `route`가 `.main`으로 시작해 먼저 소비돼 버리므로, 401 바운스 시점에 `MainTabView`가
    /// 되살려 놓는다(`deliveredDeepLink`).
    @Binding private var pendingDeepLink: DeepLink?

    public init(pendingDeepLink: Binding<DeepLink?> = .constant(nil)) {
        self._pendingDeepLink = pendingDeepLink
    }

    public var body: some View {
        Group {
            switch route {
            case .onboarding:
                OnboardingRootView(dependencies: dependencies, onFinished: { route = .main })
            case .main:
                MainTabView(
                    dependencies: dependencies,
                    pendingDeepLink: $pendingDeepLink,
                    onAuthenticationRequired: { route = .onboarding }
                )
            }
        }
        // DesignSystem 색상이 전부 고정값(다크 배리언트 없음, WSSColor.wssWhite 등)이라 시스템이
        // 다크모드면 배경만 시스템 기본(검정)으로 바뀌어 보인다 — 화면마다 .background(wssWhite)를
        // 개별로 다는 대신 앱 전체를 라이트모드로 고정해 한 번에 막는다(사용자 확정).
        .preferredColorScheme(.light)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
