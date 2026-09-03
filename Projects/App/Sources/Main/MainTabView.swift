//
//  MainTabView.swift
//  WSS-iOS
//
//  Created by Guryss on 8/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import DesignSystem

/// 온보딩(로그인~가입) 완료 후 진입하는 메인 화면 — 홈 / 피드 / 서재 / My, 4개 탭.
/// 탭 아이콘은 `DesignSystem`의 `Icons/Tabbar` 에셋(`icNavigateHome` 등)을 쓴다.
struct MainTabView: View {

    /// 탭 콘텐츠(예: 마이페이지의 서재 블록)가 다른 탭으로 push가 아니라 **전환**을 요청할 수 있도록
    /// `selection:` 바인딩과 짝지어 쓴다 — 화면 push와 달리 탭 전환은 대상 탭의 `NavigationPath`를
    /// 건드리지 않는다(그 탭이 이미 쌓아둔 스택은 그대로 유지된 채 앞으로 나온다).
    private enum Tab {
        case home, feed, library, my
    }

    let dependencies: AppDependencies
    /// 앱 밖에서 들어온 딥링크(`WSSIOSV2App.onOpenURL`, #228) — **지금 선택된 탭**의 스택 위에 바로 push한다
    /// (사용자 확정 — 앱을 쓰던 중이면 보던 화면에서 곧장 넘어가고, 콜드 스타트면 기본 탭인 홈 위).
    /// `TabView`는 4탭 Root를 전부 동시에 mount하므로 값을 전부에게 주면 4번 push된다 — 선택된 탭에만
    /// 건네고(`deepLink(for:)`), 그 탭이 소비하면 nil로 되돌린다.
    @Binding var pendingDeepLink: DeepLink?
    /// 어느 탭에서 발생했든 인증 만료는 같은 곳(온보딩 루트)으로 되돌린다 — idempotent해야 한다
    /// (여러 탭이 동시에 API를 호출 중이면 시간차로 여러 번 불릴 수 있음, `HomeFeature`/`LibraryFeature`와 동일 계약).
    let onAuthenticationRequired: () -> Void

    @State private var selectedTab: Tab = .home
    /// 선택된 탭 Root가 소비해 push한 딥링크 — **그 화면이 스택에 남아 있는 동안만** 값이 있다. 인증 만료(401)로
    /// 온보딩에 되돌아가면 이 탭 트리째 파괴돼 push했던 화면도 함께 사라지므로, 그 시점에 `pendingDeepLink`로
    /// 되살려 로그인 뒤 새 `MainTabView`가 다시 처리한다 — 토큰 없는 콜드 스타트(세션 복원 전까진 매번
    /// `.main`으로 시작했다가 몇 초 안에 401로 튕긴다)에서 카드의 "앱에서 보기"가 통째로 유실되던 문제(#228 리뷰).
    /// 사용자가 그 화면을 벗어나면(Root의 `onDeepLinkDestinationDismissed`) 지운다 — 안 지우면 한참 뒤 무관한
    /// 401에도 옛 컬렉션이 재로그인 후 다시 떠버린다. 로그아웃·탈퇴(`MypageRootView.onSessionEnded`)는 사용자가
    /// 세션을 끝낸 것이라 되살리지 않는다. 어느 탭이 소비했는지도 같이 들어, 다른 탭의 딥링크 화면이 빠질 때
    /// 이 값이 지워지지 않게 한다(탭마다 스택이 따로라 홈의 링크 A와 피드의 링크 B가 동시에 살아 있을 수 있다).
    @State private var deliveredDeepLink: (tab: Tab, link: DeepLink)?

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeRootView(
                dependencies: dependencies,
                deepLink: deepLink(for: .home),
                onDeepLinkConsumed: consumeDeepLink,
                onDeepLinkDestinationDismissed: { clearDeliveredDeepLink(for: .home) },
                onAuthenticationRequired: restoreDeepLinkAndRequireAuthentication
            )
            .tabItem { tabLabel("홈", icon: WSSImage.icNavigateHome, isSelected: selectedTab == .home) }
            .tag(Tab.home)

            FeedRootView(
                dependencies: dependencies,
                deepLink: deepLink(for: .feed),
                onDeepLinkConsumed: consumeDeepLink,
                onDeepLinkDestinationDismissed: { clearDeliveredDeepLink(for: .feed) },
                onAuthenticationRequired: restoreDeepLinkAndRequireAuthentication
            )
            .tabItem { tabLabel("피드", icon: WSSImage.icNavigateFeed, isSelected: selectedTab == .feed) }
            .tag(Tab.feed)

            LibraryRootView(
                dependencies: dependencies,
                deepLink: deepLink(for: .library),
                onDeepLinkConsumed: consumeDeepLink,
                onDeepLinkDestinationDismissed: { clearDeliveredDeepLink(for: .library) },
                onAuthenticationRequired: restoreDeepLinkAndRequireAuthentication
            )
            .tabItem { tabLabel("서재", icon: WSSImage.icNavigateLibrary, isSelected: selectedTab == .library) }
            .tag(Tab.library)

