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
        
        _selectedIndex = State(initialValue: nil)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                default:
                                    ProgressView()
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .containerRelativeFrame(.horizontal)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $selectedIndex)
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
            
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
        .onAppear {
            selectedIndex = initialIndex
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
