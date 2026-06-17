//
//  CreateFeedConnectNovelSheet.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NovelDomain
import DesignSystem
import WSSComponent

struct CreateFeedConnectNovelSheet: View {
    @Binding var searchText: String
    let novels: [Novel]
    let selectedNovelID: NovelID?
    let isLoading: Bool
    let onSearch: () -> Void
    let onSelect: (Novel) -> Void
    let onConfirm: () -> Void
    let dismissSheet: () -> Void

    var body: some View {
        HStack {
            Spacer()
            WSSImage.icCancelModal.swiftUIImage
                .frame(width: 65, height: 65)
                .onTapGesture {
                    dismissSheet()
                }
        }
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("작품 연결하기")
                        .applyWSSFont(.title1)
                        .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

                    Spacer().frame(height: 4)

                    Text("작성 중인 글과 관련된 웹소설을 선택하세요")
                        .applyWSSFont(.body2)
                        .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                }

                Spacer()
            }

            Spacer().frame(height: 33)

            WSSSearchBar(
                text: $searchText,
                placeholder: "",
                onSearch: onSearch
            )

            Spacer().frame(height: 20)

            ZStack {
                if isLoading {
                    LoadingView()
                } else if novels.isEmpty {
                    emptyView
                } else {
                    novelList
                }
            }
        }
        .padding(.horizontal, 20)

        if selectedNovelID != nil {
            WSSCTAButton(
                title: "해당 작품 연결",
                action: onConfirm
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private var emptyView: some View {
        VStack {
            Text("")
                .applyWSSFont(.body2)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var novelList: some View {
        ScrollView {
            VStack(spacing: 6) {
                ForEach(novels, id: \.id) { novel in
                    CreateFeedConnectNovelRow(
                        imageURL: novel.thumbnailImage,
                        title: novel.title,
                        author: novel.authors.joined(separator: ", "),
                        isSelected: selectedNovelID == novel.id,
                        action: { onSelect(novel) }
                    )
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }
}

#Preview {
    CreateFeedConnectNovelSheet(
        searchText: .constant("안녕"),
        novels: [Novel(
            id: NovelID(2),
            thumbnailImage: URL(string: "https://i.pinimg.com/736x/12/49/04/124904e3933472601d83f8ff771def50.jpg"),
            title: "멸망한 세계의 검신",
            authors: ["이판타지"],
            genres: [],
            interestCount: 8932,
            rating: 4.6,
            ratingCount: 1875
        ),
        Novel(
            id: NovelID(3),
            thumbnailImage: URL(string: "https://i.pinimg.com/736x/fc/11/ed/fc11ed1b94cc32feefc9e40f1b2d8f65.jpg"),
            title: "재벌집 막내아들",
            authors: ["산경"],
            genres: [],
            interestCount: 25431,
            rating: 4.9,
            ratingCount: 10234
        ),],
        selectedNovelID: nil,
        isLoading: false,
        onSearch: { },
        onSelect: { _ in },
        onConfirm: { },
        dismissSheet: { }
    )
}
