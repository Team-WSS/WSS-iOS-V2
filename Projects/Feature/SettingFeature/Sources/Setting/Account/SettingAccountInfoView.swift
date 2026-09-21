//
//  SettingAccountInfoView.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import ProfileDomain
import AuthDomain
import DesignSystem
import WSSComponent
import Logger

struct SettingAccountInfoView: View {

    @State private var viewModel: SettingAccountInfoViewModel
    @Environment(\.dismiss) private var dismiss

    /// 로그아웃 성공 시 호출된다. 세션 종료(로그인 화면 전환 등)는 App(세션 관찰) 책임이라
    /// 이 화면은 성공 신호만 호출자에게 전달한다.
    private let onLogoutSuccess: () -> Void
    /// 화면 전환 의도 콜백(#253) — 계약은 `SettingAccountInfoRoute`(Navigation/)가 정본.
    private let onRoute: (SettingAccountInfoRoute) -> Void
    /// 인증 만료 시 로그인 유도 콜백 — 이메일 로드·로그아웃이 401로 막히면 발화(Feature 공통 계약).
    /// 로그아웃 401은 이미 세션이 끝난 것이라 실패 토스트 대신 이 콜백으로 로그인/온보딩으로 되돌린다
    /// (`onLogoutSuccess`와 결과는 같지만 App이 딥링크 복원 여부를 달리 거는 별개 콜백, `App/CLAUDE.md`).
    private let onAuthenticationRequired: () -> Void

    init(
        viewModel: SettingAccountInfoViewModel,
        onLogoutSuccess: @escaping () -> Void = {},
        onRoute: @escaping (SettingAccountInfoRoute) -> Void,
        onAuthenticationRequired: @escaping () -> Void = {}
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onLogoutSuccess = onLogoutSuccess
        self.onRoute = onRoute
        self.onAuthenticationRequired = onAuthenticationRequired
    }

    var body: some View {
        VStack(spacing: 0) {
            WSSNavigationBar(title: "계정정보") { dismiss() }

            VStack(spacing: 0) {
                ForEach(SettingMenu.allCases, id: \.self) { menu in
                    SettingMenuRow(
                        title: menu.title,
                        bottomText: menu == .email ? viewModel.state.email : nil,
                        action: menu.isSelectable ? { select(menu) } : nil
                    )
                }

                Spacer()
            }
        }
        .wssCustomNavigationBar()
        .onAppear {
            viewModel.handle(.load)
        }
        .showWSSAlert(
            isPresented: logoutAlertBinding,
                      type: .logout,
                      buttonActions: [
                        { viewModel.handle(.cancelLogout) },
                        { viewModel.handle(.confirmLogout) }
                      ]
        )
        .showWSSToast(isPresented: logoutErrorToastBinding, type: .unknownError)
        .onChange(of: viewModel.state.logoutSucceeded) { _, logoutSucceeded in
            guard logoutSucceeded else { return }
            onLogoutSuccess()
        }
        .onChange(of: viewModel.state.requiresAuthentication) { _, required in
            guard required else { return }
            onAuthenticationRequired()
        }
    }

    private func select(_ menu: SettingMenu) {
        switch menu {
        case .changeGenderOrAge:
            onRoute(.changeGenderOrAge)
        case .blockUserList:
            onRoute(.blockUserList)
        case .withdraw:
            onRoute(.withdraw)
        case .logout:
            viewModel.handle(.presentLogoutAlert)
        case .email:
            break
        }
    }
}

// MARK: - Presentation

private extension SettingAccountInfoView {
    var logoutAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isLogoutAlertPresented },
            set: { if !$0 { viewModel.handle(.cancelLogout) } }
        )
    }

    var logoutErrorToastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedError != nil },
            set: { if !$0 { viewModel.handle(.dismissError) } }
        )
    }
}

// MARK: - Menu

extension SettingAccountInfoView {

    enum SettingMenu: CaseIterable {
        case changeGenderOrAge
        case email
        case blockUserList
        case logout
        case withdraw

        var title: String {
            switch self {
            case .changeGenderOrAge:    "성별/나이 변경"
            case .email:                "이메일"
            case .blockUserList:        "차단유저 목록"
            case .logout:               "로그아웃"
            case .withdraw:             "회원탈퇴"
            }
        }

        var isSelectable: Bool {
            switch self {
            case .email:    false
            default:        true
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingAccountInfoView(
            viewModel: SettingAccountInfoViewModel(
                loadAccountInfoDraftUseCase: PreviewLoadAccountInfoDraftUseCase(),
                logoutUseCase: PreviewLogoutUseCase()
            ),
            onRoute: { print("화면 전환 요청: \($0)") }
        )
    }
}

private struct PreviewLogoutUseCase: LogoutUseCase {
    func execute() async throws(RepositoryError) {}
}

private struct PreviewLoadAccountInfoDraftUseCase: LoadAccountInfoDraftUseCase {
    func execute() async throws(RepositoryError) -> AccountInfoDraft {
        AccountInfoDraft(email: "wss@websoso.kr", gender: .female, birth: try! BirthYear(2001))
    }
}
