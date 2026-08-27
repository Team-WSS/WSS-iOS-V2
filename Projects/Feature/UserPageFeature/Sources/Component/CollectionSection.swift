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

/// 마이페이지 컬렉션 섹션 — "컬렉션 N개" 헤더 행(탭하면 목록 화면으로 이동) + 개수가 1 이상이면
/// 그 아래 최대 3개의 미리보기(`CollectionPreviewRow` 재사용, `UserPageView`의 컬렉션 섹션과 공유).
/// `LibrarySection.swift`와 같은 이유로 `MypageView.swift`에서 분리했다(화면 파일이 계속 길어지는 걸
/// 막기 위함, 재사용처는 없다).
struct CollectionSection: View {

    let previews: [CollectionPreview]
    let totalCount: Int
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)

            if totalCount > 0 {
                Spacer().frame(height: 16)
                CollectionPreviewRow(previews: previews)
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
}
