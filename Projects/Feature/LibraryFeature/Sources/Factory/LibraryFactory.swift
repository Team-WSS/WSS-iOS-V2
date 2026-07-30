//
//  LibraryFactory.swift
//  LibraryFeature
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NovelDomain
import Logger

/// 모듈의 유일한 public 진입점.
/// View/ViewModel은 `internal`로 감추고, opaque `some View`로 구체 타입을 숨겨 반환한다.
/// UseCase(프로토콜)는 외부(App/Demo)가 주입한다 — Feature는 Repository/Data 구현을 모른다.
public enum LibraryFactory {

    /// - Parameters:
    ///   - onNovelSelected: 작품 셀 탭 → 작품 상세 진입 콜백. 화면 전환은 호출자(App)가 수행한다.
    ///   - onSearchTapped: 빈 상태 "웹소설 찾기" → 검색 화면 진입 콜백.
    ///   - onRegisterTapped: 우상단 등록 버튼 → 작품 등록 진입 콜백.
    ///   - onNotificationTapped: "알림 관리" → 관심 작품 알림 설정 진입 콜백.
    ///   - onAuthenticationRequired: 인증 만료(세션 죽음) 시 로그인 화면 진입 콜백 — 화면 내 서버 호출 공통.
    @MainActor
    public static func makeView(
        loadMyLibraryUseCase: LoadMyLibraryUseCase,
        loadMyLibraryKeywordsUseCase: LoadMyLibraryKeywordsUseCase,
        logger: Logger? = nil,
        onNovelSelected: @escaping (NovelID) -> Void,
        onSearchTapped: @escaping () -> Void,
        onRegisterTapped: @escaping () -> Void,
        onNotificationTapped: @escaping () -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        let viewModel = LibraryViewModel(
            loadMyLibraryUseCase: loadMyLibraryUseCase,
            loadMyLibraryKeywordsUseCase: loadMyLibraryKeywordsUseCase,
            logger: logger
        )
        return LibraryView(
            viewModel: viewModel,
            onNovelSelected: onNovelSelected,
            onSearchTapped: onSearchTapped,
            onRegisterTapped: onRegisterTapped,
            onNotificationTapped: onNotificationTapped,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    /// 다른 사용자의 서재 화면. **`NavigationStack`에 push되는 화면**이라 뒤로가기는 화면이 스스로 처리한다
    /// (내 서재는 탭 콘텐츠라 반대 — 그쪽엔 뒤로가기가 없다).
    ///
    /// - Parameters:
    ///   - userID: 조회 대상 사용자. 진입 시점(유저 프로필 등)에서 넘긴다.
    ///   - onNovelSelected: 작품 셀 탭 → 작품 상세 진입 콜백. 화면 전환은 호출자(App)가 수행한다.
    ///   - onAuthenticationRequired: 인증 만료(세션 죽음) 시 로그인 화면 진입 콜백.
    ///     ⚠️ **idempotent해야 한다** — 화면이 신호를 소진하고 다시 세우므로 만료가 반복되면 여러 번 불린다.
    ///     루트 교체는 무해하지만 `path.append(.login)`류면 로그인 화면이 겹쳐 쌓인다.
    @MainActor
    public static func makeUserLibraryView(
        userID: UserID,
        loadUserLibraryUseCase: LoadUserLibraryUseCase,
        logger: Logger? = nil,
        onNovelSelected: @escaping (NovelID) -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        let viewModel = UserLibraryViewModel(
            userID: userID,
            loadUserLibraryUseCase: loadUserLibraryUseCase,
            logger: logger
        )
        return UserLibraryView(
            viewModel: viewModel,
            onNovelSelected: onNovelSelected,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}
