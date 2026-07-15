//
//  FlowLayout.swift
//  WSSComponent
//
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

/// 가변 개수의 자식(칩 등)을 가로로 배치하다 폭이 넘치면 다음 줄로 흘려보내는 레이아웃.
public struct FlowLayout: Layout {
    private let horizontalSpacing: CGFloat
    private let verticalSpacing: CGFloat

    public init(horizontalSpacing: CGFloat = 6, verticalSpacing: CGFloat = 8) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)

        let totalHeight = rows.reduce(0) { $0 + $1.height }
            + verticalSpacing * CGFloat(max(rows.count - 1, 0))
        let widestRow = rows.map(\.width).max() ?? 0
        return CGSize(width: min(maxWidth, widestRow), height: totalHeight)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let subview = subviews[index]
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y),
                              anchor: .topLeading,
                              proposal: ProposedViewSize(size))
                x += size.width + horizontalSpacing
            }
            y += row.height + verticalSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            var current = rows[rows.count - 1]
            let projectedWidth = current.indices.isEmpty
                ? size.width
                : current.width + horizontalSpacing + size.width

            if projectedWidth > maxWidth, !current.indices.isEmpty {
                rows.append(Row(indices: [index], width: size.width, height: size.height))
            } else {
                current.indices.append(index)
                current.width = projectedWidth
                current.height = max(current.height, size.height)
                rows[rows.count - 1] = current
            }
        }
        return rows
    }
}

#Preview {
    FlowLayout(horizontalSpacing: 6, verticalSpacing: 12) {
        ForEach(["판타지", "현판", "로맨스", "로판", "무협", "미스터리", "드라마", "라노벨", "BL"], id: \.self) { genre in
            Text(genre)
                .padding(.horizontal, 13)
                .padding(.vertical, 7)
                .background(Color.gray.opacity(0.15))
                .clipShape(Capsule())
        }
    }
    .padding()
}
