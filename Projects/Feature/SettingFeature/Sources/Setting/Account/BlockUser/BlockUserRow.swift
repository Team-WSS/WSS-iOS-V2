//
//  BlockUserRow.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import SocialDomain
import DesignSystem
import WSSComponent

struct BlockUserRow: View {
    let user: BlockedUser
    let isUnblocking: Bool
    let onUnblock: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                WSSProfileImage(url: user.profileImageURL, contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                Spacer().frame(width: 14)

                Text(user.nickname)
                    .applyWSSFont(.body2)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

                Spacer()

                Button(action: onUnblock) {
                    if isUnblocking {
                        ProgressView()
                    } else {
                        Text("차단 해제")
                            .applyWSSFont(.body3)
                            .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                    }
                }
                .disabled(isUnblocking)
                .buttonStyle(.plain)
                .padding(.vertical, 7)
                .padding(.horizontal, 13)
                .background(WSSColor.wssGray50.swiftUIColor)
                .clipShape(Capsule())
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)

            Rectangle()
                .frame(height: 1)
                .foregroundStyle(WSSColor.wssGray50.swiftUIColor)
        }
    }
}

#Preview {
    BlockUserRow(
        user: BlockedUser(
            blockID: BlockID(1),
            userID: UserID(1),
            nickname: "구리스",
            profileImageURL: nil
        ),
        isUnblocking: false,
        onUnblock: {}
    )
}
