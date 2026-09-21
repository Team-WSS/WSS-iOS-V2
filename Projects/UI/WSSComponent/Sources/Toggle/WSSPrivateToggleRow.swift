//
//  WSSPrivateToggleRow.swift
//  WSSComponent
//
//  Created by Guryss on 8/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

/// "나만 보기" 류 공개범위 토글 줄(자물쇠 아이콘 + 라벨 + 토글) — 어두운 배경(`wssGray300`) 위 흰 텍스트.
/// 피드 작성(`FeedFeature`의 "나만 보는 기록")과 컬렉션 생성(`CollectionFeature`의 "나만 보는 컬렉션")이
/// 완전히 같은 룩·규격(자물쇠 18×18 + `title3` + 높이 58 + 좌우 패딩 20)이라 공용 컴포넌트로 승격했다 —
/// 라벨 문구만 화면마다 다르므로 그 값만 파라미터로 받는다.
public struct WSSPrivateToggleRow: View {

    @Binding private var isOn: Bool
    private let label: String

    public init(label: String, isOn: Binding<Bool>) {
        self.label = label
        self._isOn = isOn
    }

    public var body: some View {
        HStack(spacing: 0) {
            WSSImage.icLock.swiftUIImage
                .frame(width: 18, height: 18)
                .foregroundStyle(Color.wssGray50)

            Spacer().frame(width: 4)

            Text(label)
                .applyWSSFont(.title3)
                .foregroundStyle(Color.wssGray50)

            Spacer()

            WSSToggleButton(isOn: $isOn)
        }
        .padding(.horizontal, 20)
        .frame(height: 58)
        .background(Color.wssGray300)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var isPrivate = false

    WSSPrivateToggleRow(label: "나만 보는 기록", isOn: $isPrivate)
}
