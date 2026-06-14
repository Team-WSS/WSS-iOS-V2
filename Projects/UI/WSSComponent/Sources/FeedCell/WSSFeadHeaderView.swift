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
    public let showThreeDotsButton: Bool
    public let threeDotsButtonTapped: () -> Void

    public init(
        header: FeedHeader,
        profileImageTapped: @escaping () -> Void,
        showThreeDotsButton: Bool = true,
        threeDotsButtonTapped: @escaping () -> Void = { }
    ) {
        self.header = header
        self.profileImageTapped = profileImageTapped
        self.showThreeDotsButton = showThreeDotsButton
        self.threeDotsButtonTapped = threeDotsButtonTapped
    }

    public var body: some View {
        HStack(spacing: 0) {
            // 프로필 진입 영역 = 이미지 + 간격 + 닉네임 전체 — 이미지(32pt)만으론 탭 타겟이 좁다.
            // 간격의 투명 픽셀까지 탭되도록 contentShape 필수.
            HStack(spacing: 0) {
                AsyncImage(url: header.profileImageURL) {
                    phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                    case .failure:
                        WSSImage.imgLoadingThumbnail.swiftUIImage
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
            }
            .contentShape(Rectangle())
            .onTapGesture {
                profileImageTapped()
            }
            // 순수 이미지·텍스트 + 제스처라 접근성 트리에 안 잡힌다 — VoiceOver·UI 자동화가 버튼 하나로 인식하게 한다.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(header.nickname) 프로필")
            .accessibilityAddTraits(.isButton)

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
