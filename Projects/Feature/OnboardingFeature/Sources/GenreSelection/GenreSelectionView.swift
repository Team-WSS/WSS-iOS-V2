//
//  GenreSelectionView.swift
//  OnboardingFeature
//
//  Created by Seoyeon Choi on 8/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import ProfileDomain
import DesignSystem
import WSSComponent

/// 온보딩 3단계(마지막, 콘텐츠만) — 선호 장르 선택. "건너뛰기"로 장르 없이도 완료 가능(닉네임/약관 동의와
/// 달리 이 화면만 필수 단계가 아니다). 공통 헤더(뒤로가기+건너뛰기)·진행바는 컨테이너
/// `OnboardingStepFlowView`가 소유·렌더링한다 — 컨테이너가 이 화면의 VM을 직접 들고 있어 "건너뛰기"도
/// 컨테이너가 `viewModel.handle(.skip)`으로 곧장 호출한다(이 화면에 별도 콜백 불필요). 이 화면은
/// 장르 그리드+하단 CTA만 담당한다.
struct GenreSelectionView: View {

    @State private var viewModel: GenreSelectionViewModel

    /// 인증 만료(등록 호출 중 세션 죽음) 시 로그인 화면 진입 콜백.
    private let onAuthenticationRequired: () -> Void
    /// 프로필 등록 성공 시 발화 — 온보딩 종료 후 어디로 갈지(Home 등)는 호출자(App)가 결정한다.
    private let onCompleted: () -> Void

    init(
        viewModel: GenreSelectionViewModel,
        onAuthenticationRequired: @escaping () -> Void,
        onCompleted: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onAuthenticationRequired = onAuthenticationRequired
        self.onCompleted = onCompleted
    }

    var body: some View {
        content
            .showWSSToast(isPresented: toastBinding, type: toastType)
            .onChange(of: viewModel.state.isCompleted) { _, isCompleted in
                if isCompleted { onCompleted() }
            }
            .onChange(of: viewModel.state.requiresAuthentication) { _, needsAuth in
                if needsAuth { onAuthenticationRequired() }
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                titleSection
                    .padding(.horizontal, 20)   // 타이틀은 기존 좌우 여백(20) 유지 — 그리드만 39로 인셋

                Spacer().frame(height: 50)      // 서브타이틀 ↔ 그리드 간격

                genreGrid
                    .padding(.horizontal, Self.gridHorizontalMargin)   // 그리드 좌우 여백 39
            }
            .padding(.top, 50)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.wssWhite)
        .overlay {
            if viewModel.state.isSubmitting {
                LoadingView()
            }
        }
        .safeAreaInset(edge: .bottom) {
            ctaButton
        }
    }
}

// MARK: - Sections

private extension GenreSelectionView {

    var titleSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("평소 즐겨보는 장르를 선택하세요")
                .applyWSSFont(.headline1)
                .foregroundStyle(Color.wssBlack)

            Spacer().frame(height: 8)

