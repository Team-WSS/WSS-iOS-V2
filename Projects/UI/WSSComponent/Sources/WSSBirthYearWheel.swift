//
//  WSSBirthYearWheel.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

/// 출생연도 전용 1열 휠. 가운데 행이 선택값(밝은 밴드 + primary 체크), 나머지는 회색.
/// iOS 17 ScrollView 스냅 API(`scrollTargetBehavior(.viewAligned)` + `scrollPosition`)로 구현.
/// 연도 배열 자체를 `minYear...maxYear`로 막아두므로 범위 밖으로는 물리적으로 스크롤되지 않는다
/// (오버슈트 방지용 되돌림 로직이 필요 없다 — 월/일이 섞인 원본 `WSSDateWheel`과의 차이).
public struct WSSBirthYearWheel: View {
    
    @Binding var year: Int
    private let years: [Int]
    
    private let rowHeight: CGFloat = 37
    private let visibleCount = 3
    
    public init(year: Binding<Int>,
                minYear: Int,
                maxYear: Int) {
        self._year = year
        self.years = Array(minYear...maxYear)
    }
    
    public var body: some View {
        ZStack {
            // 가운데 선택 밴드. 체크는 WheelColumn 내부(ScrollView 옆)에 둔다.
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wssPrimary20)
                .frame(height: rowHeight)
            
            WheelColumn(values: years, selection: $year, rowHeight: rowHeight, visibleCount: visibleCount)
        }
        .frame(height: rowHeight * CGFloat(visibleCount))
    }
}

// MARK: - WheelColumn

/// 단일 열 휠. 가운데로 스냅되며, 가운데 정렬된 값이 곧 선택값이다.
private struct WheelColumn: View {
    
    let values: [Int]
    @Binding var selection: Int
    let rowHeight: CGFloat
    let visibleCount: Int
    
    private let numberWidth: CGFloat = 40
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    ForEach(values, id: \.self) { value in
                        let isSelected = value == selection
                        
                        // Text("\(value)")는 LocalizedStringKey 보간이라 Int에 천 단위 콤마(예: "2,001")를 자동으로 붙인다 — String으로 먼저 변환해 우회.
                        Text(String(value))
                            .applyWSSFont(.body2)
                            .foregroundStyle(isSelected ? Color.wssBlack : Color.wssGray200)
                            .frame(width: numberWidth+80, height: rowHeight, alignment: .center)
                            .id(value)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .frame(width: numberWidth+80, height: rowHeight * CGFloat(visibleCount))
            // 위/아래 여백을 둬 첫/마지막 값도 가운데로 올 수 있게 한다.
            .contentMargins(.vertical, rowHeight * CGFloat((visibleCount - 1) / 2), for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: selectionID)
            // scrollPosition만으로는 초기 스크롤이 적용되지 않아, 진입 시 선택값으로 명시 스크롤.
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(selection, anchor: .center)
                }
            }
            .background(alignment: .leading) {
                WSSImage.icCheckMark.swiftUIImage
                    .renderingMode(.template)
                    .foregroundStyle(Color.wssPrimary100)
            }
        }
    }
    
    /// `scrollPosition`은 옵셔널 ID 바인딩을 받으므로 래핑한다.
    private var selectionID: Binding<Int?> {
        Binding(
            get: { selection },
            set: { if let value = $0 { selection = value } }
        )
    }
}
