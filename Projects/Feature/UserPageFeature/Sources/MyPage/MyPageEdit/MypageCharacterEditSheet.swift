//
//  MypageCharacterEditSheet.swift
//  UserPageFeature
//
//  Created by Seoyeon Choi on 7/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import ProfileDomain
import DesignSystem
import WSSComponent

struct MypageCharacterEditSheet: View {
    @State private var viewModel: MypageCharacterEditSheetViewModel
    @State private var currentPage: Int = 0

    @Environment(\.dismiss) private var dismiss

    /// 확인 결과(선택된 캐릭터 ID)를 부모로 전달. 부모가 draft 반영 + 시트 dismiss를 담당한다.
    private let onApply: (Int) -> Void

    /// 캐릭터 `line`의 "%s" 자리에 채울 사용자 닉네임. 서버가 포맷 문자열로 내려준다.
    private let nickname: String

    private let characterColumnCount = 5
    private let characterRowCount = 2
    private let characterItemSpacing: CGFloat = 12
    private let characterHorizontalPadding: CGFloat = 38
    private let characterRowSpacing: CGFloat = 20

    init(viewModel: MypageCharacterEditSheetViewModel, nickname: String, onApply: @escaping (Int) -> Void) {
        self._viewModel = State(initialValue: viewModel)
        self.nickname = nickname
        self.onApply = onApply
    }