            Text("선호 장르를 기반으로 웹소설을 추천해드려요")
                .applyWSSFont(.body2)
                .foregroundStyle(Color.wssGray200)
        }
    }

    var genreGrid: some View {
        VStack(spacing: Self.rowSpacing) {           // 행 간격 25
            ForEach(genreRows, id: \.self) { row in
                HStack(spacing: Self.columnSpacing) {  // 열 간격 24
                    ForEach(row, id: \.self) { genre in
                        genreBadge(genre)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// 셀 = 원 배지 + 라벨 한 덩어리. 원 지름(`badgeSize`)은 화면 폭에 따라 가변(SE는 60 고정)이고,
    /// 각 셀은 `.frame(maxWidth: .infinity)`로 3등분된 열을 채운다 — 일반 기기에선 원 지름 == 열 폭이라
    /// 원이 열을 꽉 채우고(여백 39·열간격 24가 정확히 맞음), SE에선 60짜리 원이 열 안에서 가운데 정렬된다.
    func genreBadge(_ genre: NovelGenre) -> some View {
        let isSelected = viewModel.state.selectedGenres.contains(genre)
        let size = badgeSize
        // 아이콘·체크마크는 원 지름에 비례 스케일(기존 83 기준 40/44 비율 유지). 라벨 폰트는 title3 고정.
        let iconSize = size * (40.0 / 83.0)
        let checkSize = size * (44.0 / 83.0)

        return Button {
            viewModel.handle(.toggleGenre(genre))
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.wssPrimary50 : Color.wssGray50)
                        .overlay {
                            if isSelected {
                                Circle().strokeBorder(Color.wssPrimary100, lineWidth: 2)
                            }
                        }
                        .frame(width: size, height: size)

                    if isSelected {
                        WSSImage.icCheckMark.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: checkSize, height: checkSize)
                    } else {
                        genre.iconImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: iconSize, height: iconSize)
                    }
                }

                Text(genre.displayName)
                    .applyWSSFont(.title3)
                    .foregroundStyle(Color.wssGray300)
            }
            .frame(maxWidth: .infinity)   // 3등분 열을 채워 열 폭·탭 영역을 균등 분배
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }

    var ctaButton: some View {
        WSSCTAButton(
            title: "완료",
            isEnabled: !viewModel.state.selectedGenres.isEmpty && !viewModel.state.isSubmitting
        ) {
            viewModel.handle(.complete)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Presentation

private extension GenreSelectionView {
    // MARK: 그리드 레이아웃 상수 (사용자 확정 스펙)
    static let gridHorizontalMargin: CGFloat = 39   // 그리드 좌우 여백
    static let columnSpacing: CGFloat = 24          // 열(가로) 간격
    static let rowSpacing: CGFloat = 25             // 행(세로) 간격
    static let columnCount: CGFloat = 3
    static let compactBadgeSize: CGFloat = 60       // SE 등 세로 짧은 기기의 고정 셀 크기
    /// SE(375×667)처럼 세로가 짧은 기기 판별 — mini(375×812)와 폭이 같아 높이로만 가른다.
    static let compactHeightThreshold: CGFloat = 700

    /// 원 배지 지름 — 화면 폭에서 좌우 여백(39×2)·열 간격(24×2)을 뺀 뒤 3등분(원은 정사각이라 세로도 동일).
    /// 세로가 짧은 기기(SE)는 세로 공간이 부족해 폭 기반 가변 대신 60 고정(사용자 스펙, 여백 39는 유지).
    /// 화면 크기는 코드베이스 관례대로 `UIScreen.main.bounds`로 읽는다(온보딩은 세로 고정 = 슬롯 폭 == 화면 폭).
    var badgeSize: CGFloat {
        if UIScreen.main.bounds.height < Self.compactHeightThreshold { return Self.compactBadgeSize }
        let gridWidth = UIScreen.main.bounds.width - Self.gridHorizontalMargin * 2
        return (gridWidth - Self.columnSpacing * (Self.columnCount - 1)) / Self.columnCount
    }

    /// `NovelGenre.onboardingGenre`(9개)를 3개씩 끊어 3x3 그리드 행으로.
    var genreRows: [[NovelGenre]] {
        stride(from: 0, to: NovelGenre.onboardingGenre.count, by: 3).map {
            Array(NovelGenre.onboardingGenre[$0..<min($0 + 3, NovelGenre.onboardingGenre.count)])
        }
    }

    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedError != nil },
            set: { if !$0 { viewModel.handle(.dismissError) } }
        )
    }

    var toastType: WSSToastType {
        switch viewModel.state.presentedError {
        case .unknown, .none: .unknownError
        }
    }
}

// MARK: - Preview

#Preview {
    // 앞 단계 값은 실제 흐름에선 컨테이너가 `.setProfileContext`로 주입한다 — 프리뷰는 미주입 상태(등록 시 guard).
    GenreSelectionView(
        viewModel: GenreSelectionViewModel(registerProfileUseCase: PreviewRegisterProfileUseCase()),
        onAuthenticationRequired: { print("인증 만료 → 로그인 진입") },
        onCompleted: { print("온보딩 완료 → Home") }
    )
}

private struct PreviewRegisterProfileUseCase: RegisterProfileUseCase {
    func execute(_ profile: ProfileRegistration) async throws(RepositoryError) {}
}
