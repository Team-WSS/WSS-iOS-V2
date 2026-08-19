import SwiftUI

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

    public init() {}

    public var body: some View {
        switch route {
        case .onboarding:
            OnboardingRootView(dependencies: dependencies, onFinished: { route = .main })
        case .main:
            MainTabView(dependencies: dependencies, onAuthenticationRequired: { route = .onboarding })
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
