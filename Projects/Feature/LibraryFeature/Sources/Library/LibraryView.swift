//
//  LibraryView.swift
//  LibraryFeature
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NovelDomain
import DesignSystem
import WSSComponent

// 서재 탭 — 내가 등록한 작품 목록을 그리드/리스트로 조회하고 필터·정렬한다.
// "얇은 VM": 카피·포맷·색은 전부 View가 결정한다.
struct LibraryView: View {

    /// 목록 표시 모드 — VM 처리가 필요 없는 순수 표시 상태라 View가 소유한다.
    private enum DisplayMode {
        case grid
        case list
    }

    // 선언 순서: VM → View 전용 상태 → @Environment → 주입 let
    @State private var viewModel: LibraryViewModel
    @State private var displayMode: DisplayMode = .grid
    @State private var isSortSheetPresented = false
    @State private var isFilterSheetPresented = false

    /// 작품 셀 탭 → 작품 상세 진입 콜백. 화면 전환은 호출자(App)가 수행한다.
    private let onNovelSelected: (NovelID) -> Void
    /// 빈 상태 "웹소설 찾기" 버튼 → 검색 화면 진입 콜백.
    private let onSearchTapped: () -> Void
    /// 우상단 등록 버튼 → 작품 등록(검색) 진입 콜백.
    private let onRegisterTapped: () -> Void
    /// "알림 관리" → 관심 작품 알림 설정 진입 콜백.
    private let onNotificationTapped: () -> Void
    /// 인증 만료 시 로그인 유도 콜백 — 화면 내 모든 서버 호출 공통.
    private let onAuthenticationRequired: () -> Void

    init(
        viewModel: LibraryViewModel,
        onNovelSelected: @escaping (NovelID) -> Void,
        onSearchTapped: @escaping () -> Void,
        onRegisterTapped: @escaping () -> Void,
        onNotificationTapped: @escaping () -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onNovelSelected = onNovelSelected
        self.onSearchTapped = onSearchTapped
        self.onRegisterTapped = onRegisterTapped
        self.onNotificationTapped = onNotificationTapped
        self.onAuthenticationRequired = onAuthenticationRequired
    }

    var body: some View {
        content
            .onAppear { viewModel.handle(.load) }
            .showWSSToast(isPresented: toastBinding, type: toastType)
            .onChange(of: viewModel.state.requiresAuthentication) { _, required in
                if required { onAuthenticationRequired() }
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            headerSection
            filterChipSection
            countSortSection
            novelListSection
        }
        .overlay {
            if viewModel.state.loadFailed {
                NetworkErrorView { viewModel.handle(.retry) }
            }
        }
    }
}

// MARK: - Sections

private extension LibraryView {

    /// 상단 헤더 — "서재" 타이틀 + 작품 등록 버튼. (UI는 3단계에서 디자인 반영)
    var headerSection: some View {
        HStack(spacing: 0) {
            Text("서재")
            Spacer()
            Button {
                onRegisterTapped()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    /// 모드 토글 + 필터 칩 행. (UI는 3단계에서 디자인 반영)
    var filterChipSection: some View {
        HStack(spacing: 0) {
            Button {
                displayMode = displayMode == .grid ? .list : .grid
            } label: {
                Text(displayMode == .grid ? "그리드" : "리스트")
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                viewModel.handle(.loadRegisteredKeywords)
                isFilterSheetPresented = true
            } label: {
                Text("필터")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    /// "n개" 카운트 + 알림 관리 + 정렬. (UI는 3단계에서 디자인 반영)
    var countSortSection: some View {
        HStack(spacing: 0) {
            Text("\(viewModel.state.totalCount)개")
            Spacer()
            Button {
                onNotificationTapped()
            } label: {
                Text("알림 관리")
            }
            .buttonStyle(.plain)
            Button {
                isSortSheetPresented = true
            } label: {
                Text("정렬")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    /// 작품 목록 — 그리드/리스트 모드. 마지막 셀 노출 시 다음 페이지 로드. (UI는 3단계에서 디자인 반영)
    var novelListSection: some View {
        ScrollView {
            if viewModel.state.novels.isEmpty && !viewModel.state.isLoading {
                emptySection
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.state.novels, id: \.id) { novel in
                        Button {
                            onNovelSelected(novel.id)
                        } label: {
                            Text(novel.title)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            if novel.id == viewModel.state.novels.last?.id {
                                viewModel.handle(.loadMore)
                            }
                        }
                    }
                    if viewModel.state.isLoadingMore {
                        ProgressView()
                    }
                }
            }
        }
    }

    /// 빈 상태 — "서재가 비어있어요" + 웹소설 찾기. (UI는 3단계에서 디자인 반영)
    var emptySection: some View {
        VStack(spacing: 0) {
            Text("서재가 비어있어요")
            Button {
                onSearchTapped()
            } label: {
                Text("웹소설 찾기")
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Presentation

private extension LibraryView {

    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedToast != nil },
            set: { if !$0 { viewModel.handle(.dismissToast) } }
        )
    }

    var toastType: WSSToastType {
        .unknownError
    }
}
