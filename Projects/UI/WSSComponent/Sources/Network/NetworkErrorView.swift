//
//  NetworkErrorView.swift
//  WSSComponent
//
//  Created by WonsunLee on 5/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

public struct NetworkErrorView: View {
    public let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 41) {
            WSSImage.imgEmptyCatQuestionmark.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 166, height: 160)

            VStack(spacing: 10) {
                Text("네트워크 연결에\n실패했어요")
                    .applyWSSFont(.title1, color: .wssBlack)

                Text("연결 상태를 확인한 후\n다시 시도해 보세요")
                    .applyWSSFont(.body2, color: .wssGray300)
            }

            Button(action: action) {
                Text("페이지 다시 불러오기")
                    .applyWSSFont(.label1, color: .wssWhite)
                    .padding(.horizontal, 37)
                    .padding(.vertical, 14)
                    .background(Color.wssPrimary100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.wssWhite)
    }
}

#Preview {
    NetworkErrorView(action: {
        print("페이지 다시 불러오기 버튼 클릭")
    })
}
