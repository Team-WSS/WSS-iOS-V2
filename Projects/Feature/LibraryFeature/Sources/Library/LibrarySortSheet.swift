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
// presentation 설정·배경·높이는 이 시트가 자체 보유한다(ReadingPeriodSheet 패턴).
struct LibrarySortSheet: View {

    let selected: LibrarySortType
    let onSelect: (LibrarySortType) -> Void

    private enum Metric {
        static let topPadding: CGFloat = 24
        static let rowHeight: CGFloat = 39
        static let rowSpacing: CGFloat = 10
        static let horizontalPadding: CGFloat = 20
        static let checkSize: CGFloat = 22
        /// 체크와 글씨 사이 간격 — overlay offset에만 쓰인다(글씨 레이아웃엔 영향 없음).
        static let checkGap: CGFloat = 4
    }

    private static let rowCount = LibrarySortType.allCases.count

    // 시트 높이 = 상단여백 + 행 + 간격. detent 계산에 쓴다(콘텐츠에 딱 맞춤).
    // 하단 여백은 두지 않는다 — 시스템이 이 높이 **아래에 홈 인디케이터 safe area를 더해** 시트를 그리므로,
    // 여기서 또 주면 여백이 두 겹이 되어 마지막 행 아래가 휑해진다.
    static let sheetHeight: CGFloat =
        Metric.topPadding
        + CGFloat(rowCount) * Metric.rowHeight
        + CGFloat(rowCount - 1) * Metric.rowSpacing

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: Metric.topPadding)
            ForEach(Array(LibrarySortType.allCases.enumerated()), id: \.element) { index, sortType in
                if index > 0 {
                    Spacer().frame(height: Metric.rowSpacing)
                }
                row(sortType)
            }
        }
        // 패딩은 VStack 전체에 한 번(ReadingPeriodSheet와 동일) — 행마다 걸면 폭 계산이 어긋나기 쉽다.
        .padding(.horizontal, Metric.horizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.wssWhite)
        .presentationDetents([.height(LibrarySortSheet.sheetHeight)])
        .presentationDragIndicator(.hidden)
        // ⚠️ presentationCornerRadius는 쓰지 않는다 — presentationBackground(Color)와 함께 쓰면
        // 배경 사각형이 시트 둥근 모서리에 클립되지 않아 양 옆·하단이 화면 밖으로 삐져나온다(ReadingPeriodSheet도 안 씀).
        // iOS 26 시트 기본 배경은 글래스 — 디자인은 불투명 흰색이라 presentationBackground만 명시.
        .presentationBackground(Color.wssWhite)
    }

    private func row(_ sortType: LibrarySortType) -> some View {
        let isSelected = sortType == selected
        return Button {
            onSelect(sortType)
        } label: {
            Text(sortType.libraryDisplayName)
                .applyWSSFont(.body2, color: isSelected ? .wssBlack : .wssGray200)
                // 체크는 글씨 레이아웃에 영향 주지 않는 overlay로 글씨 왼쪽에 얹는다 →
                // 선택돼도 글씨는 가운데 그대로 있고 체크만 왼쪽에 나타난다(글씨 밀림 방지).
                .overlay(alignment: .leading) {
                    if isSelected {
                        WSSImage.icCheckMark.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: Metric.checkSize, height: Metric.checkSize)
                            .offset(x: -(Metric.checkSize + Metric.checkGap))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: Metric.rowHeight)
                // 선택 배경만 그리고(미선택은 clear) 모양에 클립 — content는 clipShape로 자르지 않는다.
                .background(
                    isSelected ? Color.wssPrimary20 : Color.clear,
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

// presentationDetents는 실제 .sheet로 띄울 때만 적용되므로, 프리뷰도 시트로 호스팅한다.
private struct SortSheetPreviewHost: View {
    @State private var isPresented = true
    var body: some View {
        Color.wssGray50
            .sheet(isPresented: $isPresented) {
                LibrarySortSheet(selected: .title) { print("정렬 선택: \($0)") }
            }
    }
}

#Preview {
    SortSheetPreviewHost()
}
