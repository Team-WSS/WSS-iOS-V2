//
//  MyFeedFilterSheet.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem
import WSSComponent
import BaseDomain
import FeedDomain
import ProfileDomain

struct MyFeedFilterSheet: View {

    let viewModel: SosoFeedViewModel
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("글 찾기 필터")
                    .applyWSSFont(.body2)
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    WSSImage.icCancelModal.swiftUIImage
                        .frame(height: 65)
                }
            }

            categorySection

            Spacer()
                .frame(height: 36)

            isPublicSection

            Spacer()
                .frame(height: 33)

            WSSCTAButton(title: "해당하는 글 보기",
                         action: {
                             viewModel.handle(.applyMyFeedFilter)
                             dismiss()
                         })
            .padding(.vertical, 10)

            Spacer()
        }
        .padding(.horizontal, 20)
        .onAppear {
            viewModel.handle(.resetMyFeedFilterDraft)
        }
    }

    //MARK: - 카테고리

    private var categorySection: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text("카테고리")
                    .applyWSSFont(.title2)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

                FlowLayout(horizontalSpacing: 6, verticalSpacing: 12) {
                    ForEach(NovelGenre.myFeedFilter, id: \.displayName) { genre in
                        CapsuleSelectableKeywordChip(
                            keyword: genre.displayName,
                            isSelected: viewModel.isMyFeedFilterGenreSelected(genre),
                            action: { viewModel.handle(.toggleMyFeedFilterGenre(genre)) }
                        )
                    }
                }
            }
            Spacer()
        }
    }

    //MARK: - 공개여부

    @ViewBuilder
    private func isPublicRow(
        icon: Image,
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 0) {
            icon
                .renderingMode(.template)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)

            Spacer().frame(width: 10)

            Text(title)
                .applyWSSFont(.body2)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)

            Spacer()

            ZStack {
                WSSImage.icSelectNovelDefault.swiftUIImage
                    .opacity(isSelected ? 0 : 1)
                    .scaleEffect(isSelected ? 0.85 : 1)

                WSSImage.icSelectNovelSelected.swiftUIImage
                    .opacity(isSelected ? 1 : 0)
                    .scaleEffect(isSelected ? 1 : 0.6)
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.6), value: isSelected)
        }
        .frame(height: 55)
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }

    private var isPublicSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("공개여부")
                    .applyWSSFont(.title2)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
             Spacer()
            }

            Spacer().frame(height: 10)

            isPublicRow(
                icon: WSSImage.icEye.swiftUIImage,
                title: "공개글",
                isSelected: viewModel.isMyFeedFilterPublicSelected,
                action: { viewModel.handle(.toggleMyFeedFilterPublic) }
            )

            Rectangle()
                .frame(height: 1)
                .foregroundStyle(WSSColor.wssGray50.swiftUIColor)

            isPublicRow(
                icon: WSSImage.icLock.swiftUIImage,
                title: "비공개글",
                isSelected: viewModel.isMyFeedFilterPrivateSelected,
                action: { viewModel.handle(.toggleMyFeedFilterPrivate) }
            )

            Rectangle()
                .frame(height: 1)
                .foregroundStyle(WSSColor.wssGray50.swiftUIColor)
        }
    }
}

private struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 6
    var verticalSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)

        let totalHeight = rows.reduce(0) { $0 + $1.height }
            + verticalSpacing * CGFloat(max(rows.count - 1, 0))
        let widestRow = rows.map(\.width).max() ?? 0
        return CGSize(width: min(maxWidth, widestRow), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let subview = subviews[index]
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y),
                              anchor: .topLeading,
                              proposal: ProposedViewSize(size))
                x += size.width + horizontalSpacing
            }
            y += row.height + verticalSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            var current = rows[rows.count - 1]
            let projectedWidth = current.indices.isEmpty
                ? size.width
                : current.width + horizontalSpacing + size.width

            if projectedWidth > maxWidth, !current.indices.isEmpty {
                rows.append(Row(indices: [index], width: size.width, height: size.height))
            } else {
                current.indices.append(index)
                current.width = projectedWidth
                current.height = max(current.height, size.height)
                rows[rows.count - 1] = current
            }
        }
        return rows
    }
}

#Preview {
    MyFeedFilterSheet(
        viewModel: SosoFeedViewModel(
            loadMyFeedsUseCase: PreviewLoadMyFeedsUseCaseForSheet(),
            loadsosoFeedsUseCase: PreviewLoadSosoFeedsUseCaseForSheet(),
            feedLikeUseCase: PreviewFeedLikeUseCaseForSheet(),
            loadProfileUseCase: PreviewLoadProfileUseCaseForSheet()
        ),
        dismiss: { print("닫기 버튼") }
    )
}

private struct PreviewLoadMyFeedsUseCaseForSheet: LoadMyFeedsUseCase {
    func execute(option: MyFeedOption,
                 lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
        Paginated(items: [], hasNext: false)
    }
}

private struct PreviewLoadSosoFeedsUseCaseForSheet: LoadSosoFeedsUseCase {
    func execute(option: SosoFeedOption,
                 lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
        Paginated(items: [], hasNext: false)
    }
}

private struct PreviewFeedLikeUseCaseForSheet: FeedLikeUseCase {
    func like(feedID: FeedID) async throws(RepositoryError) { }
    func unlike(feedID: FeedID) async throws(RepositoryError) { }
}

private struct PreviewLoadProfileUseCaseForSheet: LoadProfileUseCase {
    func execute(target: ProfileTarget) async throws(RepositoryError) -> Profile {
        Profile(nickname: "미리보기", introduction: "", characterImage: nil, isPublic: true, genrePreferences: [])
    }
}
