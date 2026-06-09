//
//  ReadingPeriodSheet.swift
//  NovelReviewFeature
//
//  Created by YunhakLee on 6/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import DesignSystem
import NovelReviewDomain
import WSSComponent

/// 독서 기간 선택 sheet. 상태에 따라 입력 형태가 다르다.
/// - watching: 시작 날짜 1개 (높이 320)
/// - quit: 종료 날짜 1개 (높이 320)
/// - watched: segment로 시작/종료를 전환하며 한 시트에서 둘 다 선택 (높이 394)
///
/// 입력 상태·순서 보정 정책은 `ReadingPeriodSheetViewModel`에 있고, 이 View는 레이아웃과 표기만 담당한다.
/// 배경은 흰색, 완료는 `WSSCTAButton`, 그 아래 "날짜 삭제"(기간 제거). 취소는 우상단 X 또는 배경 탭(시트 dismiss).
struct ReadingPeriodSheet: View {

    @StateObject private var viewModel: ReadingPeriodSheetViewModel

    @Environment(\.dismiss) private var dismiss
    @Namespace private var segmentNamespace

    /// 완료/삭제 결과를 부모로 전달. 부모가 `updatePeriod` 호출 + 시트 dismiss를 담당한다.
    /// VM은 순수 상태/파생만 들고, 결과 발화(콜백 호출)는 View가 한다.
    private let onApply: (_ start: Date?, _ end: Date?) -> Void

    init(
        status: ReadingStatus,
        period: ReadingPeriod?,
        onApply: @escaping (_ start: Date?, _ end: Date?) -> Void
    ) {
        self._viewModel = StateObject(
            wrappedValue: ReadingPeriodSheetViewModel(
                status: status,
                period: period,
                maxDate: Calendar.current.startOfDay(for: Date())
            )
        )
        self.onApply = onApply
    }

    /// 시작/종료를 모두 고르는 watched만 더 높다.
    private var sheetHeight: CGFloat {
        viewModel.status == .watched ? 394 : 320
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if viewModel.status == .watched {
                segmentedField
                    .padding(.bottom, 7)
            }

            // watched의 field 전환 시 편집 날짜가 바뀌면 휠이 editingDateBinding 변화를 감지해 스스로 재정렬한다.
            // (id 재생성 ❌ — 재생성하면 새 ScrollView가 맨 위로 정렬됐다가 점프해 번쩍인다.)
            WSSDateWheel(date: editingDateBinding, maxDate: viewModel.maxDate)
                .padding(.top, 10)
                .padding(.bottom, 30)

            WSSCTAButton(title: "완료") {
                let result = viewModel.result
                onApply(result.start, result.end)
            }

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
            if viewModel.status != .watched {
                Text(viewModel.status.dateText)
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
            segmentItem(.start, label: "시작 날짜", date: viewModel.state.start)
            segmentItem(.end, label: "종료 날짜", date: viewModel.state.end)
        }
        .padding(2)
        .background(Color.wssGray50)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        // 애니메이션을 segment에만 한정한다. 전역 withAnimation을 쓰면 .id(field)로 재생성되는
        // 휠의 scrollPosition 이동까지 애니메이션을 타서 숫자가 주르륵 스크롤된다.
        .animation(.snappy(duration: 0.25), value: viewModel.state.field)
    }

    private func segmentItem(_ target: ReadingPeriodSheetViewModel.Field, label: String, date: Date) -> some View {
        let isSelected = viewModel.state.field == target
        let color = isSelected ? Color.wssBlack : Color.wssGray200

        return VStack(spacing: 2) {
            Text(label)
                .applyWSSFont(.title2)
            Text(ReviewDateFormatter.segment.string(from: date))
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
            viewModel.handle(.selectField(target))
        }
    }

    /// 휠이 편집하는 날짜 바인딩. set은 휠이 이미 오늘로 클램프한 값을 VM에 넘겨 순서를 보정한다.
    private var editingDateBinding: Binding<Date> {
        Binding(
            get: { viewModel.editingDate },
            set: { viewModel.handle(.updateEditingDate($0)) }
        )
    }
}

// MARK: - Preview

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