            MypageRootView(
                dependencies: dependencies,
                deepLink: deepLink(for: .my),
                onDeepLinkConsumed: consumeDeepLink,
                onDeepLinkDestinationDismissed: { clearDeliveredDeepLink(for: .my) },
                onLibraryTapped: { selectedTab = .library },
                onSessionEnded: onAuthenticationRequired,
                onAuthenticationRequired: restoreDeepLinkAndRequireAuthentication
            )
            .tabItem { tabLabel("My", icon: WSSImage.icNavigateMy, isSelected: selectedTab == .my) }
            .tag(Tab.my)
        }
        .task {
            // 푸시 권한 요청·원격 알림 등록(#243, V1 parity) — 메인 탭 진입 시 1회. `MainTabView`는 세션이
            // 있어야만(부트스트랩 통과) 뜨므로 여기가 "로그인 상태의 메인 진입"에 해당한다. 미결정이면 권한을
            // 요청하고, 허용 상태면 APNs 등록을 시작해 FCM 토큰이 서버에 등록되도록 한다.
            await PushNotificationCenter.shared.requestAuthorizationAndRegisterIfGranted()
        }
    }
}

// MARK: - 딥링크

private extension MainTabView {
    /// `Tab`이 `private`라 이 메서드도 `private`여야 컴파일된다(`private extension`의 기본은 fileprivate).
    private func deepLink(for tab: Tab) -> DeepLink? {
        selectedTab == tab ? pendingDeepLink : nil
    }

    /// 소비자는 항상 지금 선택된 탭이다(`deepLink(for:)`가 그 탭에만 값을 주므로).
    func consumeDeepLink() {
        deliveredDeepLink = pendingDeepLink.map { (tab: selectedTab, link: $0) }
        pendingDeepLink = nil
    }

    /// `Tab`이 `private`라 이 메서드도 `private`여야 컴파일된다(`deepLink(for:)`와 같은 이유).
    private func clearDeliveredDeepLink(for tab: Tab) {
        guard deliveredDeepLink?.tab == tab else { return }
        deliveredDeepLink = nil
    }

    /// 401 만료 경로(4탭 공통) — 딥링크 화면이 아직 스택에 있으면 되살린 뒤 온보딩으로 되돌린다. 여러 탭이
    /// 시간차로 불러도 같은 값을 다시 쓸 뿐이라 idempotent 계약은 그대로다.
    func restoreDeepLinkAndRequireAuthentication() {
        if let deliveredDeepLink {
            pendingDeepLink = deliveredDeepLink.link
        }
        onAuthenticationRequired()
    }
}

private extension MainTabView {
    /// ⚠️ `Label(_:image:)`(문자열 이름)는 쓰지 않는다 — 이 아이콘들은 App이 아니라 `DesignSystem`
    /// 프레임워크의 리소스 번들에 있어서, 이름 문자열만으로 찾는 `Image(_:)`/`Label(_:image:)`는
    /// 기본 번들(App)만 뒤져 **완전히 새로 설치한 상태에서는 조용히 빈 아이콘**이 된다(#196에서 실측 —
    /// 이전 빌드가 남아있는 상태에선 우연히 다르게 보여 처음엔 못 잡았다). 번들을 이미 아는
    /// `WSSImage.icXxx.swiftUIImage`(전 Feature가 쓰는 정본 경로)로 직접 그린다.
    func tabLabel(_ title: String, icon: DesignSystemImages, isSelected: Bool) -> some View {
        // iOS 26 새(Liquid Glass) 탭바는 template 이미지를 자기 틴트로 덮어써(비선택=검정)
        // `UITabBarAppearance.normal`을 무시한다(실측 — appearance/`foregroundStyle`/`.tint` 모두 비선택은
        // 검정으로 남았고, tint를 아예 빼도 커스텀 이미지라 자동 회색 처리를 못 받았다). 그래서 틴트에
        // 맡기지 않고 **색을 미리 구운 `.alwaysOriginal` 이미지**를 선택 상태별로 바꿔 끼운다 —
        // `.alwaysOriginal`이면 탭바가 재틴트를 못 해 우리가 칠한 색이 그대로 남는다(iOS 버전 무관).
        // 글씨 색은 어피어런스가 담당(`WSSIOSV2App.configureTabBarAppearance`) — iOS 26 비선택 글씨는
        // 거기서도 검정으로 남지만(플랫폼 제약, 아이콘만 회색으로 구분), iOS 18 이하는 글씨도 gray200.
        let color = UIColor(isSelected ? Color.wssBlack : Color.wssGray200)
        let tinted = icon.image.withTintColor(color, renderingMode: .alwaysOriginal)
        return Label {
            Text(title)
        } icon: {
            Image(uiImage: tinted)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
    }
}
