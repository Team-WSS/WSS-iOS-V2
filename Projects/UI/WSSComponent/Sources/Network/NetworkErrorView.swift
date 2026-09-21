//
//  NetworkErrorView.swift
//  WSSComponent
//
//  Created by WonsunLee on 5/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import DesignSystem

public struct NetworkErrorView: View {
    private let error: RepositoryError
    public let action: () -> Void

    public init(error: RepositoryError = .unknown, action: @escaping () -> Void) {
        self.error = error
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 41) {
            WSSImage.imgEmptyCatQuestionmark.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 166, height: 160)

            VStack(spacing: 10) {
                Text(title)
                    .applyWSSFont(.title1, color: .wssBlack)

                Text(message)
                    .applyWSSFont(.body2, color: .wssGray300)
            }

            Button(action: action) {
                Text("페이지 다시 불러오기")
                    .applyWSSFont(.label1, color: .wssWhite)
                    .padding(.horizontal, 37)
                    .padding(.vertical, 14)
                    .background(Color.wssPrimary100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.wssWhite)
    }

    // MARK: - Copy (RepositoryError 3분류)

    // serverUnavailable(5xx) / networkUnavailable(오프라인)만 명시하고 나머지는 default("일시적 오류")로
    // 흡수한다 — authenticationRequired·notFound·forbidden·privateProfile은 설계상 이 뷰로 오지 않지만
    // (각각 로그인 라우팅·전용 안내로 분기), 실수로 넘어와도 크래시·오분류 없이 안전하게 폴백한다.
    private var title: String {
        switch error {
        case .serverUnavailable:
            return "서버에 문제가\n생겼어요"
        case .networkUnavailable:
            return "네트워크 연결에\n실패했어요"
        default:
            return "일시적인 오류가\n발생했어요"
        }
    }

    private var message: String {
        switch error {
        case .serverUnavailable:
            return "잠시 후 다시 시도해 주세요"
        case .networkUnavailable:
            return "연결 상태를 확인한 후\n다시 시도해 보세요"
        default:
            return "다시 시도해 주세요"
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        NetworkErrorView(error: .serverUnavailable) {}
        NetworkErrorView(error: .networkUnavailable) {}
        NetworkErrorView(error: .unknown) {}
    }
}
