//
//  WSSDateWheel.swift
//  NovelReviewFeature
//
//  Created by YunhakLee on 6/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem
import WSSComponent

/// 연/월/일 3열 휠 날짜 선택기. 가운데 행이 선택값(밝은 밴드 + primary 체크), 나머지는 회색.
/// iOS 17 ScrollView 스냅 API(`scrollTargetBehavior(.viewAligned)` + `scrollPosition`)로 구현.
struct WSSDateWheel: View {

    @Binding var date: Date
    /// 선택 가능한 최대 날짜(보통 오늘). 이보다 미래로 굴리면 이 날짜로 되돌린다.
    private let maxDate: Date

    private let rowHeight: CGFloat = 37
    private let visibleCount = 3
    private let calendar = Calendar.current
    private let years: [Int]

    @State private var year: Int
    @State private var month: Int
    @State private var day: Int
    /// 미래로 오버슈트한 스크롤이 멈췄는지 판단하는 디바운스 Task(마지막 변경 후 일정 시간 무변화 = 정착).
    @State private var settleTask: Task<Void, Never>?
    /// 되돌림 시 각 컬럼이 선택값으로 물리 스크롤을 재정렬하도록 알리는 신호.
    @State private var bounceToken = 0

    init(date: Binding<Date>, maxDate: Date) {
        self._date = date
        self.maxDate = maxDate
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date.wrappedValue)
        _year = State(initialValue: comps.year ?? 2024)
        _month = State(initialValue: comps.month ?? 1)
        _day = State(initialValue: comps.day ?? 1)
        let maxYear = 3000
        self.years = Array(1900...maxYear)
    }

    private var months: [Int] { Array(1...12) }

    /// 선택된 연/월에 맞는 실제 일수(28~31).
    private var days: [Int] {
        let comps = DateComponents(year: year, month: month)
        guard let monthDate = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: monthDate) else {
            return Array(1...31)
        }
        return Array(range)
    }

    var body: some View {
        ZStack {
            // 가운데 선택 밴드. 체크는 각 WheelColumn 내부(ScrollView 옆)에 둔다.
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wssPrimary20)
                .frame(height: rowHeight)

            HStack(spacing: 0) {
                WheelColumn(values: years, selection: $year, format: { "\($0)" }, numberWidth: 40, rowHeight: rowHeight, visibleCount: visibleCount, bounceToken: bounceToken)
                Spacer()
                WheelColumn(values: months, selection: $month, format: { String(format: "%02d", $0) }, numberWidth: 20, rowHeight: rowHeight, visibleCount: visibleCount, bounceToken: bounceToken)
                Spacer()
                WheelColumn(values: days, selection: $day, format: { String(format: "%02d", $0) }, numberWidth: 20, rowHeight: rowHeight, visibleCount: visibleCount, bounceToken: bounceToken)
            }
            .padding(.horizontal, 7.5)
        }
        .frame(height: rowHeight * CGFloat(visibleCount))
        .onChange(of: year) { _, _ in commit() }
        .onChange(of: month) { _, _ in commit() }
        .onChange(of: day) { _, _ in commit() }
        // 부모가 편집 대상(시작↔종료)을 바꾸면 date가 외부에서 갱신된다 → 휠을 그 날짜로 재정렬.
        .onChange(of: date) { _, newDate in syncColumns(to: newDate) }
    }

    /// 외부에서 `date`가 바뀌면(시작↔종료 전환) 내부 컬럼을 그 날짜로 맞추고 물리 스크롤을 재정렬한다.
    /// 내부 스크롤이 일으킨 `date` 변경은 이미 year/month/day와 일치하므로 early-return으로 되먹임 루프를 막는다.
    /// (`.id(field)` 재생성 대신 이 방식을 쓰면 휠이 유지돼 전환 시 맨 위로 튀는 번쩍임이 없다.)
    private func syncColumns(to newDate: Date) {
        let c = calendar.dateComponents([.year, .month, .day], from: newDate)
        guard let y = c.year, let m = c.month, let d = c.day else { return }
        if y == year && m == month && d == day { return }
        year = y
        month = m
        day = d
        bounceToken &+= 1   // 컬럼들이 새 선택값으로 물리 스크롤을 재정렬
    }

    /// 스크롤 변경마다 호출. 미래로 오버슈트하면 `date`를 갱신하지 않고 정착 디바운스만 무장하고,
    /// 스크롤이 멈춘 뒤(`scheduleBounceBack`)에야 오늘로 되돌린다. 유효 범위면 즉시 반영한다.
    private func commit() {
        // 월 길이 변동(예: 31일→28일)으로 일이 넘치면 클램프.
        if day > days.count {
            day = days.count
            return
        }
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        guard let assembled = calendar.date(from: comps) else { return }

        if calendar.compare(assembled, to: maxDate, toGranularity: .day) == .orderedDescending {
            // 미래로 굴러가는 중 — 일단 두고 정착되면 되돌린다. date(세그먼트 표시)는 갱신하지 않는다.
            scheduleBounceBack()
        } else {
            settleTask?.cancel()   // 유효한 값에 정착했으면 예약된 되돌림 취소
            date = assembled
        }
    }

    /// 마지막 변경 후 일정 시간 추가 변경이 없으면(= 스크롤 정착) 오늘로 되돌린다.
    /// 플링 도중에는 계속 재예약되어 발동하지 않으므로 관성과 싸우지 않는다.
    private func scheduleBounceBack() {
        settleTask?.cancel()
        settleTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            bounceBackToMaxDate()
        }
    }

    private func bounceBackToMaxDate() {
        let c = calendar.dateComponents([.year, .month, .day], from: maxDate)
        withAnimation(.easeOut(duration: 0.35)) {
            year = c.year ?? year
            month = c.month ?? month
            day = c.day ?? day
        }
        date = maxDate
        bounceToken &+= 1   // 컬럼들이 선택값으로 물리 스크롤을 촤라락 재정렬
    }
}

