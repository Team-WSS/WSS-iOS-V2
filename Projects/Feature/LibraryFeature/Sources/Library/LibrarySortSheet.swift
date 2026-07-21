//
//  LibrarySortSheet.swift
//  LibraryFeature
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import NovelDomain
import DesignSystem
import WSSComponent

// 정렬 선택 바텀시트 — 6종 중 단일 선택. 선택 즉시 부모가 dismiss + 재로드한다.
struct LibrarySortSheet: View {

    let selected: LibrarySortType
    let onSelect: (LibrarySortType) -> Void

    static let sheetHeight: CGFloat = 24 + 6 * 39 + 5 * 10 + 24

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)
            VStack(spacing: 10) {
                ForEach(LibrarySortType.allCases, id: \.self) { sortType in
                    row(sortType)
                }
            }
            Spacer()
        }
    }

    private func row(_ sortType: LibrarySortType) -> some View {
        let isSelected = sortType == selected
        return Button {
            onSelect(sortType)
        } label: {
            HStack(spacing: 4) {
                if isSelected {
                    WSSImage.icCheckMark.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                }
                Text(sortType.libraryDisplayName)
                    .applyWSSFont(.body2, color: isSelected ? .wssBlack : .wssGray200)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 39)
            .background(isSelected ? Color.wssPrimary20 : Color.wssWhite)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Presentation

extension LibrarySortType {
    /// 정렬 시트·메인 정렬 버튼 라벨. (도메인 의미값 → 카피 매핑은 View 몫)
    var libraryDisplayName: String {
        switch self {
        case .registeredNewest: "등록 최신순"
        case .registeredOldest: "등록 오래된순"
        case .title:            "제목순"
        case .readDate:         "날짜순"
        case .ratingHighest:    "별점 높은순"
        case .ratingLowest:     "별점 낮은순"
        }
    }

    /// 메인 화면 정렬 버튼의 축약 라벨 — 디자인은 "최신순"으로 짧게 표기.
    var libraryShortDisplayName: String {
        switch self {
        case .registeredNewest: "최신순"
        case .registeredOldest: "오래된순"
        case .title:            "제목순"
        case .readDate:         "날짜순"
        case .ratingHighest:    "별점 높은순"
        case .ratingLowest:     "별점 낮은순"
        }
    }
}
