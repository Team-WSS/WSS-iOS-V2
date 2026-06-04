//
//  NovelReviewView.swift
//  NovelReviewFeature
//
//  Created by YunhakLee on 6/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NovelReviewDomain
import WSSComponent

// 스켈레톤. 화면 구성/디자인은 추후 WSSComponent 컴포넌트 기반으로 교체한다.
// 라벨 표현은 WSSComponent의 Presentation 확장(statusName/displayName)을 사용한다.
struct NovelReviewView<ViewModel: NovelReviewViewModel>: View {

    @StateObject private var viewModel: ViewModel
    @State private var isPeriodSheetPresented = false

    init(viewModel: ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 24) {
            if viewModel.isLoading {
                ProgressView()
            } else {
                statusSection
                periodSection
                ratingSection
                attractivePointSection
                completeButton
            }
        }
        .padding()
        .navigationTitle("작품 평가")
        .onAppear {
            viewModel.load()
        }
        .sheet(isPresented: $isPeriodSheetPresented) {
            ReadingPeriodSheet(
                status: viewModel.selectedStatus,
                period: viewModel.selectedPeriod
            ) { start, end in
                viewModel.updatePeriod(start: start, end: end)
                isPeriodSheetPresented = false
            }
        }
        .alert(
            "오류",
            isPresented: errorBinding,
            actions: {
                Button("확인") { viewModel.dismissError() }
            },
            message: {
                Text(viewModel.errorMessage ?? "")
            }
        )
    }
}

// MARK: - Sections

private extension NovelReviewView {

    /// 읽기 상태 — 셋 중 하나만 선택(세그먼트).
    var statusSection: some View {
        Picker(
            "읽기 상태",
            selection: Binding(
                get: { viewModel.selectedStatus },
                set: { viewModel.selectStatus($0) }
            )
        ) {
            ForEach(ReadingStatus.allCases, id: \.self) { status in
                Text(status.statusName).tag(status)
            }
        }
        .pickerStyle(.segmented)
    }

    /// 독서 기간 — 상태별로 다른 날짜를 sheet에서 선택. 라벨은 상태에 맞춰 바뀐다(`dateText`).
    var periodSection: some View {
        Button {
            isPeriodSheetPresented = true
        } label: {
            HStack {
                Text(viewModel.selectedStatus.dateText)
                Spacer()
                periodValueLabel
            }
        }
    }

    /// 선택된 기간 표시. 도메인 `normalized(for:)`가 상태에 맞는 날짜만 채워두므로
    /// status로 분기하지 않고 start/end 존재 여부로만 표기한다(둘 다=기간, 하나=단일 날짜).
    /// Date는 SwiftUI 네이티브 포맷으로 직접 렌더(수동 DateFormatter 불필요).
    @ViewBuilder
    var periodValueLabel: some View {
        switch (viewModel.selectedPeriod?.start, viewModel.selectedPeriod?.end) {
        case let (start?, end?):
            Text("\(start, format: periodDateStyle) ~ \(end, format: periodDateStyle)")
        case let (start?, nil):
            Text(start, format: periodDateStyle)
        case let (nil, end?):
            Text(end, format: periodDateStyle)
        case (nil, nil):
            Text("선택").foregroundStyle(.secondary)
        }
    }

    /// 평점 — 0.0~5.0, 0.5 단위 슬라이더. 0.0은 "평점 없음"(nil)으로 처리(도메인 Rating은 0.5부터).
    var ratingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("평점")
                Spacer()
                Text(ratingDisplayText)
                    .foregroundStyle(viewModel.selectedRating == nil ? .secondary : .primary)
            }

            Slider(
                value: Binding(
                    get: { viewModel.selectedRating?.value ?? 0 },
                    set: { viewModel.updateRating($0) }
                ),
                in: 0...5,
                step: 0.5
            )
        }
    }

    var ratingDisplayText: String {
        guard let rating = viewModel.selectedRating else { return "평점 없음" }
        return String(format: "%.1f", rating.value)
    }

    /// 매력 포인트 — 6개 중 최대 3개 토글(초과는 ViewModel이 막고 알림).
    var attractivePointSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("매력 포인트")

            ForEach(AttractivePoint.allCases, id: \.self) { point in
                let isSelected = viewModel.selectedAttractivePoints.contains(point)

                Button {
                    viewModel.toggleAttractivePoint(point)
                } label: {
                    HStack {
                        Text(point.displayName)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
    }

    /// 완료 — 현재 draft를 저장한다. 저장 중에는 스피너 표시 + 중복 탭 방지.
    var completeButton: some View {
        Button {
            viewModel.save()
        } label: {
            if viewModel.isSaving {
                ProgressView()
            } else {
                Text("평가 완료")
            }
        }
        .disabled(viewModel.isSaving)
    }

    var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.dismissError() }
        )
    }
}

// MARK: - ReadingPeriodSheet

private let periodDateStyle = Date.FormatStyle.dateTime.year().month(.twoDigits).day(.twoDigits)

/// 독서 기간 선택 sheet. 상태에 따라 입력 형태가 다르다.
/// - watching: 시작 날짜 1개
/// - quit: 종료 날짜 1개
/// - watched: segment로 시작/종료를 전환하며 한 시트에서 둘 다 선택
private struct ReadingPeriodSheet: View {

    private enum Field: Hashable { case start, end }

    let status: ReadingStatus
    let onApply: (_ start: Date?, _ end: Date?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var field: Field = .start
    @State private var start: Date
    @State private var end: Date

    init(
        status: ReadingStatus,
        period: ReadingPeriod?,
        onApply: @escaping (_ start: Date?, _ end: Date?) -> Void
    ) {
        self.status = status
        self.onApply = onApply
        _start = State(initialValue: period?.start ?? Date())
        _end = State(initialValue: period?.end ?? Date())
        // watched 진입 시 종료일부터 보고 싶다면 여기서 field 초기값 조정 가능.
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if status == .watched {
                    Picker("기간", selection: $field) {
                        Text("시작").tag(Field.start)
                        Text("종료").tag(Field.end)
                    }
                    .pickerStyle(.segmented)
                }

                DatePicker(
                    "",
                    selection: editingDateBinding,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()

                Spacer()
            }
            .padding()
            .navigationTitle(status.dateText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("확인") { apply() }
                }
            }
        }
    }

    /// 상태별로 segment가 가리키는(또는 단일) 날짜를 편집하는 바인딩.
    private var editingDateBinding: Binding<Date> {
        switch status {
        case .watching:
            return $start
        case .quit:
            return $end
        case .watched:
            return field == .start ? $start : $end
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

// MARK: - Preview

#Preview {
    NavigationStack {
        NovelReviewView(
            viewModel: DefaultNovelReviewViewModel(
                novelID: NovelID(1),
                loadUseCase: PreviewLoadNovelReviewDraftUseCase(),
                saveUseCase: PreviewSaveNovelReviewUseCase()
            )
        )
    }
}

private struct PreviewLoadNovelReviewDraftUseCase: LoadNovelReviewDraftUseCase {
    func execute(novelID: NovelID) async throws(RepositoryError) -> NovelReviewDraft? { nil }
}

private struct PreviewSaveNovelReviewUseCase: SaveNovelReviewUseCase {
    func execute(draft: NovelReviewDraft) async throws(RepositoryError) {}
}
