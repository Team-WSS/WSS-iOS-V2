//
//  CrossScreenFeedback.swift
//  WSS-iOS
//
//  Created by YunhakLee on 9/1/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import WSSComponent

/// 크로스스크린 완료 피드백 채널(#236) — push된 화면에서 끝난 일의 완료 토스트를 그 화면이 pop된
/// **뒤** 복귀 화면 위에 띄운다. V1의 전역 `NotificationCenter` 배관(`feedEdited`·`NovelReviewed`·
/// `BlockUser`)을 **콜백 seam + 탭 Root 소유 상태**로 재설계한 것:
/// - 발화 화면(Feature)은 완료 콜백만 올린다(`onUserBlocked`/`onSaved`/`onSubmitted`) — 자기는 pop되므로
///   토스트를 직접 못 띄운다.
/// - 각 탭 Root가 `CrossScreenFeedbackState` 하나를 `@State`로 들고, 콜백에서 `present(_:)`를 부르고,
///   자기 `NavigationStack` **컨테이너**에 `.showCrossScreenFeedbackToast`를 건다 — pop 후 최상단이 된
///   직전 뷰 위에 뜬다(#221 blockUser 배선의 일반화 — 그 4벌 복붙을 이 채널로 흡수).
///
/// 발화가 일어난 **그 탭**에서만 뜬다(V1은 전역 브로드캐스트를 피드 탭 하나만 캐치했다 — V2가 더 정확).
enum CrossScreenFeedback: Equatable {
    /// 타유저 차단 성공 — "{nickname}님을 차단했어요" (UserPage가 pop되며 발화)
    case userBlocked(nickname: String)
    /// 피드 작성/수정 완료 — "작성 완료!" (CreateFeedView가 dismiss되며 발화, V1 `feedEdited` parity)
    case feedEdited
    /// 작품 평가 저장 완료 — "평가 완료!" (NovelReviewView가 dismiss되며 발화, V1 `NovelReviewed` parity)
    case novelReviewed

    var toastType: WSSToastType {
        switch self {
        case .userBlocked(let nickname): .blockUser(nickname: nickname)
        case .feedEdited: .feedEdited
        case .novelReviewed: .novelReviewed
        }
    }
}

/// 표시 여부(`isPresented`)와 마지막 피드백 값을 분리 보유한다 — 토스트가 사라지는 애니메이션 동안에도
/// 값이 남아 있어야 문구가 페이드아웃 중에 바뀌지 않는다(값을 nil로 비우는 방식이면 fallback 문구가 스친다).
struct CrossScreenFeedbackState {
    fileprivate var isPresented = false
    fileprivate var feedback: CrossScreenFeedback?

    mutating func present(_ feedback: CrossScreenFeedback) {
        self.feedback = feedback
        isPresented = true
    }
}

extension View {
    /// ⚠️ 각 탭 Root의 `NavigationStack` **컨테이너**에 걸어야 한다 — pop되는 화면 안에 걸면 화면과 함께
    /// 사라진다(#221 크로스스크린 토스트 패턴).
    func showCrossScreenFeedbackToast(_ state: Binding<CrossScreenFeedbackState>) -> some View {
        showWSSToast(
            isPresented: state.isPresented,
            type: state.wrappedValue.feedback?.toastType ?? .unknownError
        )
    }
}
