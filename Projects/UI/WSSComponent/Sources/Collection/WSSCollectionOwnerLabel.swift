//
//  WSSCollectionOwnerLabel.swift
//  WSSComponent
//
//  Created by Guryss on 9/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

/// 컬렉션 카드 하단의 작성자 표시 — "{닉네임}님의 컬렉션". 홈 컬렉션 섹션과 전체 컬렉션뷰(#283)가 함께 쓴다.
/// 탭 동작은 없다(사용자 확정 2026-09-28 — 카드 전체가 컬렉션 상세로 가는 버튼이다).
public struct WSSCollectionOwnerLabel: View {

    private let nickname: String
    private let profileImage: URL?

    public init(nickname: String, profileImage: URL?) {
        self.nickname = nickname
        self.profileImage = profileImage
    }

    private enum Metric {
        static let imageSize: CGFloat = 16
        static let imageCornerRadius: CGFloat = 4
        static let spacing: CGFloat = 4
    }

    public var body: some View {
        HStack(spacing: 0) {
            WSSProfileImage(url: profileImage)
                .frame(width: Metric.imageSize, height: Metric.imageSize)
                .clipShape(RoundedRectangle(cornerRadius: Metric.imageCornerRadius))

            Spacer().frame(width: Metric.spacing)

            Text("\(nickname)님의 컬렉션")
                .applyWSSFont(.label2, color: .wssGray200)
                .lineLimit(1)
        }
    }
}
