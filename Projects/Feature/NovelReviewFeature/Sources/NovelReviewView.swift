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

    init(viewModel: ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 24) {
            if viewModel.isLoading {
                ProgressView()
            } else {
                statusSection
                attractivePointSection
                completeButton
            }
        }
        .padding()
        .navigationTitle("작품 평가")
        .onAppear {
            viewModel.load()
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
