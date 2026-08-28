//
//  MainTabView.swift
//  WSS-iOS
//
//  Created by Guryss on 8/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

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
    /// 어느 탭에서 발생했든 인증 만료는 같은 곳(온보딩 루트)으로 되돌린다 — idempotent해야 한다
    /// (여러 탭이 동시에 API를 호출 중이면 시간차로 여러 번 불릴 수 있음, `HomeFeature`/`LibraryFeature`와 동일 계약).
    let onAuthenticationRequired: () -> Void

    @State private var selectedTab: Tab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeRootView(dependencies: dependencies, onAuthenticationRequired: onAuthenticationRequired)
                .tabItem { tabLabel("홈", icon: WSSImage.icNavigateHome) }
                .tag(Tab.home)

            FeedRootView(dependencies: dependencies, onAuthenticationRequired: onAuthenticationRequired)
                .tabItem { tabLabel("피드", icon: WSSImage.icNavigateFeed) }
                .tag(Tab.feed)

            LibraryRootView(dependencies: dependencies, onAuthenticationRequired: onAuthenticationRequired)
                .tabItem { tabLabel("서재", icon: WSSImage.icNavigateLibrary) }
                .tag(Tab.library)

            MypageRootView(
                dependencies: dependencies,
                onLibraryTapped: { selectedTab = .library },
                onAuthenticationRequired: onAuthenticationRequired
            )
            .tabItem { tabLabel("My", icon: WSSImage.icNavigateMy) }
            .tag(Tab.my)
        }
    }
}

private extension MainTabView {
    /// ⚠️ `Label(_:image:)`(문자열 이름)는 쓰지 않는다 — 이 아이콘들은 App이 아니라 `DesignSystem`
    /// 프레임워크의 리소스 번들에 있어서, 이름 문자열만으로 찾는 `Image(_:)`/`Label(_:image:)`는
    /// 기본 번들(App)만 뒤져 **완전히 새로 설치한 상태에서는 조용히 빈 아이콘**이 된다(#196에서 실측 —
    /// 이전 빌드가 남아있는 상태에선 우연히 다르게 보여 처음엔 못 잡았다). 번들을 이미 아는
    /// `WSSImage.icXxx.swiftUIImage`(전 Feature가 쓰는 정본 경로)로 직접 그린다.
    func tabLabel(_ title: String, icon: DesignSystemImages) -> some View {
        Label {
            Text(title)
        } icon: {
            // .template이어야 UITabBarAppearance의 iconColor(선택 wssBlack/비선택 wssGray200,
            // WSSIOSV2App.configureTabBarAppearance)가 실제로 먹는다 — 이 에셋 자체는
            // template-rendering-intent가 "original"이라 여기서 명시하지 않으면 원색 그대로 나간다.
            icon.swiftUIImage
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
    }
}
