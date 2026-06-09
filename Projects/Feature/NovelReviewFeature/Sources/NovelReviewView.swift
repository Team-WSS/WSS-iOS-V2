//
//  NovelReviewView.swift
//  NovelReviewFeature
//
//  Created by YunhakLee on 6/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import DesignSystem
import NovelReviewDomain
import WSSComponent

// 작품 평가(리뷰 초안) 화면. WSSComponent의 Presentation 확장(아이콘/라벨)과 DesignSystem 토큰으로 구성.
// "얇은 ViewModel" 원칙: 카피·포맷·색 등 표기는 전부 View에서 결정한다.
struct NovelReviewView: View {
    
    @StateObject private var viewModel: NovelReviewViewModel
    @State private var isPeriodSheetPresented = false
    @Environment(\.dismiss) private var dismiss
    
    /// 네비게이션 타이틀. 진입 이전 화면이 Factory를 통해 주입한다.
    private let title: String
    
    init(viewModel: NovelReviewViewModel, title: String) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.title = title
    }
    
    var body: some View {
        Group {
            if viewModel.state.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    WSSImage.icNavigateLeft.swiftUIImage
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.wssGray200)
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    viewModel.handle(.save)
                } label: {
                    if viewModel.state.isSaving {
                        ProgressView()
                    } else {
                        Text("완료")
                            .applyWSSFont(.title2)
                            .foregroundStyle(Color.wssPrimary100)
                    }
                }
                .disabled(viewModel.state.isSaving)
            }
        }
        .onAppear {
            viewModel.handle(.load)
        }
        .sheet(isPresented: $isPeriodSheetPresented) {
            ReadingPeriodSheet(
                status: viewModel.state.draft.status,
                period: viewModel.state.draft.period
            ) { start, end in
                viewModel.handle(.updatePeriod(start: start, end: end))
                isPeriodSheetPresented = false
            }
        }
        .alert(
            "오류",
            isPresented: errorBinding,
            actions: {
                Button("확인") { viewModel.handle(.dismissError) }
            },
            message: {
                Text(viewModel.state.errorMessage ?? "")
            }
        )
    }
    
    private var content: some View {
        ScrollView {
            VStack(spacing: 0) {
                statusSection
                periodSection
                
                sectionDivider
                    .padding(.top, 14)
                    .padding(.bottom, 24)
                
                ratingSection
                
                sectionDivider
                    .padding(.top, 38)
                    .padding(.bottom, 24)
                
                attractivePointSection
                
                sectionDivider
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                
                keywordSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
    
    private var sectionDivider: some View {
        Rectangle()
            .fill(Color.wssGray50)
            .frame(height: 1)
    }
}

// MARK: - Sections

private extension NovelReviewView {
    
    /// 읽기 상태 — 셋 중 하나만 선택. 아이콘+라벨을 가로로 나열, 탭으로 전환.
    /// 아이콘은 단색 에셋이라 `.template`로 틴팅: 선택=채움(`fillImage`)+primary, 미선택=외곽선(`strokeImage`)+회색.
    var statusSection: some View {
        HStack(spacing: 0) {
            ForEach(ReadingStatus.allCases, id: \.self) { status in
                let isSelected = viewModel.state.draft.status == status
                let imageColor = isSelected ? Color.wssPrimary100 : Color.wssGray80
                let textColor = isSelected ? Color.wssPrimary100 : Color.wssGray200
                
                Button {
                    viewModel.handle(.selectStatus(status))
                } label: {
                    VStack(spacing: 5) {
                        status.fillImage
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundStyle(imageColor)
                        
                        Text(status.statusName)
                            .applyWSSFont(.body5)
                            .foregroundStyle(textColor)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    // 틴트 색의 기본 크로스페이드를 짧게 고정(미설정 시 느리게 번진다).
                    .animation(.easeInOut(duration: 0.1), value: isSelected)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
    }
    
    /// 독서 기간 — 탭하면 sheet로 날짜를 고른다. 라벨(밑줄)은 선택된 날짜를 `yy년 M월 d일`로 표기.
    var periodSection: some View {
        Button {
            isPeriodSheetPresented = true
        } label: {
            periodValueLabel
                .applyWSSFont(.body4_2)
                .foregroundStyle(Color.wssGray200)
                .lineLimit(1)
                .underline()
                .frame(minWidth: 83)
                .frame(height: 44, alignment: .center)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    /// 선택된 기간 표시. 도메인 `normalized(for:)`가 상태에 맞는 날짜만 채워두므로
    /// status로 분기하지 않고 start/end 존재 여부로만 표기한다(둘 다=기간, 하나=단일 날짜).
    @ViewBuilder
    var periodValueLabel: some View {
        switch (viewModel.state.draft.period?.start, viewModel.state.draft.period?.end) {
        case let (start?, end?):
            Text("\(periodDateFormatter.string(from: start)) ~ \(periodDateFormatter.string(from: end))")
        case let (start?, nil):
            Text(periodDateFormatter.string(from: start))
        case let (nil, end?):
            Text(periodDateFormatter.string(from: end))
        case (nil, nil):
            Text("본 날짜 추가")
        }
    }
    
    /// 별점 — 별 탭/슬라이드로 0.5 단위 부여. 0.0은 "평점 없음"(nil)으로 매핑(도메인 Rating은 0.5부터).
    var ratingSection: some View {
        VStack(spacing: 14) {
            Text("별점")
                .applyWSSFont(.title3)
                .foregroundStyle(Color.wssBlack)
            
            StarRatingView(rating: viewModel.state.draft.rating?.value ?? 0) { value in
                print(value)
                viewModel.handle(.updateRating(value))
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    /// 매력 포인트 — 6개 중 최대 3개 토글(초과는 ViewModel이 막고 알림).
    /// 아이콘은 단색 에셋이라 `.template`로 틴팅: 선택=primary, 미선택=회색.
    var attractivePointSection: some View {
        VStack(spacing: 14) {
            Text("매력포인트")
                .applyWSSFont(.title3)
                .foregroundStyle(Color.wssBlack)
            
            HStack(spacing: 0) {
                ForEach(AttractivePoint.allCases, id: \.self) { point in
                    let isSelected = viewModel.state.draft.attractivePoints.contains(point)
                    let imageColor = isSelected ? Color.wssPrimary100 : Color.wssGray80
                    let textColor = isSelected ? Color.wssPrimary100 : Color.wssGray200
                    
                    Button {
                        viewModel.handle(.toggleAttractivePoint(point))
                    } label: {
                        VStack(spacing: 6) {
                            point.iconImage
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                                .foregroundStyle(imageColor)
                            
                            Text(point.displayName)
                                .applyWSSFont(.body4)
                                .foregroundStyle(textColor)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        // 틴트 색의 기본 크로스페이드를 짧게 고정(미설정 시 느리게 번진다).
                        .animation(.easeInOut(duration: 0.05), value: isSelected)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    /// 키워드 — 제목 + 검색바 룩 탭 버튼. 탭하면 키워드 탐색뷰로 이동(추후 연결).
    /// 선택된 키워드 칩 표시는 추후 구현.
    var keywordSection: some View {
        VStack(spacing: 14) {
            Text("키워드")
                .applyWSSFont(.title3)
                .foregroundStyle(Color.wssBlack)
            
            WSSSearchBarButton(
                placeholder: "작품을 나타내는 키워드는?",
                placeholderAlignment: .center
            ) {
                // TODO: 키워드 탐색뷰로 이동 (실제 액션은 추후 연결)
                print("키워드 탐색뷰로 이동")
            }
        }
    }
    
    var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.errorMessage != nil },
            set: { _ in viewModel.handle(.dismissError) }
        )
    }
}

// MARK: - StarRatingView

/// 별점 입력 — 탭/드래그(슬라이드)로 0.5 단위 점수를 부여한다.
/// 별 에셋(`icLargeStar*`)은 살몬색이 박혀 있어 틴팅 없이 채움/반쪽/빈 이미지를 교체해 표현한다.
private struct StarRatingView: View {
    
    let rating: Double
    let onChange: (Double) -> Void
    
    private let starCount = 5
    private let starSize: CGFloat = 30
    private let spacing: CGFloat = 10
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<starCount, id: \.self) { index in
                image(for: index)
                    .resizable()
                    .scaledToFit()
                    .frame(width: starSize, height: starSize)
            }
        }
        .contentShape(Rectangle())
        .overlay {
            GeometryReader { geo in
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        // minimumDistance 0 → 단순 탭도 onChanged로 잡혀 탭/슬라이드를 한 제스처로 처리.
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                update(at: value.location.x, totalWidth: geo.size.width)
                            }
                    )
            }
        }
    }
    
    /// index번째 별을 현재 점수에 맞춰 채움/반쪽/빈 상태로 그린다.
    private func image(for index: Int) -> Image {
        let starValue = Double(index + 1)
        if rating >= starValue {
            return WSSImage.icLargeStarFilled.swiftUIImage
        } else if rating + 0.5 >= starValue {
            return WSSImage.icLargeStarHalf.swiftUIImage
        } else {
            return WSSImage.icLargeStarEmpty.swiftUIImage
        }
    }
    
    /// 터치 x좌표 → 0.5 단위 점수. 별 경계를 넘기면 그 별을 채우도록 올림(.up) 처리.
    private func update(at x: CGFloat, totalWidth: CGFloat) {
        guard totalWidth > 0 else { return }
        let raw = Double(x / totalWidth) * Double(starCount)   // 0...5
        let stepped = (raw * 2).rounded(.up) / 2
        // 0.5 단위
        let clamped = min(max(stepped, 0), Double(starCount))
        onChange(clamped)
    }
}

// MARK: - ReadingPeriodSheet

/// 기간 표기 전용 포맷터. 디자인 표기(`yy년 M월 d일`)가 고정 문구라 FormatStyle 대신 명시적 포맷을 쓴다.
private let periodDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yy년 M월 d일"
    return formatter
}()

/// segment 날짜 표기 포맷(`yyyy-MM-dd`). watched 모드 시작/종료 탭의 보조 라벨용.
private let segmentDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

/// 독서 기간 선택 sheet. 상태에 따라 입력 형태가 다르다.
/// - watching: 시작 날짜 1개 (높이 362)
/// - quit: 종료 날짜 1개 (높이 362)
/// - watched: segment로 시작/종료를 전환하며 한 시트에서 둘 다 선택 (높이 436)
///
/// 배경은 흰색, 완료는 `WSSCTAButton`, 그 아래 "날짜 삭제"(기간 제거). 취소는 우상단 X 또는 배경 탭(시트 dismiss).
private struct ReadingPeriodSheet: View {
    
    private enum Field: Hashable { case start, end }
    
    let status: ReadingStatus
    let onApply: (_ start: Date?, _ end: Date?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Namespace private var segmentNamespace
    @State private var field: Field = .start
    @State private var start: Date
    @State private var end: Date
    /// 선택 가능한 최대 날짜(오늘). 휠의 미래 클램프 기준.
    private let today = Calendar.current.startOfDay(for: Date())
    
    init(
        status: ReadingStatus,
        period: ReadingPeriod?,
        onApply: @escaping (_ start: Date?, _ end: Date?) -> Void
    ) {
        self.status = status
        self.onApply = onApply
        _start = State(initialValue: period?.start ?? Date())
        _end = State(initialValue: period?.end ?? Date())
    }
    
    /// 시작/종료를 모두 고르는 watched만 더 높다.
    private var sheetHeight: CGFloat {
        status == .watched ? 394 : 320
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            if status == .watched {
                segmentedField
                    .padding(.bottom, 7)
            }
            
            // watched는 field 전환 시 편집 날짜가 바뀌므로 id로 휠을 새로 띄워 초기값을 갱신한다.
            WSSDateWheel(date: editingDateBinding, maxDate: today)
                .id(field)
                .padding(.top, 10)
                .padding(.bottom, 30)
            
            WSSCTAButton(title: "완료") { apply() }
            
            Button {
                onApply(nil, nil)
            } label: {
                Text("날짜 삭제")
                    .applyWSSFont(.body1)
                    .foregroundStyle(Color.wssPrimary100)
                    .frame(width: 101, height: 51)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 5)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.wssWhite)
        .presentationDetents([.height(sheetHeight)])
        .presentationBackground(Color.wssWhite)
    }
    
    /// watched는 segment가 제목 역할을 하므로 X만, 단일 상태는 제목 + X.
    private var header: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if status != .watched {
                Text(status.dateText)
                    .applyWSSFont(.title1)
                    .foregroundStyle(Color.wssBlack)
                    .padding(.bottom, 15)
                    .padding(.leading, 5)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                WSSImage.icCancelModal.swiftUIImage
                    .renderingMode(.template)
                    .foregroundStyle(Color.wssGray300)
                    .frame(width: 25, height: 25)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 20)
        }
    }
    
    /// 시작/종료 전환 segment(2열). 선택된 쪽은 흰 배경 + 그림자.
    private var segmentedField: some View {
        HStack(spacing: 0) {
            segmentItem(.start, label: "시작 날짜", date: start)
            segmentItem(.end, label: "종료 날짜", date: end)
        }
        .padding(2)
        .background(Color.wssGray50)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        // 애니메이션을 segment에만 한정한다. 전역 withAnimation을 쓰면 .id(field)로 재생성되는
        // 휠의 scrollPosition 이동까지 애니메이션을 타서 숫자가 주르륵 스크롤된다.
        .animation(.snappy(duration: 0.25), value: field)
    }
    
    private func segmentItem(_ target: Field, label: String, date: Date) -> some View {
        let isSelected = field == target
        let color = isSelected ? Color.wssBlack : Color.wssGray200
        
        return VStack(spacing: 2) {
            Text(label)
                .applyWSSFont(.title2)
            Text(segmentDateFormatter.string(from: date))
                .applyWSSFont(.body4)
        }
        .foregroundStyle(color)
        .frame(height: 63)
        .frame(maxWidth: .infinity)
        // 선택 강조(흰 배경)는 단일 thumb를 matchedGeometryEffect로 공유해 좌우로 슬라이드시킨다.
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wssWhite)
                    .matchedGeometryEffect(id: "segmentThumb", in: segmentNamespace)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            field = target
        }
    }
    
    /// 상태별로 segment가 가리키는(또는 단일) 날짜를 편집하는 바인딩.
    /// set은 휠이 이미 오늘로 클램프한 값을 받아, watched에서 두 날짜의 순서를 보정한다.
    private var editingDateBinding: Binding<Date> {
        Binding(get: { editingDate }, set: { applyEditedDate($0) })
    }

    private var editingDate: Date {
        switch status {
        case .watching: return start
        case .quit:     return end
        case .watched:  return field == .start ? start : end
        }
    }

    /// 편집 중인 쪽이 기준. watched에서 시작이 종료를 넘으면 종료를, 종료가 시작보다 빠르면 시작을 끌어다 맞춘다.
    /// (어느 쪽이 양보하느냐는 포커스 상태에 달린 입력 UX 정책 — 도메인 규칙 아님)
    private func applyEditedDate(_ newDate: Date) {
        switch status {
        case .watching:
            start = newDate
        case .quit:
            end = newDate
        case .watched:
            if field == .start {
                start = newDate
                if start > end { end = start }
            } else {
                end = newDate
                if end < start { start = end }
            }
        }
    }
    
    /// 상태별로 의미 있는 날짜만 넘긴다. 도메인이 다시 normalize하므로 여기선 형태만 맞춘다.
    private func apply() {
        switch status {
        case .watching:
            onApply(start, nil)
        case .quit:
            onApply(nil, end)
        case .watched:
            onApply(start, end)
        }
    }
}

// MARK: - WSSDateWheel

/// 연/월/일 3열 휠 날짜 선택기. 가운데 행이 선택값(밝은 밴드 + primary 체크), 나머지는 회색.
/// iOS 17 ScrollView 스냅 API(`scrollTargetBehavior(.viewAligned)` + `scrollPosition`)로 구현.
private struct WSSDateWheel: View {
    
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

// MARK: - Preview

#Preview {
    NavigationStack {
        NovelReviewView(
            viewModel: NovelReviewViewModel(
                novelID: NovelID(1),
                loadUseCase: PreviewLoadNovelReviewDraftUseCase(),
                saveUseCase: PreviewSaveNovelReviewUseCase()
            ),
            title: "당신의 이해를 돕기 위하여"
        )
    }
}

// presentationDetents는 실제 .sheet로 띄울 때만 적용되므로, 프리뷰도 시트로 호스팅한다.
private struct PeriodSheetPreviewHost: View {
    let status: ReadingStatus
    @State private var isPresented = true
    var body: some View {
        Color.wssGray50
            .sheet(isPresented: $isPresented) {
                ReadingPeriodSheet(status: status, period: nil) { _, _ in }
            }
    }
}

#Preview("기간 시트 - 시작/종료") {
    PeriodSheetPreviewHost(status: .watched)
}

#Preview("기간 시트 - 단일") {
    PeriodSheetPreviewHost(status: .watching)
}

private struct PreviewLoadNovelReviewDraftUseCase: LoadNovelReviewDraftUseCase {
    func execute(novelID: NovelID) async throws(RepositoryError) -> NovelReviewDraft? {
        print("로드됨!")
        return nil
    }
}

private struct PreviewSaveNovelReviewUseCase: SaveNovelReviewUseCase {
    func execute(draft: NovelReviewDraft) async throws(RepositoryError) {
        print("저장됨!")
    }
}
