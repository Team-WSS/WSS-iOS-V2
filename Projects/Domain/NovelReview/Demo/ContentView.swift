//
//  ContentView.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 1/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import NovelReviewDomain
import BaseDomain

struct ContentView: View {

    // 25개 키워드 (토글 선택용)
    private let demoKeywords: [Keyword] = (1...25).map { Keyword(id: KeywordID($0), name: "키워드 \($0)") }

    // Draft (도메인 기능 테스트 대상)
    @State private var draft = NovelReviewDraft(
        novelID: NovelID(1),
        status: .watching,
        period: nil,
        rating: nil,
        attractivePoints: [],
        keywords: []
    )

    // Period Editor State (UI 편의용)
    @State private var periodEnabled = false
    @State private var startEnabled = true
    @State private var endEnabled = false
    @State private var startDate = Date()
    @State private var endDate = Date()

    // Rating Editor State
    @State private var ratingEnabled = false
    @State private var ratingValue: Double = 3.0

    // Alert
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        NavigationStack {
            List {
                summarySection
                statusSection
                periodSection
                ratingSection
                attractivePointsSection
                keywordsSection
            }
            .navigationTitle("Domain Demo")
            .onAppear { syncEditorsFromDraft() }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Sections

    private var summarySection: some View {
        Section("요약") {
            LabeledContent("novelID", value: String(describing: draft.novelID))
            LabeledContent("status", value: String(describing: draft.status))
            LabeledContent("period") { Text(periodText(draft.period)).font(.footnote).foregroundStyle(.secondary) }
            LabeledContent("rating") { Text(draft.rating.map { String(format: "%.1f", $0.value) } ?? "nil").font(.footnote).foregroundStyle(.secondary) }
            LabeledContent("attractivePoints") { Text("\(draft.attractivePoints.count)/3") }
            LabeledContent("keywords") { Text("\(draft.keywords.count)/20") }
        }
    }

    private var statusSection: some View {
        Section("읽기 상태") {
            Picker("Status", selection: Binding(
                get: { draft.status },
                set: { newStatus in
                    draft.changeStatus(newStatus)
                    // status 변경에 의해 period가 정규화될 수 있으니 UI editor도 sync
                    syncEditorsFromDraft()
                }
            )) {
                Text("읽는 중").tag(ReadingStatus.watching)
                Text("완독").tag(ReadingStatus.watched)
                Text("하차").tag(ReadingStatus.quit)
            }
            .pickerStyle(.segmented)
        }
    }

    private var periodSection: some View {
        Section("읽기 기간") {
            Toggle("기간 사용", isOn: Binding(
                get: { periodEnabled },
                set: { isOn in
                    periodEnabled = isOn
                    if !isOn {
                        draft.setPeriod(nil)
                    } else {
                        // 기본: start만 켠 상태
                        startEnabled = true
                        endEnabled = false
                        applyPeriodToDraft()
                    }
                }
            ))

            if periodEnabled {
                OptionalDatePickerRow(title: "시작 날짜", isEnabled: $startEnabled, date: $startDate) {
                    applyPeriodToDraft()
                }
                OptionalDatePickerRow(title: "종료 날짜", isEnabled: $endEnabled, date: $endDate) {
                    applyPeriodToDraft()
                }

                Text("※ status에 따라 period가 자동 정규화됩니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var ratingSection: some View {
        Section("별점") {
            Toggle("별점 사용", isOn: Binding(
                get: { ratingEnabled },
                set: { isOn in
                    ratingEnabled = isOn
                    if !isOn {
                        draft.setRating(nil)
                    } else {
                        applyRatingToDraft()
                    }
                }
            ))

            if ratingEnabled {
                VStack(alignment: .leading, spacing: 10) {
                    Text("선택: \(ratingValue, specifier: "%.1f") (0.5 단위)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Slider(
                        value: Binding(
                            get: { ratingValue },
                            set: { newValue in
                                let snapped = (newValue * 2).rounded() / 2
                                ratingValue = snapped
                                applyRatingToDraft()
                            }
                        ),
                        in: 0.5...5.0,
                        step: 0.5
                    )
                }
            }
        }
    }

    private var attractivePointsSection: some View {
        Section("매력 포인트 (최대 3개)") {
            FlowWrap(spacing: 8) {
                ForEach(AttractivePoint.allCases, id: \.self) { point in
                    let selected = draft.attractivePoints.contains(point)
                    Chip(title: String(describing: point), selected: selected) {
                        toggleAttractivePoint(point)
                    }
                }
            }
            Text("선택됨: \(draft.attractivePoints.count)/3")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var keywordsSection: some View {
        Section("키워드 (25개 중 선택, 최대 20개)") {
            FlowWrap(spacing: 8) {
                ForEach(demoKeywords, id: \.self) { keyword in
                    let selected = draft.keywords.contains(keyword)
                    Chip(title: keyword.name, selected: selected) {
                        toggleKeyword(keyword)
                    }
                }
            }
            Text("선택됨: \(draft.keywords.count)/20")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func toggleAttractivePoint(_ point: AttractivePoint) {
        if draft.attractivePoints.contains(point) {
            draft.removeAttractivePoint(point)
            return
        }
        do {
            try draft.addAttractivePoint(point) // 4번째 선택 시 throw
        } catch {
            show(title: "매력 포인트 제한", message: String(describing: error))
        }
    }

    private func toggleKeyword(_ keyword: Keyword) {
        var next = draft.keywords
        if let idx = next.firstIndex(of: keyword) {
            next.remove(at: idx)
        } else {
            next.append(keyword)
        }

        do {
            try draft.setKeywords(next) // 21번째 선택 시 throw (현재 도메인 구현 기준)
        } catch {
            show(title: "키워드 제한", message: String(describing: error))
        }
    }

    private func applyPeriodToDraft() {
        let s: Date? = startEnabled ? startDate : nil
        let e: Date? = endEnabled ? endDate : nil

        if s == nil && e == nil {
            draft.setPeriod(nil)
            return
        }

        do {
            let p = try ReadingPeriod(start: s, end: e)
            draft.setPeriod(p) // status 기준 normalized 적용됨
            syncEditorsFromDraft()
        } catch {
            show(title: "기간 오류", message: String(describing: error))
        }
    }

    private func applyRatingToDraft() {
        do {
            let r = try Rating(ratingValue)
            draft.setRating(r)
        } catch {
            show(title: "별점 오류", message: String(describing: error))
        }
    }

    // MARK: - Sync

    private func syncEditorsFromDraft() {
        // period
        if let p = draft.period {
            periodEnabled = true
            startEnabled = (p.start != nil)
            endEnabled = (p.end != nil)
            if let s = p.start { startDate = s }
            if let e = p.end { endDate = e }
        } else {
            periodEnabled = false
            startEnabled = true
            endEnabled = false
        }

        // rating
        if let r = draft.rating {
            ratingEnabled = true
            ratingValue = r.value
        } else {
            ratingEnabled = false
            ratingValue = 3.0
        }
    }

    // MARK: - Helpers

    private func show(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }

    private func periodText(_ period: ReadingPeriod?) -> String {
        guard let period else { return "nil" }

        let f = DateFormatter()
        f.dateStyle = .medium

        let s = period.start.map { f.string(from: $0) } ?? "nil"
        let e = period.end.map { f.string(from: $0) } ?? "nil"
        return "start: \(s), end: \(e)"
    }
}

// MARK: - Components

private struct OptionalDatePickerRow: View {
    let title: String
    @Binding var isEnabled: Bool
    @Binding var date: Date
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(title, isOn: Binding(
                get: { isEnabled },
                set: { newValue in
                    isEnabled = newValue
                    onChange()
                }
            ))

            if isEnabled {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { date },
                        set: { newValue in
                            date = newValue
                            onChange()
                        }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
            }
        }
    }
}

private struct Chip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(selected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// iOS16+ : 간단한 칩 래핑 레이아웃
private struct FlowWrap<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content

    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        FlowLayout(spacing: spacing) { content }
    }
}

@available(iOS 16.0, *)
private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? UIScreen.main.bounds.width
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
