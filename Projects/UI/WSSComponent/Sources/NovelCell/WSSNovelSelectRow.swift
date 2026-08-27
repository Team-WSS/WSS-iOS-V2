//
//  WSSNovelSelectRow.swift
//  WSSComponent
//
//  Created by Guryss on 8/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

/// 작품 검색 결과를 고르는 행(표지 + 제목/작가 + 선택 아이콘) — `FeedFeature`의 연결 작품 검색(단일선택)과
/// `CollectionFeature`의 작품 추가(다중선택)가 완전히 같은 룩을 쓰게 돼 공용화했다(#199, `CreateFeedConnectNovelRow`
/// 원본). 단일/다중 선택 정책은 이 컴포넌트가 모른다 — `isSelected`/`action`만 받고 그 의미는 호출부가 정한다.
public struct WSSNovelSelectRow: View {

    let imageURL: URL?
    let title: String
    let author: String
    let isSelected: Bool
    let action: () -> Void

    public init(
        imageURL: URL?,
        title: String,
        author: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.imageURL = imageURL
        self.title = title
        self.author = author
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        HStack(spacing: 0) {
            // 원본(CreateFeedConnectNovelRow)은 raw AsyncImage를 썼다 — 목록 반복 렌더에선 재사용 시
            // placeholder가 번쩍이는 문제가 있어(WSSComponent/CLAUDE.md) 승격하며 WSSNovelCoverImage로 교체.
            // 크기가 고정인 자리라 `aspectRatio` 파라미터는 넘기지 않는다(둘 다 주면 밖에서 또 걸지
            // 말라는 컴포넌트 계약과 충돌 — WSSComponent/CLAUDE.md).
            WSSNovelCoverImage(url: imageURL)
                .frame(width: 78, height: 105)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer().frame(width: 18)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .applyWSSFont(.title3)
                    .foregroundStyle(Color.wssBlack)
                    .lineLimit(1)

                Text(author)
                    .applyWSSFont(.body5)
                    .foregroundStyle(Color.wssGray200)
                    .lineLimit(1)
            }

            Spacer()

            WSSSelectionCheckIcon(isSelected: isSelected)
                .frame(width: 44, height: 44)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var isSelected: Bool = false

    WSSNovelSelectRow(
        imageURL: nil,
        title: "여주인공의 이해를 돕기 위하여",
        author: "이보라",
        isSelected: isSelected,
        action: { isSelected.toggle() }
    )
    .padding(.horizontal, 20)
}
