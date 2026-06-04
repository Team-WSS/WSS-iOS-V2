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
struct NovelReviewView<ViewModel: NovelReviewViewModel>: View {

    @StateObject private var viewModel: ViewModel
    @State private var isPeriodSheetPresented = false
    @Environment(\.dismiss) private var dismiss

    /// 네비게이션 타이틀. 진입 이전 화면이 Factory를 통해 주입한다.
    private let title: String

    init(viewModel: ViewModel, title: String) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.title = title
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
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
                    viewModel.save()
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Text("완료")
                            .applyWSSFont(.title2)
                            .foregroundStyle(Color.wssPrimary100)
                    }
                }
                .disabled(viewModel.isSaving)
            }
        }
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
                let isSelected = viewModel.selectedStatus == status
                let imageColor = isSelected ? Color.wssPrimary100 : Color.wssGray80
                let textColor = isSelected ? Color.wssPrimary100 : Color.wssGray200

                Button {
                    viewModel.selectStatus(status)
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
                .underline()
                .frame(width: 83, height: 44, alignment: .center)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 선택된 기간 표시. 도메인 `normalized(for:)`가 상태에 맞는 날짜만 채워두므로
    /// status로 분기하지 않고 start/end 존재 여부로만 표기한다(둘 다=기간, 하나=단일 날짜).
    @ViewBuilder
    var periodValueLabel: some View {
        switch (viewModel.selectedPeriod?.start, viewModel.selectedPeriod?.end) {
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

            StarRatingView(rating: viewModel.selectedRating?.value ?? 0) { value in
                print(value)
                viewModel.updateRating(value)
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
                    let isSelected = viewModel.selectedAttractivePoints.contains(point)
                    let imageColor = isSelected ? Color.wssPrimary100 : Color.wssGray80
                    let textColor = isSelected ? Color.wssPrimary100 : Color.wssGray200

                    Button {
                        viewModel.toggleAttractivePoint(point)
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
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.dismissError() }
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
            ),
            title: "당신의 이해를 돕기 위하여"
        )
    }
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
