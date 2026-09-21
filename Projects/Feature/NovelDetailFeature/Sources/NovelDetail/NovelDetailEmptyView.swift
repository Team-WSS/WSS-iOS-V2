//
//  NovelDetailEmptyView.swift
//  NovelDetailFeature
//
//  Created by YunhakLee on 7/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

/// 이 화면 전용 빈 상태(고양이 + 문구). WSSComponent의 `WSSEmptyView`는 검색 빈 상태
/// 전용(고정 문구·버튼 필수)이라 재사용하지 않고 화면 폴더에 둔다.
struct NovelDetailEmptyView: View {

    let message: String

    var body: some View {
        VStack(spacing: 0) {
            WSSImage.imgEmptyCatEyes.swiftUIImage
            Spacer().frame(height: 11)
            Text(message)
                .applyWSSFont(.body2)
                .foregroundStyle(Color.wssGray200)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
