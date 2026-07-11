//
//  NovelDetailReviewSection.swift
//  NovelDetailFeature
//
//  Created by YunhakLee on 7/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NovelDomain
import DesignSystem
import WSSComponent

/// 유저 평가 영역 + CTA(관심 / 나도 한마디). 헤더의 회색(wssGray50) 배경을 이어받는다.
/// - 평가 없음: 읽기 상태 3종 셀렉터 — 탭한 상태를 seed로 평가 화면 진입.
/// - 평가 있음: 별점·기간 칩 + 상태바 — 상태바는 탭한 상태를, 그 외 영역(칩·여백)은 현재 상태를 seed로 진입.
struct NovelDetailReviewSection: View {

    let information: NovelInformation
    let novel: Novel
    let onSelectStatus: (ReadingStatus) -> Void
    let onToggleInterest: () -> Void
    let onCreateFeedTapped: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 22)
            reviewBox
            Spacer().frame(height: 12)
            ctaButtons
            Spacer().frame(height: 24)
        }
        .padding(.horizontal, 20)
        .background(Color.wssGray50)
    }

    // MARK: - Review Box

    @ViewBuilder
    private var reviewBox: some View {
        if let userReview = information.userReview {
            // 평가 있음: 상태바는 상태별 개별 진입점(탭한 상태를 seed), 그 외 영역(칩·여백)은
            // 현재 상태로 진입. 상태 Button이 hit-test 우선이라 바깥 onTapGesture와 공존한다
            // (중첩 Button은 hit-test가 불안정해 피한다).
            VStack(spacing: 0) {
                Spacer().frame(height: 12)
                reviewChips(userReview)
                Spacer().frame(height: 10)
                statusRow(selected: userReview.readingStatus)
                Spacer().frame(height: 15)
            }
            .frame(maxWidth: .infinity)
            .background(Color.wssWhite)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.wssGray80, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                onSelectStatus(userReview.readingStatus)
            }
        } else {
            // 평가 없음: 상태별 셀렉터. 각 상태가 개별 진입점.
            HStack(spacing: 0) {
                ForEach(Self.statusOrder, id: \.self) { status in
                    Button {
                        onSelectStatus(status)
                    } label: {
                        statusItem(status, isSelected: false)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if status != Self.statusOrder.last {
                        verticalDivider
                    }
                }
            }
            .padding(.vertical, 10)
            .frame(height: 74)
            .background(Color.wssWhite)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.wssGray80, lineWidth: 1)
            )
        }
    }

    private static let statusOrder = ReadingStatus.novelDetailDisplayOrder

    /// 별점 칩 + 독서 기간 칩. 값이 없는 칩은 표시하지 않는다.
    private func reviewChips(_ userReview: UserNovelReview) -> some View {
        HStack(spacing: 0) {
            if let rating = userReview.rating {
                chip(icon: WSSImage.icStarFilled.swiftUIImage,
                     text: String(format: "%.1f", rating.value))
                Spacer().frame(width: 8)
            }
            if let periodText = periodText(userReview.period) {
                chip(icon: WSSImage.icCalendar.swiftUIImage, text: periodText)
            }
        }
    }

    private func chip(icon: Image, text: String) -> some View {
        HStack(spacing: 5) {
            icon
                .resizable()
                .frame(width: 14, height: 14)
            Text(text)
                .applyWSSFont(.body5)
                .foregroundStyle(Color.wssGray300)
            WSSImage.icChevronRightMini.swiftUIImage
                .resizable()
                .frame(width: 14, height: 14)
        }
        .padding(.leading, 12)
        .padding(.trailing, 10)
        .frame(height: 23)
        .background(Color.wssWhite)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.wssGray80, lineWidth: 1)
        )
    }

    /// 기간 표기 — status 분기 대신 start/end 존재 여부로만 결정한다(도메인 normalize가 이미 상태별 날짜를 강제).
    private func periodText(_ period: ReadingPeriod?) -> String? {
        guard let period else { return nil }
        let start = period.start.map(Self.dateFormatter.string(from:))
        let end = period.end.map(Self.dateFormatter.string(from:))
        switch (start, end) {
        case let (start?, end?): return "\(start) ~ \(end)"
        case let (start?, nil):  return "\(start) ~"
        case let (nil, end?):    return "~ \(end)"
        case (nil, nil):         return nil
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yy. MM. dd"
        return formatter
    }()

    private func statusRow(selected: ReadingStatus) -> some View {
        HStack(spacing: 0) {
            ForEach(Self.statusOrder, id: \.self) { status in
                Button {
                    onSelectStatus(status)
                } label: {
                    statusItem(status, isSelected: status == selected)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if status != Self.statusOrder.last {
                    verticalDivider
                }
            }
        }
        .padding(.horizontal, 10)
    }

    private func statusItem(_ status: ReadingStatus, isSelected: Bool) -> some View {
        VStack(spacing: 0) {
            (isSelected ? status.fillImage : status.strokeImage)
                .resizable()
                .frame(width: 20, height: 20)
            Spacer().frame(height: 5)
            Text(status.statusName)
                .applyWSSFont(.body4)
                .foregroundStyle(isSelected ? Color.wssSecondary100 : Color.wssGray300)
        }
    }

    private var verticalDivider: some View {
        Rectangle()
            .fill(Color.wssGray70)
            .frame(width: 1, height: 36)
    }

    // MARK: - CTA

    private var ctaButtons: some View {
        HStack(spacing: 0) {
            interestButton
            Spacer().frame(width: 8)
            createFeedButton
        }
    }

    /// 관심 토글: on = primary50 배경 + 채운 하트 / off = 흰 배경 + 라인 하트.
    private var interestButton: some View {
        Button {
            onToggleInterest()
        } label: {
            HStack(spacing: 0) {
                (isInterested ? WSSImage.icHeartFilled.swiftUIImage : WSSImage.icHeartEmpty.swiftUIImage)
                    .resizable()
                    .frame(width: 20, height: 20)
                Spacer().frame(width: 9)
                Text("관심")
                    .applyWSSFont(.body4)
                    .foregroundStyle(Color.wssPrimary100)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(isInterested ? Color.wssPrimary50 : Color.wssWhite)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.wssPrimary100, lineWidth: 1)
            )
            .contentShape(Rectangle())
            // 하트 에셋 교체·배경색의 기본 크로스페이드를 짧게 고정
            // (미설정 시 느리게 번진다 — NovelReview 읽기 상태 선택과 동일한 처방).
            .animation(.easeInOut(duration: 0.1), value: isInterested)
        }
        .buttonStyle(.plain)
    }

    private var isInterested: Bool {
        novel.isInterested == true
    }

    private var createFeedButton: some View {
        Button {
            onCreateFeedTapped()
        } label: {
            HStack(spacing: 0) {
                WSSImage.icPencil.swiftUIImage
                    .resizable()
                    .frame(width: 20, height: 20)
                Spacer().frame(width: 9)
                Text("나도 한마디")
                    .applyWSSFont(.body4)
                    .foregroundStyle(Color.wssWhite)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(Color.wssPrimary100)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
