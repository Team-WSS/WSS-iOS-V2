//
//  CreateCollectionView.swift
//  CollectionFeature
//
//  Created by Guryss on 8/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import CollectionDomain
import DesignSystem
import WSSComponent

// 컬렉션 생성 화면. "얇은 ViewModel" 원칙: 카피·포맷·색 등 표기는 전부 View가 결정한다.
// ⚠️ 골격 단계 — 세부 스타일·간격은 Figma 3단계에서 정밀 구현된다(아직 대략적인 레이아웃).
struct CreateCollectionView: View {

    @State private var viewModel: CreateCollectionViewModel
    /// 글자수 clamp 트랩(로컬 버퍼 → 확정값 반영 2단계, `Feature/CLAUDE.md` 참고) 전용 필드 버퍼.
    /// VM 상태에 TextField를 직접 물리지 않는다.
    @State private var nameFieldText: String
    @State private var descriptionFieldText: String
    @Environment(\.dismiss) private var dismiss

    /// "작품 추가"/"작품 수정" 타일 탭 콜백 — 작품 검색 화면은 이번 범위 밖(#199 후속)이라 placeholder.
    private let onAddNovelTapped: () -> Void
    /// 인증 만료 시 로그인 화면 진입 콜백. 화면 전환은 호출자(App)가 수행.
    private let onAuthenticationRequired: () -> Void

    init(
        viewModel: CreateCollectionViewModel,
        onAddNovelTapped: @escaping () -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self._nameFieldText = State(initialValue: viewModel.state.draft.name)
        self._descriptionFieldText = State(initialValue: viewModel.state.draft.description)
        self.onAddNovelTapped = onAddNovelTapped
        self.onAuthenticationRequired = onAuthenticationRequired
    }

    var body: some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar { toolbarContent }
            .showWSSToast(isPresented: toastBinding, type: toastType)
            .onChange(of: viewModel.state.shouldDismiss) { _, shouldDismiss in
                guard shouldDismiss else { return }
                dismiss()
            }
            // 인증 만료 신호 — 실제 로그인 화면 전환은 호출자(App)가 콜백 안에서 수행한다.
            .onChange(of: viewModel.state.requiresAuthentication) { _, needsAuth in
                if needsAuth { onAuthenticationRequired() }
            }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 0) {
                privateSection

                Spacer().frame(height: 20)

                VStack(spacing: 0) {
                    nameSection

                    Spacer().frame(height: 30)

                    descriptionSection

                    Spacer().frame(height: 30)

                    novelListSection
                }
                .padding(.horizontal, 16)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - Toolbar

private extension CreateCollectionView {

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                dismiss()
            } label: {
                WSSImage.icNavigateLeft.swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color.wssGray200)
            }
        }

        ToolbarItem(placement: .confirmationAction) {
            Button {
                viewModel.handle(.submit)
            } label: {
                if viewModel.state.isSubmitting {
                    ProgressView()
                } else {
                    Text("완료")
                        .applyWSSFont(.title2)
                        .foregroundStyle(viewModel.canSubmit ? Color.wssPrimary100 : Color.wssGray100)
                }
            }
            .disabled(!viewModel.canSubmit)
        }
    }
}

// MARK: - Sections

private extension CreateCollectionView {

    var privateSection: some View {
        WSSPrivateToggleRow(
            label: "나만 보는 컬렉션",
            isOn: Binding(
                get: { viewModel.state.draft.isPrivate },
                set: { _ in viewModel.handle(.togglePrivate) }
            )
        )
    }

