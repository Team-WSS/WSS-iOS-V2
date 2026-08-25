//
//  WSSLibrarySection.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 7/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

/// 서재 통계 섹션(관심/보는중/봤어요/하차 4칸). `UserPageFeature`의 MyPage·UserPage가 원본이고(#200),
/// 두 화면이 완전히 동일한 배경·숫자 컬러(`wssPrimary20`+`wssPrimary100`)로 통일되며 승격했다
/// (사용자 명시 요청, 2026-08-25) — 이 컴포넌트는 도메인 엔티티(`NovelDomain.RegisteredNovelStats`)를
/// 모른다(`WSSComponent`는 `BaseDomain` 외 상위 Domain을 의존하지 않는다, `UI/CLAUDE.md` 참고).
/// 4개 카운트를 값으로만 받고, 엔티티 → 값 매핑(옵셔널 처리 포함, `stats?.interest ?? 0` 등)은 호출부
/// (Feature)가 한다.
public struct WSSLibrarySection: View {

    private let interest: Int
    private let watching: Int
    private let watched: Int
    private let quit: Int
    private let action: () -> Void

    public init(interest: Int, watching: Int, watched: Int, quit: Int, action: @escaping () -> Void) {
        self.interest = interest
        self.watching = watching
        self.watched = watched
        self.quit = quit
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                libraryItem(count: interest, title: "관심")
                libraryItem(count: watching, title: "보는중")
                libraryItem(count: watched, title: "봤어요")
                libraryItem(count: quit, title: "하차")
            }
            .padding(.vertical, 14.5)
            .background(Color.wssPrimary20)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
    }

    private func libraryItem(count: Int, title: String) -> some View {
        VStack(spacing: 2) {
            Text(String(count))
                .applyWSSFont(.title2)
                .foregroundStyle(Color.wssPrimary100)
                .lineLimit(1)

            Text(title)
                .applyWSSFont(.body5)
                .foregroundStyle(Color.wssBlack)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    WSSLibrarySection(interest: 4, watching: 30, watched: 1312, quit: 24) {
        print("서재 뷰로 이동")
    }
}
