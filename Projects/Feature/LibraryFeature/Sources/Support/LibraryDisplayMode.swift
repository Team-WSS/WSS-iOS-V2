//
//  LibraryDisplayMode.swift
//  LibraryFeature
//
//  Created by YunhakLee on 7/30/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

/// 서재 목록의 표시 모드 — VM 처리가 필요 없는 순수 표시 상태라 각 View가 `@State`로 소유한다.
/// 내 서재(캡슐 세그먼트)와 타유저 서재(아이콘 버튼 하나)가 컨트롤 모양만 다르고 의미는 같아 여기 공유한다.
enum LibraryDisplayMode {
    case grid
    case list

    /// 타유저 서재의 토글 — 두 모드뿐이라 탭하면 반대편으로 간다.
    var toggled: LibraryDisplayMode {
        self == .grid ? .list : .grid
    }
}

/// 모드 아이콘(12×12) — 디자인 시스템에 에셋이 없어 도형으로 그린다.
/// **두 화면이 같은 그림을 써야** 같은 뜻의 컨트롤이 화면마다 달라 보이지 않는다.
struct LibraryDisplayModeIcon: View {

    let mode: LibraryDisplayMode
    let color: Color

    var body: some View {
        switch mode {
        case .grid: gridIcon
        case .list: listIcon
        }
    }

    private var gridIcon: some View {
        VStack(spacing: 2) {
            ForEach(0..<2, id: \.self) { _ in
                HStack(spacing: 2) {
                    ForEach(0..<2, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(color)
                            .frame(width: 5, height: 5)
                    }
                }
            }
        }
    }

    private var listIcon: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(color)
                        .frame(width: 2, height: 2)
                    Capsule()
                        .fill(color)
                        .frame(width: 7, height: 2)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 20) {
        LibraryDisplayModeIcon(mode: .grid, color: .wssBlack)
        LibraryDisplayModeIcon(mode: .list, color: .wssGray100)
    }
    .padding()
}
