//
//  NovelReviewViewModel.swift
//  NovelReviewFeature
//
//  Created by YunhakLee on 6/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain
import NovelReviewDomain

protocol NovelReviewViewModelInput {
    func selectStatus(_ status: ReadingStatus)
    func toggleAttractivePoint(_ point: AttractivePoint)
    func dismissError()
}

protocol NovelReviewViewModelOutput: ObservableObject {
    var selectedStatus: ReadingStatus { get }
    var selectedAttractivePoints: [AttractivePoint] { get }
    var errorMessage: String? { get }
}

typealias NovelReviewViewModel = NovelReviewViewModelInput & NovelReviewViewModelOutput

@MainActor
final class DefaultNovelReviewViewModel: NovelReviewViewModel {

    // MARK: - State

    @Published private var draft: NovelReviewDraft
    @Published private(set) var errorMessage: String?

    // MARK: - Output

    var selectedStatus: ReadingStatus { draft.status }
    var selectedAttractivePoints: [AttractivePoint] { draft.attractivePoints }

    // MARK: - Init

    init(novelID: NovelID) {
        self.draft = NovelReviewDraft(novelID: novelID, status: .watching)
    }
}

// MARK: - Input

extension DefaultNovelReviewViewModel {

    /// 읽기 상태 선택. ReadingStatus는 단일 값이라 새 값으로 바꾸면 기존 선택은 자동 해제된다.
    func selectStatus(_ status: ReadingStatus) {
        draft.changeStatus(status)
    }

    /// 매력 포인트 토글. 이미 선택돼 있으면 해제, 아니면 추가한다.
    /// 추가 시 최대 개수(3) 정책은 도메인(`NovelReviewDraft`)이 검증하며, 초과 시 throw → 사용자 메시지로 변환.
    func toggleAttractivePoint(_ point: AttractivePoint) {
        do {
            if draft.attractivePoints.contains(point) {
                draft.removeAttractivePoint(point)
            } else {
                try draft.addAttractivePoint(point)
            }
        } catch {
            handle(error: error)
        }
    }

    func dismissError() {
        errorMessage = nil
    }
}

// MARK: - Error Mapping

private extension DefaultNovelReviewViewModel {
    func handle(error: Error) {
        switch error {
        case NovelReviewDraft.ValidationError.tooManyAttractivePoints(let max):
            errorMessage = "매력 포인트는 최대 \(max)개까지 선택할 수 있어요"
        default:
            errorMessage = "잠시 후 다시 시도해 주세요"
        }
    }
}
