//
//  CollectionSection.swift
//  UserPageFeature
//
//  Created by Guryss on 8/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import CollectionDomain
import DesignSystem
import WSSComponent

/// 마이페이지 컬렉션 섹션 — "컬렉션 N개" 헤더 행(탭하면 목록 화면으로 이동) + 개수가 1 이상이면
/// 그 아래 최대 3개의 미리보기(대표 표지 1장씩). `LibrarySection.swift`와 같은 이유로
/// `MypageView.swift`에서 분리했다(화면 파일이 계속 길어지는 걸 막기 위함, 재사용처는 없다).
struct CollectionSection: View {

    let previews: [CollectionPreview]
    let totalCount: Int
    let action: () -> Void

    private enum Metric {
        /// 미리보기 항목 사이 간격(사용자 확정, 2026-08-21) — 화면 폭 기준 역산 대신 고정값으로 정했다.
        static let previewItemSpacing: CGFloat = 30
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)

            if totalCount > 0 {
                Spacer().frame(height: 16)
                previewRow
            }
        }
    }

    private var header: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Text("컬렉션 ")
                    .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                Text("\(totalCount)개")
                    .foregroundStyle(WSSColor.wssPrimary100.swiftUIColor)

                Spacer()

                WSSImage.icNavigateRight.swiftUIImage
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                    .frame(width: 24, height: 24)
            }
            .applyWSSFont(.title2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 항목 사이 간격은 고정 30 — 화면 폭에 맞춰 정확히 맞추는 시도(역산 간격)를 걷어내고 단순
    /// 고정값으로 정리했다(사용자 확정, 2026-08-21). 좌우 여백을 신경 쓰는 대신, **묶음 전체를 화면
    /// 가운데 정렬**한다(사용자 확정) — `HStack`은 내용물(고정폭 항목 3개+간격) 크기만큼만 차지하고,
    /// 그 바깥 `.frame(maxWidth: .infinity)`가 화면 전체 폭을 차지해 기본 정렬(`.center`)로 가운데
    /// 놓는다. 헤더 행의 좌측 정렬 20pt 패딩과는 별개 레이아웃이라 이 행에는 적용하지 않는다.
    private var previewRow: some View {
        HStack(spacing: Metric.previewItemSpacing) {
            ForEach(previews, id: \.id) { preview in
                collectionItem(imageURL: preview.representativeNovel.thumbnailImage, title: preview.name)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func collectionItem(imageURL: URL?, title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 6.57)
                    .fill(WSSColor.wssGrayToast.swiftUIColor)
                    .offset(x: 14)
                    .frame(width: 73, height: 108)

                RoundedRectangle(cornerRadius: 6.57)
                    .fill(WSSColor.wssGray80.swiftUIColor)
                    .offset(x: 7)
                    .frame(width: 73, height: 108)

                // 크기 고정 자리라 aspectRatio 없이 .frame으로 직접 크기를 준다(`WSSComponent/CLAUDE.md`
                // 정본 패턴). 원래 죽은 코드는 raw `AsyncImage`를 썼는데, URL이 nil이면 `.empty` phase에서
                // 영영 못 벗어나 `ProgressView()`가 멈추지 않고 계속 돈다 — 이 섹션을 되살리며 함께 고쳤다.
                WSSNovelCoverImage(url: imageURL)
                    .frame(width: 73, height: 108)
                    .clipShape(RoundedRectangle(cornerRadius: 6.57))
            }
            .shadow(color: Color.black.opacity(0.1), radius: 12.68, x: 0, y: 1)

            Text(title)
                .applyWSSFont(.body5)
                .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                .lineLimit(1)
        }
        .frame(width: 88)
    }
}
