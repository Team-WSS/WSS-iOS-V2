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
import DesignSystem
import WSSComponent

// 작품 평가(리뷰 초안) 화면. WSSComponent의 Presentation 확장(아이콘/라벨)과 DesignSystem 토큰으로 구성.
// "얇은 ViewModel" 원칙: 카피·포맷·색 등 표기는 전부 View에서 결정한다.
struct NovelReviewView: View {

    @State private var viewModel: NovelReviewViewModel
    @State private var isPeriodSheetPresented = false
    @Environment(\.dismiss) private var dismiss

    /// 네비게이션 타이틀. 진입 이전 화면이 Factory를 통해 주입한다.
    private let title: String

    init(viewModel: NovelReviewViewModel, title: String) {
        self._viewModel = State(initialValue: viewModel)
        self.title = title
    }

    var body: some View {
        // 로딩을 if/else 트리 교체가 아니라 overlay로 둔다. isLoading 토글 시 루트(content) 정체성이
        // 유지돼야, 로드 완료 순간과 뒤로가기(dismiss)가 겹쳐도 진행 중인 pop이 취소되지 않는다.
        content
        .overlay {
            if viewModel.state.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.wssWhite)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar { toolbarContent }
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
        .showWSSToast(isPresented: toastBinding, type: toastType)
        // 알럿 버튼은 자동으로 닫히지 않으므로(버튼 액션만 호출), 각 액션이 직접 isPresented를 내린다.
        .showWSSAlert(
            isPresented: stopAlertBinding,
            type: .stopNovelReview,
            buttonActions: [
                { viewModel.handle(.confirmStop) },  // "그만하기" → 화면 닫기
                { viewModel.handle(.keepWriting) }   // "계속 작성" → 머무름
            ]
        )
        .onChange(of: viewModel.state.shouldDismiss) { _, shouldDismiss in
            guard shouldDismiss else { return }
            dismiss()
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 0) {
                statusSection
                periodSection

                Spacer().frame(height: 14)
                sectionDivider
                Spacer().frame(height: 24)

                ratingSection

                Spacer().frame(height: 38)
                sectionDivider
                Spacer().frame(height: 24)

                attractivePointSection

                Spacer().frame(height: 24)
                sectionDivider
                Spacer().frame(height: 24)

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

// MARK: - Toolbar

private extension NovelReviewView {

    /// 좌측 뒤로가기(닫기 요청) + 우측 완료(저장). 저장 중엔 완료 자리에 스피너를 띄우고 비활성화한다.
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                viewModel.handle(.requestClose)
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
                    VStack(spacing: 0) {
                        status.fillImage
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundStyle(imageColor)

                        Spacer().frame(height: 5)

                        Text(status.statusName)
                            .applyWSSFont(.body5)
                            .foregroundStyle(textColor)
                    }
                    .padding(.vertical, 10)
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
            Text("\(ReviewDateFormatter.period.string(from: start)) ~ \(ReviewDateFormatter.period.string(from: end))")
        case let (start?, nil):
            Text("\(ReviewDateFormatter.period.string(from: start)) ~")
        case let (nil, end?):
            Text("~ \(ReviewDateFormatter.period.string(from: end))")
        case (nil, nil):
            Text("본 날짜 추가")
        }
    }

    /// 별점 — 별 탭/슬라이드로 0.5 단위 부여. 0.0은 "평점 없음"(nil)으로 매핑(도메인 Rating은 0.5부터).
    var ratingSection: some View {
        VStack(spacing: 0) {
            Text("별점")
                .applyWSSFont(.title3)
                .foregroundStyle(Color.wssBlack)

            Spacer().frame(height: 14)

            StarRatingView(rating: viewModel.state.draft.rating?.value ?? 0) { value in
                viewModel.handle(.updateRating(value))
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// 매력 포인트 — 6개 중 최대 3개 토글(초과는 ViewModel이 막고 알림).
    /// 아이콘은 단색 에셋이라 `.template`로 틴팅: 선택=primary, 미선택=회색.
    var attractivePointSection: some View {
        VStack(spacing: 0) {
            Text("매력포인트")
                .applyWSSFont(.title3)
                .foregroundStyle(Color.wssBlack)

            Spacer().frame(height: 14)

            HStack(spacing: 0) {
                ForEach(AttractivePoint.allCases, id: \.self) { point in
                    let isSelected = viewModel.state.draft.attractivePoints.contains(point)
                    let imageColor = isSelected ? Color.wssPrimary100 : Color.wssGray80
                    let textColor = isSelected ? Color.wssPrimary100 : Color.wssGray200

                    Button {
                        viewModel.handle(.toggleAttractivePoint(point))
                    } label: {
                        VStack(spacing: 0) {
                            point.iconImage
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                                .foregroundStyle(imageColor)

                            Spacer().frame(height: 6)

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
        VStack(spacing: 0) {
            Text("키워드")
                .applyWSSFont(.title3)
                .foregroundStyle(Color.wssBlack)

            Spacer().frame(height: 14)

            WSSSearchBarButton(
                placeholder: "작품을 나타내는 키워드는?",
                placeholderAlignment: .center
            ) {
                // TODO: 키워드 탐색뷰로 이동 (실제 액션은 추후 연결)
                print("키워드 탐색뷰로 이동")
            }
        }
    }
}

// MARK: - Presentation

private extension NovelReviewView {

    /// 에러 유무 → 토스트 표시 여부. 자동 닫힘(모디파이어가 false로 set)·재탭 시 에러를 비운다.
    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedError != nil },
            set: { if !$0 { viewModel.handle(.dismissError) } }
        )
    }

    /// 작성 중단 알럿 표시 여부. 실제 닫기 판단은 ViewModel이 하고, View는 표시 상태만 바인딩한다.
    var stopAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isStopAlertPresented },
            set: { if !$0 { viewModel.handle(.keepWriting) } }
        )
    }

    /// 의미 에러(VM) → 토스트 타입(표현)은 View가 매핑한다. nil일 땐 모디파이어가 숨기므로 표시되지 않는다.
    var toastType: WSSToastType {
        switch viewModel.state.presentedError {
        case .attractivePointLimit(let max):    .selectionOverLimit(count: max)
        case .unknown, .none:                   .unknownError
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NovelReviewView(
            viewModel: NovelReviewViewModel(
                novelID: NovelID(1),
                status: .watching,
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
