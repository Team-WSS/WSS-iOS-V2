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

    var body: some View {
        VStack(spacing: 0) {
            header

            if totalCount > 0 {
                Spacer().frame(height: 16)
                previewRow
            }
        }
        .padding(.horizontal, 20)
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

    // Figma는 justify-between(양끝 정렬, 3개 기준 균등 분배)이라 각 항목을 동일폭 슬롯에 leading
    // 정렬해 흉내낸다 — 정확한 간격 수치는 확인 필요(`UserPageFeature/CLAUDE.md` 참고).
    private var previewRow: some View {
        HStack(spacing: 0) {
            ForEach(previews, id: \.id) { preview in
                collectionItem(imageURL: preview.representativeNovel.thumbnailImage, title: preview.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
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