    var nameSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("컬렉션 이름")
                    .foregroundStyle(Color.wssBlack)
                Text(" *")
                    .foregroundStyle(Color.wssPrimary100)
            }
            .applyWSSFont(.title2)
                
            Spacer().frame(height: 10)

            HStack(spacing: 0) {
                TextField("컬렉션 이름을 입력해주세요", text: $nameFieldText)
                    .applyWSSFont(.body2)

                Text("(\(nameFieldText.count)/\(CollectionDraft.maxNameCount))")
                    .applyWSSFont(.body2)
                    .foregroundStyle(Color.wssGray200)
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(Color.wssGray50)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .onChange(of: nameFieldText) { _, newValue in
            let clamped = String(newValue.prefix(CollectionDraft.maxNameCount))
            if clamped != newValue {
                nameFieldText = clamped
                return
            }
            viewModel.handle(.updateName(clamped))
        }
    }

    var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("컬렉션 설명")
                .applyWSSFont(.title2)
                .foregroundStyle(Color.wssBlack)

            Spacer().frame(height: 10)

            ZStack(alignment: .topLeading) {
                if descriptionFieldText.isEmpty {
                    Text("컬렉션에 관련한 설명을 간단하게 작성해주세요")
                        .applyWSSFont(.body2)
                        .foregroundStyle(Color.wssGray100)
                        .allowsHitTesting(false)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }

                TextField("", text: $descriptionFieldText, axis: .vertical)
                    .applyWSSFont(.body2)
                    .frame(maxWidth: .infinity, minHeight: 78, alignment: .topLeading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .background(Color.wssGray50)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(alignment: .bottomTrailing) {
                Text("(\(descriptionFieldText.count)/\(CollectionDraft.maxDescriptionCount))")
                    .applyWSSFont(.body2)
                    .foregroundStyle(Color.wssGray200)
                    .padding(.trailing, 16)
                    .padding(.bottom, 18)
            }
        }
        .onChange(of: descriptionFieldText) { _, newValue in
            let clamped = String(newValue.prefix(CollectionDraft.maxDescriptionCount))
            if clamped != newValue {
                descriptionFieldText = clamped
                return
            }
            viewModel.handle(.updateDescription(clamped))
        }
    }

    var novelListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                HStack(spacing: 0) {
                    Text("작품 리스트")
                        .foregroundStyle(Color.wssBlack)
                    Text(" *")
                        .foregroundStyle(Color.wssPrimary100)
                }
                .applyWSSFont(.title2)

                Text("(\(viewModel.state.draft.novelIDs.count)/\(CollectionDraft.maxNovelCount))")
                    .applyWSSFont(.body3)
                    .foregroundStyle(Color.wssGray200)
            }

            Spacer().frame(height: 12)

            novelGrid
        }
    }

    var novelGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
            spacing: 12
        ) {
            addNovelTile

            ForEach(viewModel.state.draft.novelIDs, id: \.self) { novelID in
                if let novel = viewModel.state.novelDisplayInfo[novelID] {
                    novelGridCell(novel)
                }
            }
        }
    }

    var addNovelTile: some View {
        Button(action: onAddNovelTapped) {
            VStack(spacing: 4) {
                Text(viewModel.state.draft.novelIDs.isEmpty ? "작품 추가" : "작품 수정")
                    .applyWSSFont(.title4)
                    .foregroundStyle(Color.wssGray200)

                WSSImage.icBookRegister.swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color.wssGray200)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 156)
            .background(Color.wssGray50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    func novelGridCell(_ novel: CollectionNovel) -> some View {
        let isRepresentative = novel.id == viewModel.representativeNovelID

        return VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                WSSNovelCoverImage(url: novel.thumbnailImage, aspectRatio: 108.0 / 156.0)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        if isRepresentative {
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.wssPrimary100, lineWidth: 2)
                        }
                    }

                Button {
                    viewModel.handle(.selectRepresentativeNovel(novel.id))
                } label: {
                    Text(isRepresentative ? "✓ 대표" : "대표")
                        .applyWSSFont(.label2)
                        .foregroundStyle(Color.wssWhite)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(isRepresentative ? Color.wssPrimary100 : Color.wssGray100)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .padding(8)
            }

            Text(novel.title)
                .applyWSSFont(.body4)
                .foregroundStyle(Color.wssBlack)
                .lineLimit(2)
        }
    }
}

// MARK: - Presentation

private extension CreateCollectionView {

    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedError != nil },
            set: { if !$0 { viewModel.handle(.dismissError) } }
        )
    }

    var toastType: WSSToastType {
        switch viewModel.state.presentedError {
        case .unknown, .none:
            .unknownError
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CreateCollectionView(
            viewModel: CreateCollectionViewModel(
                createCollectionUseCase: PreviewCreateCollectionUseCase()
            ),
            onAddNovelTapped: { print("작품 추가 진입") },
            onAuthenticationRequired: { print("인증 만료 → 로그인 진입") }
        )
    }
}

private struct PreviewCreateCollectionUseCase: CreateCollectionUseCase {
    func execute(_ draft: CollectionDraft) async throws(RepositoryError) -> CollectionID {
        print("생성됨!")
        return CollectionID(1)
    }
}
