//
//  LibraryRatingSlider.swift
//  LibraryFeature
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

// 별점 범위 슬라이더 — 0.0~5.0을 0.5 단위로 스냅하는 양쪽 핸들 슬라이더.
// 시스템 Slider는 단일 값만 지원해 화면 전용으로 직접 그린다.
//
// 좌표계는 구 WSSiOS `WSSRangeSlider`(UIKit)와 같다 — 트랙이 **핸들 반지름만큼 안쪽**(x: 8 ~ width-8)에
// 놓여 양 끝값에서도 핸들이 슬라이더 밖으로 잘리지 않는다. 트랙을 전체 폭으로 두면 0.0/5.0에서 핸들이 반쪽 난다.
struct LibraryRatingSlider: View {

    let min: Float
    let max: Float
    /// "별점 없음" 토글이 켜지면 편집 잠금 + 회색 표시.
    let isDisabled: Bool
    let onChange: (Float, Float) -> Void

    private enum Handle {
        case lower
        case upper
    }

    /// 드래그 중 잡고 있는 핸들 — 한 번 정하면 손을 뗄 때까지 유지한다(정본 `isDraggingLower/Upper`).
    @State private var activeHandle: Handle?

    private static let bounds: ClosedRange<Float> = 0.0...5.0
    private static let step: Float = 0.5
    /// 두 핸들이 같은 값이 되지 않도록 항상 한 칸은 벌린다(예: max 4.5면 min은 4.0까지).
    private static let minimumGap: Float = step
    private static let handleSize: CGFloat = 16
    private static let trackHeight: CGFloat = 4
    private static let tickSize = CGSize(width: 1, height: 2)
    private static let tickCount = 11

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                track(width: width)
                ticks(width: width)
                activeSegment(width: width)
                handle(at: min, width: width)
                handle(at: max, width: width)
            }
            .frame(height: Self.handleSize)
            // 트랙(4px)이 얇아 그대로는 잡기 어렵다 — 슬라이더 전체 높이를 히트 영역으로.
            .contentShape(Rectangle())
            .gesture(dragGesture(width: width))
        }
        .frame(height: Self.handleSize)
    }

    // MARK: - Parts

    private func track(width: CGFloat) -> some View {
        Capsule()
            .fill(isDisabled ? Color.wssGray70 : Color.wssPrimary50)
            .frame(width: Swift.max(width - Self.handleSize, 0), height: Self.trackHeight)
            .offset(x: Self.handleSize / 2)
    }

    private func activeSegment(width: CGFloat) -> some View {
        let minX = position(of: min, width: width)
        let maxX = position(of: max, width: width)
        return Capsule()
            .fill(isDisabled ? Color.wssGray200 : Color.wssPrimary100)
            .frame(width: Swift.max(maxX - minX, 0), height: Self.trackHeight)
            .offset(x: minX)
    }

    private func ticks(width: CGFloat) -> some View {
        ForEach(0..<Self.tickCount, id: \.self) { index in
            let value = Self.bounds.lowerBound + Float(index) * Self.step
            Rectangle()
                .fill(isDisabled ? Color.wssGray100 : Color.wssPrimary100)
                .frame(width: Self.tickSize.width, height: Self.tickSize.height)
                .offset(x: position(of: value, width: width) - Self.tickSize.width / 2)
        }
    }

    private func handle(at value: Float, width: CGFloat) -> some View {
        Circle()
            .fill(Color.wssWhite)
            .shadow(color: .wssBlack.opacity(0.2), radius: 4, y: 2)
            .frame(width: Self.handleSize, height: Self.handleSize)
            .offset(x: position(of: value, width: width) - Self.handleSize / 2)
    }

    // MARK: - Geometry

    /// 값 → 트랙 위 x. 트랙은 핸들 반지름만큼 안쪽에서 시작·끝난다.
    private func position(of value: Float, width: CGFloat) -> CGFloat {
        let trackWidth = Swift.max(width - Self.handleSize, 0)
        let fraction = CGFloat((value - Self.bounds.lowerBound) / (Self.bounds.upperBound - Self.bounds.lowerBound))
        return Self.handleSize / 2 + trackWidth * fraction
    }

    private func value(atX x: CGFloat, width: CGFloat) -> Float {
        let trackWidth = Swift.max(width - Self.handleSize, 1)
        let ratio = (x - Self.handleSize / 2) / trackWidth
        let fraction = Float(Swift.min(Swift.max(ratio, 0), 1))
        let raw = Self.bounds.lowerBound + fraction * (Self.bounds.upperBound - Self.bounds.lowerBound)
        let snapped = (raw / Self.step).rounded() * Self.step
        return Swift.min(Swift.max(snapped, Self.bounds.lowerBound), Self.bounds.upperBound)
    }

    /// 잡은 핸들만 움직인다. 두 핸들이 교차하지 않게 상대 핸들 값으로 클램프.
    ///
    /// ⚠️ 어느 핸들을 움직일지는 **드래그 시작에 한 번만** 정한다. 매 이벤트마다 "가까운 쪽"을 다시 고르면
    /// 두 핸들이 가까워진 순간 반대편으로 넘어간다 — 아래 핸들을 4.0까지 끌고 온 뒤 4.5로 가면
    /// 4.5는 4.0·5.0에서 거리가 같아 판정이 뒤집혀 **5.0에 있던 위쪽 핸들이 끌려오던 버그**.
    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                guard !isDisabled else { return }
                let x = gesture.location.x
                // 첫 이벤트(translation == .zero)면 새 드래그 세션 — 그때만 잡을 핸들을 고른다.
                // onEnded가 취소로 유실돼도 다음 터치에서 되살아나도록 세션 시작을 직접 감지한다.
                let handle = (gesture.translation == .zero ? nil : activeHandle)
                    ?? nearestHandle(toX: x, width: width)
                activeHandle = handle

                let tapped = value(atX: x, width: width)
                switch handle {
                case .lower:
                    // 상대 핸들에 한 칸 못 미치는 지점까지만. bounds 클램프는 이상 입력(외부에서 min == max로
                    // 주입된 필터) 때 경계를 벗어나지 않게 하는 방어다.
                    let newMin = Swift.max(Swift.min(tapped, max - Self.minimumGap), Self.bounds.lowerBound)
                    onChange(newMin, max)
                case .upper:
                    let newMax = Swift.min(Swift.max(tapped, min + Self.minimumGap), Self.bounds.upperBound)
                    onChange(min, newMax)
                }
            }
            .onEnded { _ in
                activeHandle = nil
            }
    }

    /// 터치 지점에서 가까운 핸들.
    /// 겹침 분기는 슬라이더 조작으로는 도달할 수 없지만(항상 한 칸 벌어짐), 외부에서 min == max인 필터가
    /// 주입되면 그 상태에서도 터치 방향으로 다시 벌릴 수 있어야 해서 남긴다.
    private func nearestHandle(toX x: CGFloat, width: CGFloat) -> Handle {
        let lowerX = position(of: min, width: width)
        let upperX = position(of: max, width: width)

        guard min != max else { return x >= lowerX ? .upper : .lower }

        return abs(x - lowerX) <= abs(x - upperX) ? .lower : .upper
    }
}
