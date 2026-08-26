//
//  CreateFeedConnectNovelSheet.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import DesignSystem
import WSSComponent

struct CreateFeedConnectNovelSheet: View {
    @Binding var searchText: String
    let novels: [Novel]
    let selectedNovelID: NovelID?
    let isLoading: Bool
    /// 현재 `searchText`로 검색이 **실제로 완료**됐는지 — VM(`CreateFeedViewModel.state.hasSearchedNovel`)이
    /// 소유한다(뷰가 자체 `@State`로 들면 텍스트 편집 시 끄는 걸 잊기 쉽다 — 실제로 겪었던 문제,
    /// `CollectionFeature/CLAUDE.md` 참고).
    let hasSearched: Bool
    let isLoadingMore: Bool
    let onSearch: () -> Void
    let onLoadMore: () -> Void
    let onSelect: (Novel) -> Void
    let onConfirm: () -> Void
    let inquiryNovelAction: () -> Void
    let dismissSheet: () -> Void

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            Button {
                dismissSheet()
            } label: {
                WSSImage.icCancelModal.swiftUIImage
                    .frame(width: 65, height: 65)
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
                isFocused: $isSearchFocused,
                onSearch: onSearch
            )

            Spacer().frame(height: 20)

            // `!hasSearched`면 무조건 빈 화면(흰 배경)이다 — 타이핑 도중이거나(검색 미실행), x 버튼으로
            // 텍스트를 비운 직후, 또는 결과를 받은 뒤 다시 타이핑하는 도중엔 `novels` 배열이 이전 값을
            // 그대로 들고 있을 수 있어 그 배열 유무만으론 판단하지 않는다(`CollectionFeature/CLAUDE.md`의
            // `AddNovelViewModel` 항목과 동일 함정).
            ZStack {
                if isLoading {
                    LoadingView()
                } else if !hasSearched {
                    Spacer()
                } else if novels.isEmpty {
                    WSSEmptyView(type: .novel,
                                 action: { inquiryNovelAction() })
                } else {
                    novelList
                }
            }
        }
        .padding(.horizontal, 20)
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchFocused = false
        }
        .onAppear {
            isSearchFocused = true
        }

        if selectedNovelID != nil {
            WSSCTAButton(
                title: "해당 작품 연결",
                action: onConfirm
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private var novelList: some View {
        ScrollView {
            // ⚠️ 무한스크롤 `onAppear` 감지는 `LazyVStack`(non-lazy `VStack`이면 스크롤 없이 전체 행이
            // 한꺼번에 나타나 즉시 연쇄 로드된다 — `SearchFeature/CLAUDE.md` 참고)이어야 의미가 있다.
            LazyVStack(spacing: 6) {
                ForEach(novels, id: \.id) { novel in
                    WSSNovelSelectRow(
                        imageURL: novel.thumbnailImage,
                        title: novel.title,
                        author: novel.authors.joined(separator: ", "),
                        isSelected: selectedNovelID == novel.id,
                        action: { onSelect(novel) }
                    )
                    // 마지막 행이 보이는 순간 다음 페이지 요청(중복 방지는 VM 가드가 담당).
                    .onAppear {
                        if novel.id == novels.last?.id { onLoadMore() }
                    }
                }

                if isLoadingMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.immediately)
        // 상위 `VStack`의 배경 탭 제스처는 이 `ScrollView` 내부(특히 빈 여백)까지는 안 먹는다 —
        // `ScrollView`가 그 터치를 자기 것으로 가져가버린다(`SearchFeature/CLAUDE.md`의 자동완성 항목과
        // 동일 함정). 그래서 이 스크롤뷰 자신에도 같은 제스처를 직접 건다 — 행 위를 탭하면
        // `WSSNovelSelectRow`의 자체 탭 액션이 먼저 소비하므로 서로 충돌하지 않는다.
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchFocused = false
        }
    }
}

#Preview {
    CreateFeedConnectNovelSheet(
        searchText: .constant(""),
        novels: [],
        selectedNovelID: nil,
        isLoading: false,
        hasSearched: false,
        isLoadingMore: false,
        onSearch: { },
        onLoadMore: { },
        onSelect: { _ in },
        onConfirm: { },
        inquiryNovelAction: { },
        dismissSheet: { }
    )
}
