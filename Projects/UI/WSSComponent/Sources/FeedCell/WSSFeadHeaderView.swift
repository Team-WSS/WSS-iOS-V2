//
//  WSSFeadHeaderView.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import SwiftUI
import DesignSystem

//MARK: - Feed Header 구조체

public struct FeedHeader {
    public let profileImageURL: URL?
    public let nickname: String
    public let createdDate: String
    public let isEdited: Bool

    public init(
        profileImageURL: URL?,
        nickname: String,
        createdDate: String,
        isEdited: Bool
    ) {
        self.profileImageURL = profileImageURL
        self.nickname = nickname
        self.createdDate = createdDate
        self.isEdited = isEdited
    }
}

// MARK: - Feed Header 뷰

public struct WSSFeadHeaderView: View {

    let header: FeedHeader

    public let profileImageTapped: () -> Void
    /// 내 글이면 `false` — 내 프로필로 "이동"할 곳이 없어 이 영역을 탭 타겟으로 만들지 않는다
    /// (`Button` 자체를 안 그려서, 탭이 그대로 아래 컨테이너로 흘러가 일반 셀 탭과 동일하게 동작한다).
    public let isProfileTappable: Bool
    public let showThreeDotsButton: Bool
    public let threeDotsButtonTapped: () -> Void

    public init(
        header: FeedHeader,
        profileImageTapped: @escaping () -> Void,
        isProfileTappable: Bool = true,
        showThreeDotsButton: Bool = true,
        threeDotsButtonTapped: @escaping () -> Void = { }
    ) {
        self.header = header
        self.profileImageTapped = profileImageTapped
        self.isProfileTappable = isProfileTappable
        self.showThreeDotsButton = showThreeDotsButton
        self.threeDotsButtonTapped = threeDotsButtonTapped
    }

    public var body: some View {
        HStack(spacing: 0) {
            // 프로필 진입 영역 = 이미지 + 간격 + 닉네임 전체 — 이미지(32pt)만으론 탭 타겟이 좁다.
            if isProfileTappable {
                // 실제 `Button`이어야 셀 행 컨테이너의 `onTapGesture`(피드 상세 진입)보다 이 영역이
                // 우선한다(WSSComponent/CLAUDE.md "Button은 조상의 onTapGesture보다 우선" — 예전엔
                // 이 영역도 onTapGesture였는데, 행 전체가 simultaneousGesture이던 시절엔 공존했지만
                // 행을 일반 onTapGesture로 바꾸면서 Button으로 승격해야 눌림이 행 탭에 먹히지 않는다).
                Button(action: profileImageTapped) {
                    profileContent
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(header.nickname) 프로필")
            } else {
                // Button을 아예 안 그려서 탭이 컨테이너(피드 상세 진입)로 그대로 흘러간다 — 여기서
                // .disabled()로 막으면 Button이 히트테스트를 계속 가로채 아래로 안 흘러간다.
                profileContent
            }

            Spacer().frame(width: 4)

            Circle()
                .frame(width: 2, height: 2)
                .foregroundColor(Color.wssGray200)
                .frame(width: 8, height: 8)

            Spacer().frame(width: 4)

            Text(header.createdDate)
                .applyWSSFont(.body5)
                .foregroundStyle(Color.wssGray200)

            Spacer().frame(width: 4)

            if (header.isEdited) {
                Text("(수정됨)")
                    .applyWSSFont(.body5)
                    .foregroundStyle(Color.wssGray200)
            }

            Spacer()

            if showThreeDotsButton {
                Button {
                    threeDotsButtonTapped()
                } label: {
                    WSSImage.icThreedots.swiftUIImage
                        .renderingMode(.template)
                        .foregroundStyle(WSSColor.wssGray100.swiftUIColor)
                        .frame(width: 32, height: 32, alignment: .trailing)
                }
                // 위 프로필 이미지와 같은 이유의 접근성 보완.
                .accessibilityLabel("더보기")
                .accessibilityAddTraits(.isButton)
            }
        }
        .background(Color.wssWhite)
    }

    private var profileContent: some View {
        HStack(spacing: 0) {
            AsyncImage(url: header.profileImageURL) {
                phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                case .failure:
                    WSSColor.wssGray200.swiftUIColor
                default:
                    ProgressView()
                }
            }
            .scaledToFit()
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Spacer().frame(width: 10)

            Text(header.nickname)
                .applyWSSFont(.body4)
                .foregroundStyle(Color.wssBlack)
                .lineLimit(1)
        }
        // 간격의 투명 픽셀까지 탭되도록 contentShape 필수 — isProfileTappable == false일 때도
        // 이 영역이 컨테이너의 onTapGesture 히트테스트에 포함되게 한다(빈 공간이 죽지 않도록).
        .contentShape(Rectangle())
    }
}

#Preview {
    WSSFeadHeaderView(
        header: FeedHeader(
            profileImageURL: URL(string: "https://i.pinimg.com/736x/fd/fc/ef/fdfcefdd9bc7d69e9adf1dde8293fe6e.jpg"),
            nickname: "구리스",
            createdDate: "2024년 6월 19일",
            isEdited: true
        ),
        profileImageTapped: { }
    )
}