    var body: some View {
        GeometryReader { geo in
            let itemSize = characterItemSize(for: geo.size.width)

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 33)

                        Text("프로필 선택")
                            .applyWSSFont(.title2)
                            .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

                        Spacer().frame(height: 14)

                        thumbnailSection

                        Spacer().frame(height: 35)

                        if let error = viewModel.state.hasLoadError {
                            NetworkErrorView(error: error) { viewModel.handle(.load) }
                                .frame(height: itemSize * CGFloat(characterRowCount) + characterRowSpacing + 18)
                        } else {
                            selectionSection(itemSize: itemSize)
                        }
                    }
                }

                bottomBarSection
            }
        }
        // iPhone SE 등 화면이 작은 기기에서 화면 높이를 넘는 고정값을 요청하면 시트가 찌그러져
        // selectionSection이 잘려 보인다 — 실제 화면 높이 안에서만 잡히도록 위쪽 여백을 두고 clamp한다.
        .presentationDetents([.height(min(680, UIScreen.main.bounds.height - 40))])
        .presentationBackground(WSSColor.wssWhite.swiftUIColor)
        .presentationBackgroundInteraction(.disabled)
        .interactiveDismissDisabled()
        .presentationCornerRadius(16)
        .onAppear {
            viewModel.handle(.load)
        }
    }

    private var thumbnailSection: some View {
        VStack(spacing: 0) {
            WSSProfileImage(url: selectedCharacter?.representativeImage)
                .frame(width: 250, height: 250)

            Spacer().frame(height: 18)

            Text(selectedCharacter?.name ?? "")
                .applyWSSFont(.title1)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

            Spacer().frame(height: 4)

            Text(greetingLine)
                .applyWSSFont(.title3)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
        }
    }

    /// 캐릭터 `line`의 "%s"를 사용자 닉네임으로 치환. `String(format:)`은 "%s"에 C 문자열을 기대해 Swift
    /// `String` 인자와 맞지 않으므로(오동작 소지) 단순 치환으로 처리한다.
    private var greetingLine: String {
        guard let line = selectedCharacter?.line else { return "" }
        return line.replacingOccurrences(of: "%s", with: nickname)
    }

    private func selectionSection(itemSize: CGFloat) -> some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(characterPages.indices, id: \.self) { pageIndex in
                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.fixed(itemSize), spacing: characterItemSpacing),
                            count: characterColumnCount
                        ),
                        spacing: characterRowSpacing
                    ) {
                        ForEach(characterPages[pageIndex], id: \.id) { character in
                            CharacterSelectionCell(
                                imageURL: character.thumbnailImage,
                                isSelected: character.id == viewModel.state.selectedCharacterID,
                                size: itemSize,
                                action: { viewModel.handle(.select(character.id)) }
                            )
                        }
                    }
                    .padding(.horizontal, characterHorizontalPadding)
                    .tag(pageIndex)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: itemSize * CGFloat(characterRowCount) + characterRowSpacing)

            Spacer().frame(height: 12)

            pageIndicator
        }
    }

    private var selectedCharacter: ProfileCharacter? {
        viewModel.state.characters.first { $0.id == viewModel.state.selectedCharacterID }
    }
    
    /// `GeometryReader`가 아주 좁은 폭(예: 시트 프레젠테이션 애니메이션 도중 과도기 프레임)을 보고하면
    /// 결과가 음수가 될 수 있다 — 그대로 `.frame(height:)`/`GridItem(.fixed:)`에 흘러들어가면 SwiftUI가
    /// "Invalid frame dimension (negative or non-finite)" 런타임 이슈를 낸다. 0으로 클램프.
    private func characterItemSize(for width: CGFloat) -> CGFloat {
        let totalSpacing = characterItemSpacing * CGFloat(characterColumnCount - 1)
        return max(0, (width - characterHorizontalPadding * 2 - totalSpacing) / CGFloat(characterColumnCount))
    }

    /// 페이지당 10개(5열×2행)로 나눈 뒤, 각 페이지를 열 우선 순서로 재배치한다.
    private var characterPages: [[ProfileCharacter]] {
        let pageSize = characterColumnCount * characterRowCount
        return stride(from: 0, to: viewModel.state.characters.count, by: pageSize).map {
            let page = Array(viewModel.state.characters[$0..<min($0 + pageSize, viewModel.state.characters.count)])
            return columnMajorOrdered(page)
        }
    }

    /// 서버는 캐릭터를 "왼 위 → 왼 아래 → 오른쪽 위 → 오른쪽 아래"(열 우선) 순서로 내려준다.
    /// `LazyVGrid`는 항목을 행 우선(왼→오, 다음 행)으로 채우므로, 열 우선 소스 순서를 행 우선 배치로
    /// 변환해야 시각적으로 의도한 열 순서가 나온다.
    private func columnMajorOrdered(_ characters: [ProfileCharacter]) -> [ProfileCharacter] {
        var ordered = characters
        for (sourceIndex, character) in characters.enumerated() {
            let row = sourceIndex % characterRowCount
            let column = sourceIndex / characterRowCount
            let gridIndex = row * characterColumnCount + column
            if gridIndex < ordered.count {
                ordered[gridIndex] = character
            }
        }
        return ordered
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(characterPages.indices, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? WSSColor.wssPrimary100.swiftUIColor : WSSColor.wssGray100.swiftUIColor)
                    .frame(width: 6, height: 6)
            }
        }
    }

    private var bottomBarSection: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Text("취소")
                    .applyWSSFont(.title1)
                    .foregroundStyle(Color.wssGray300)
                    .frame(maxWidth: .infinity)
                    .frame(height: 53)
            }
            .background(Color.wssGray70)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            WSSCTAButton(title: "확인", isEnabled: viewModel.state.selectedCharacterID != nil) {
                guard let selectedCharacterID = viewModel.state.selectedCharacterID else { return }
                onApply(selectedCharacterID)
                dismiss()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

private struct CharacterSelectionCell: View {
    let imageURL: URL?
    let isSelected: Bool
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            WSSProfileImage(url: imageURL)
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(WSSColor.wssPrimary100.swiftUIColor, lineWidth: 2)
                        .opacity(isSelected ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        MypageCharacterEditSheet(
            viewModel: MypageCharacterEditSheetViewModel(
                selectedCharacterID: nil,
                loadProfileCharacterUseCase: PreviewLoadProfileCharacterUseCase()
            ),
            nickname: "소소",
            onApply: { _ in }
        )
    }
}

private struct PreviewLoadProfileCharacterUseCase: LoadProfileCharacterUseCase {
    func execute() async throws(RepositoryError) -> [ProfileCharacter] {
        (1...20).map { index in
            ProfileCharacter(
                id: index,
                name: "팬텀 \(index)",
                line: "만나서 반가워요, %s",
                representativeImage: URL(string: "https://i.pinimg.com/736x/5d/c4/68/5dc46859de623b667c4ed3273c99071e.jpg"),
                thumbnailImage: URL(string: "https://i.pinimg.com/736x/5d/c4/68/5dc46859de623b667c4ed3273c99071e.jpg"),
                isRepresentative: index == 1
            )
        }
    }
}
