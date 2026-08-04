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

/// 온보딩 3단계(마지막) — 선호 장르 선택. 진행바 3/3. 뒤로가기 가능 + "건너뛰기"로 장르 없이도 완료 가능
/// (닉네임/약관 동의와 달리 이 화면만 필수 단계가 아니다 — Figma에 back chevron·skip이 실제로 있다).
struct GenreSelectionView: View {

    @State private var viewModel: GenreSelectionViewModel
    @Environment(\.dismiss) private var dismiss

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
            .toolbar(.hidden, for: .navigationBar)
            .enableSwipeBack()
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
            VStack(spacing: 0) {
                headerRow
                OnboardingStepProgressBar(currentStep: 3)
            }

            VStack(alignment: .leading, spacing: 0) {
                titleSection
                Spacer().frame(height: 61)
                genreGrid
            }
            .padding(.horizontal, 20)
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

    /// Figma "고정 영역"의 back chevron + 건너뛰기 텍스트 행 — 시스템 네비바가 아니라 화면 자체 콘텐츠(스와이프 뒤로가기는 `.enableSwipeBack()`로 별도 복원).
    var headerRow: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: 6)
            
            Button {
                dismiss()
            } label: {
                WSSImage.icNavigateLeft.swiftUIImage
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.wssBlack)
                    .frame(width: 24, height: 24)
            }
            .frame(width: 44, height: 44)
            .padding(.leading, 6)

            Spacer()

            Button {
                viewModel.handle(.skip)
            } label: {
                Text("건너뛰기")
                    .applyWSSFont(.body2)
                    .foregroundStyle(Color.wssGray300)
            }
            .padding(10)
            
            Spacer().frame(width: 12)
        }
        .frame(height: 44)
        .padding(.top, 27)
        .padding(.bottom, 17)
    }

    var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("평소 즐겨보는 장르를 선택하세요")
                .applyWSSFont(.headline1)
                .foregroundStyle(Color.wssBlack)

            Text("선호 장르를 기반으로 웹소설을 추천해드려요")
                .applyWSSFont(.body2)
                .foregroundStyle(Color.wssGray200)
        }
    }

    var genreGrid: some View {
        VStack(spacing: 25) {
            ForEach(genreRows, id: \.self) { row in
                HStack(spacing: 24) {
                    ForEach(row, id: \.self) { genre in
                        genreBadge(genre)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    func genreBadge(_ genre: NovelGenre) -> some View {
        let isSelected = viewModel.state.selectedGenres.contains(genre)

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
                        .frame(width: 83, height: 83)

                    if isSelected {
                        WSSImage.icCheckMark.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                    } else {
                        genre.iconImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                    }
                }

                Text(genre.displayName)
                    .applyWSSFont(.title3)
                    .foregroundStyle(Color.wssGray300)
            }
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
    GenreSelectionView(
        viewModel: GenreSelectionViewModel(
            nickname: "구리구리스",
            gender: .female,
            birthYear: try! BirthYear(2000),
            registerProfileUseCase: PreviewRegisterProfileUseCase()
        ),
        onAuthenticationRequired: { print("인증 만료 → 로그인 진입") },
        onCompleted: { print("온보딩 완료 → Home") }
    )
}

private struct PreviewRegisterProfileUseCase: RegisterProfileUseCase {
    func execute(_ profile: ProfileRegistration) async throws(RepositoryError) {}
}
