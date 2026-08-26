//
//  WSSRangeSlider.swift
//  WSSComponent
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

/// 범위(min~max) 슬라이더 — 값을 `step` 단위로 스냅하는 양쪽 핸들 슬라이더.
/// 시스템 `Slider`는 단일 값만 지원해 직접 그린다. `LibraryFeature`(별점 범위)·`SearchFeature`(상세탐색
/// 별점 범위) 둘 다 같은 모양(0.0~5.0, 0.5 단위)이라 중복을 피해 여기로 승격했다(#185).
///
/// 좌표계는 구 WSSiOS `WSSRangeSlider`(UIKit)와 같다 — 트랙이 **핸들 반지름만큼 안쪽**(x: 8 ~ width-8)에
/// 놓여 양 끝값에서도 핸들이 슬라이더 밖으로 잘리지 않는다. 트랙을 전체 폭으로 두면 0.0/5.0에서 핸들이 반쪽 난다.
///
/// 드래그 중 핸들이 한 스텝 넘어갈 때마다 `HapticManager.selection()`으로 가벼운 햅틱을 울린다 — 매
/// `onChanged` 이벤트가 아니라 **스냅된 값이 실제로 바뀔 때만**(`lastHapticValue` 비교) 울려야 손가락을
/// 대고만 있어도 진동이 나는 걸 막는다.
public struct WSSRangeSlider: View {

    let min: Float
    let max: Float
    /// 편집 잠금 + 회색 표시(예: LibraryFeature의 "별점 등록 안된 작품만 보기" 토글 켜짐).
    let isDisabled: Bool
    let onChange: (Float, Float) -> Void

    public let bounds: ClosedRange<Float>
    public let step: Float

    private enum Handle {
        case lower
        case upper
    }

    /// 드래그 중 잡고 있는 핸들 — 한 번 정하면 손을 뗄 때까지 유지한다(정본 `isDraggingLower/Upper`).
    @State private var activeHandle: Handle?
    /// 마지막으로 햅틱을 울린 값 — 이 값과 달라질 때만(=한 스텝 이동할 때만) 다시 울린다.
    /// 매 `onChanged` 이벤트마다 울리면 손가락을 붙이고만 있어도 진동이 난다.
    @State private var lastHapticValue: Float?

    private static let handleSize: CGFloat = 16
    private static let trackHeight: CGFloat = 4
    private static let tickSize = CGSize(width: 1, height: 2)

    public init(
        min: Float,
        max: Float,
        isDisabled: Bool,
        bounds: ClosedRange<Float> = 0.0...5.0,
        step: Float = 0.5,
        onChange: @escaping (Float, Float) -> Void
    ) {
        self.min = min
        self.max = max
        self.isDisabled = isDisabled
        self.bounds = bounds
        self.step = step
        self.onChange = onChange
    }

    /// 두 핸들이 같은 값이 되지 않도록 항상 한 칸은 벌린다(예: max 4.5면 min은 4.0까지).
    private var minimumGap: Float { step }
    private var tickCount: Int { Int(((bounds.upperBound - bounds.lowerBound) / step).rounded()) + 1 }

    public var body: some View {
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
        ForEach(0..<tickCount, id: \.self) { index in
            let value = bounds.lowerBound + Float(index) * step
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
        let fraction = CGFloat((value - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound))
        return Self.handleSize / 2 + trackWidth * fraction
    }

    private func value(atX x: CGFloat, width: CGFloat) -> Float {
        let trackWidth = Swift.max(width - Self.handleSize, 1)
        let ratio = (x - Self.handleSize / 2) / trackWidth
        let fraction = Float(Swift.min(Swift.max(ratio, 0), 1))
        let raw = bounds.lowerBound + fraction * (bounds.upperBound - bounds.lowerBound)
        let snapped = (raw / step).rounded() * step
        return Swift.min(Swift.max(snapped, bounds.lowerBound), bounds.upperBound)
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
                let isNewSession = gesture.translation == .zero
                let handle = (isNewSession ? nil : activeHandle) ?? nearestHandle(toX: x, width: width)
                activeHandle = handle
                // 세션 시작 시점의 "이미 그 값"으로 기준을 잡아야, 손가락을 대기만 하고 아직 옮기지 않은
                // 순간에는 울리지 않는다(다음 스텝으로 실제로 넘어갈 때만 반응해야 하므로).
                if isNewSession {
                    lastHapticValue = (handle == .lower ? min : max)
                }

                let tapped = value(atX: x, width: width)
                switch handle {
                case .lower:
                    // 상대 핸들에 한 칸 못 미치는 지점까지만. bounds 클램프는 이상 입력(외부에서 min == max로
                    // 주입된 필터) 때 경계를 벗어나지 않게 하는 방어다.
                    let newMin = Swift.max(Swift.min(tapped, max - minimumGap), bounds.lowerBound)
                    triggerHapticIfStepChanged(to: newMin)
                    onChange(newMin, max)
                case .upper:
                    let newMax = Swift.min(Swift.max(tapped, min + minimumGap), bounds.upperBound)
                    triggerHapticIfStepChanged(to: newMax)
                    onChange(min, newMax)
                }
            }
            .onEnded { _ in
                activeHandle = nil
                lastHapticValue = nil
            }
    }

    /// 잡은 핸들이 새 스텝 값으로 넘어갈 때만 가벼운 햅틱(`.selection()`, 정렬·필터 전환과 같은 급의 반응).
    private func triggerHapticIfStepChanged(to newValue: Float) {
        guard lastHapticValue != newValue else { return }
        lastHapticValue = newValue
        HapticManager.selection()
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

// MARK: - Preview

#Preview {
    @Previewable @State var min: Float = 3.5
    @Previewable @State var max: Float = 5.0

    VStack(spacing: 40) {
        WSSRangeSlider(min: min, max: max, isDisabled: false) { newMin, newMax in
            min = newMin
            max = newMax
        }
        WSSRangeSlider(min: 1.0, max: 4.0, isDisabled: true) { _, _ in }
    }
    .padding()
}
