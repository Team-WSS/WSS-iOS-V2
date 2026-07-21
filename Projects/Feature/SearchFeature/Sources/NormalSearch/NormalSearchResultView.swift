//
//  NormalSearchResultView.swift
//  SearchFeature
//
//  Created by Seoyeon Choi on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NovelDomain
import DesignSystem
import WSSComponent

struct NormalSearchResultView: View {

    @Environment(\.openURL) private var openURL

    let novels: [Novel]
    let resultCount: Int
    let isLoading: Bool
    let hasLoadError: Bool
    let isLoadingMore: Bool
    let onLoadMore: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            resultContent
        }
    }

    @ViewBuilder
    private var resultContent: some View {
        if isLoading {
            LoadingView()
        } else if hasLoadError {
            NetworkErrorView(action: onRetry)
        } else if novels.isEmpty {
            Spacer()
            WSSEmptyView(type: .novel,
                         action: {
                if let url = AppURL.inquiryAddNovel { openURL(url) }
            })
            Spacer()
        } else {
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    topBarSection
                    
                    Spacer().frame(height: 16)
                    
                    ForEach(novels, id: \.id) { novel in
                        NormalSearchResultItemRow(novel: novel)
                            // 무한스크롤 — 마지막 행이 화면에 보이는 순간 다음 페이지 요청(중복 방지는 VM 가드가 담당).
                            .onAppear {
                                if novel.id == novels.last?.id { onLoadMore() }
                            }

                        Spacer().frame(height: 6)
                    }

                    if isLoadingMore {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
            }
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .contentMargins(.top, 9, for: .scrollContent)
            .contentMargins(.bottom, 20)
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private var topBarSection: some View {
        HStack(spacing: 0) {
            Text("작품")
                .applyWSSFont(.title1)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

            Spacer().frame(width: 5)

            Text("\(resultCount)")
                .applyWSSFont(.body4)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)

            Spacer()

            Button {
                if let url = AppURL.inquiryAddNovel { openURL(url) }
            } label: {
                Text("찾는 작품이 없다면?")
                    .applyWSSFont(.body4)
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                    .underline()
            }
        }
    }
}

#Preview {
    NormalSearchResultView(
        novels: [
            Novel(id: NovelID(1),
                  thumbnailImage: URL(string: "https://i.pinimg.com/736x/df/8b/fc/df8bfc3d40960397f79fd119b88d35a3.jpg"),
                  title: "나의 철벽 때문에 계약 남편이 미치려 한다고요?",
                  authors: ["하루다"],
                  genres: [],
                  interestCount: 8,
                  rating: 4.9,
                  ratingCount: 2,
                  isInterested: false)
        ],
        resultCount: 1,
        isLoading: false,
        hasLoadError: false,
        isLoadingMore: false,
        onLoadMore: { },
        onRetry: { }
    )
}
