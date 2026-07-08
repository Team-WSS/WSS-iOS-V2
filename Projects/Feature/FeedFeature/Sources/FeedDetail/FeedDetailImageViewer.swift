//
//  FeedDetailImageViewer.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/12/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

/// 첨부 이미지 확대 뷰. 탭한 이미지부터 시작해 페이지 스와이프로 다른 첨부 이미지도 볼 수 있다.
struct FeedDetailImageViewer: View {
    
    let imageURLs: [URL?]
    let initialIndex: Int
    @State private var selectedIndex: Int?

    @Environment(\.dismiss) private var dismiss

    init(imageURLs: [URL?], initialIndex: Int) {
        self.imageURLs = imageURLs
        self.initialIndex = initialIndex
        self._selectedIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                            imageView(url: url)
                                .containerRelativeFrame(.horizontal)
                                .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $selectedIndex)
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
                .onAppear {
                    // scrollPosition(id:)의 초깃값 반영은 fullScreenCover 등장 전환 중엔 무시되는
                    // 경우가 있다(최초 진입에서만 재현). ScrollViewReader.scrollTo는 UIScrollView에
                    // 직접 오프셋을 지시하는 명령형 API라 전환 중에도 더 확실히 반영된다.
                    guard initialIndex != 0 else { return }
                    proxy.scrollTo(initialIndex, anchor: .leading)
                }
            }

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Button {
                        dismiss()
                    } label: {
                        WSSImage.icCancelModal.swiftUIImage
                            .renderingMode(.template)
                            .foregroundStyle(WSSColor.wssWhite.swiftUIColor)
                            .frame(width: 44, height: 44)
                    }
                    .padding(.top, 1)
                    .padding(.leading, 6)
                    
                    Spacer()
                }

                Spacer()
            }
            
            VStack(spacing: 0) {
                Text("\((selectedIndex ?? initialIndex) + 1) / \(imageURLs.count)")
                    .applyWSSFont(.title2)
                    .foregroundStyle(WSSColor.wssWhite.swiftUIColor)
                    .padding(.top, 12)
                
                Spacer()
            }
        }
    }
    
    private func imageView(url: URL?) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                
            case .failure:
                WSSImage.imgLoadingThumbnail.swiftUIImage
                    .resizable()
                    .scaledToFit()
                
            default:
                ProgressView()
                    .tint(WSSColor.wssWhite.swiftUIColor)
            }
        }
    }
}

#Preview {
    FeedDetailImageViewer(
        imageURLs: [
            URL(string: "https://i.pinimg.com/1200x/a7/41/22/a74122c74fab445033dcc8b3544f5dd1.jpg"),
            URL(string: "https://i.pinimg.com/1200x/1b/24/4f/1b244f2796bc860e9ffe1e8f9162ce7c.jpg"),
            URL(string: "https://i.pinimg.com/736x/41/ad/4b/41ad4bc22cf862de46e376d265df9c91.jpg")
        ],
        initialIndex: 1
    )
}