// MARK: - WheelColumn

/// 단일 열 휠. 가운데로 스냅되며, 가운데 정렬된 값이 곧 선택값이다.
private struct WheelColumn: View {

    let values: [Int]
    @Binding var selection: Int
    let format: (Int) -> String
    /// 숫자 컬럼 폭. ScrollView를 이 폭으로 고정해 체크가 숫자 왼쪽 10pt(HStack spacing)에 오게 한다.
    let numberWidth: CGFloat
    let rowHeight: CGFloat
    let visibleCount: Int
    /// 부모가 오버슈트를 되돌릴 때 증가. 변경되면 선택값으로 물리 스크롤을 재정렬한다.
    let bounceToken: Int

    var body: some View {
        // 체크를 ScrollView 옆에 둔다. ScrollView 폭을 숫자 폭으로 고정하면
        // 가운데 정렬된 숫자의 왼쪽 10pt(HStack spacing)에 체크가 자연히 고정된다.
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    ForEach(values, id: \.self) { value in
                        let isSelected = value == selection

                        Text(format(value))
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
            // scrollPosition만으로는 HStack 중첩 시 초기 스크롤이 적용되지 않아, 진입 시 선택값으로 명시 스크롤.
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(selection, anchor: .center)
                }
            }
            // 오버슈트 되돌림: 부모가 선택값을 오늘로 바꾸고 토큰을 올리면, 물리 스크롤을 그 값으로 촤라락 정렬.
            .onChange(of: bounceToken) { _, _ in
                withAnimation(.easeOut(duration: 0.28)) {
                    proxy.scrollTo(selection, anchor: .center)
                }
            }
            // 월 변경으로 일수가 바뀌면(예: 31일달→28일달) 일 컬럼을 선택값으로 재정렬.
            .onChange(of: values.count) { _, _ in
                withAnimation {
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
