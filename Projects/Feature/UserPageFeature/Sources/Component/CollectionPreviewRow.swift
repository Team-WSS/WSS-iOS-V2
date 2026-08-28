//
//  CollectionPreviewRow.swift
//  UserPageFeature
//
//  Created by Guryss on 8/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import CollectionDomain
import DesignSystem
import WSSComponent

/// 컬렉션 미리보기 항목들(대표 표지 1장씩) — `CollectionSection`(마이페이지, "컬렉션 N개" 헤더)과
/// `UserPageView`의 컬렉션 섹션("컬렉션" 타이틀 + 화살표, 헤더 스타일이 다르다)이 공유한다.
/// `LibrarySection`/`GenreSection`이 "콘텐츠만" 재사용되고 타이틀 행은 화면마다 로컬로 짓는 것과
/// 동일한 분리 — 헤더 스타일이 화면마다 달라 헤더까지 통째로 공용화하면 오히려 분기가 늘어난다.
struct CollectionPreviewRow: View {

    let previews: [CollectionPreview]
    /// 항목 탭 → 그 컬렉션 상세로 이동. 실제 화면 전환(`CollectionFeature`의 상세 화면 조립)은 호출자
    /// (App 조정 계층)가 수행한다 — 이 화면은 콜백만 올린다(마이페이지 헤더 행의 `onCollectionTapped`와
    /// 동일한 위상).
    let onItemTapped: (CollectionID) -> Void

    private enum Metric {
        /// 좌우 여백(사용자 확정, 2026-08-27) — 개수와 무관하게 항상 고정. 헤더 행의 좌측 패딩(20)과는
        /// 의도적으로 다른 값이라 헤더 타이틀과 미리보기 시작 위치가 6pt 어긋나지만, 그 어긋남 자체가
        /// 사용자가 받아들인 트레이드오프다(아래 `CappedLeadingRowLayout` 문서 참고).
        static let horizontalMargin: CGFloat = 26
        /// 아이템 사이 간격(사용자 확정, 2026-08-27) — 개수와 무관하게 항상 고정.
        static let itemSpacing: CGFloat = 32
        /// 표지 원본 비율(73:108) — 장식 사각형·표지가 이 비율로 함께 커지고 작아진다.
        static let coverAspectRatio: CGFloat = 73.0 / 108.0
        /// 장식 사각형의 최대 오프셋(`.offset(x: 14)`) — 표지가 아이템 칸 폭을 다 채우면 이 오프셋만큼
        /// 옆 아이템과의 간격을 침범해 보인다(실측 확인, 2026-08-27). 표지 쪽에 이만큼 오른쪽 여유를
        /// 미리 남겨(`.padding(.trailing:)`) 장식이 칸 안에서만 튀어나오게 한다 — 기존 고정폭(88) 박스
        /// 안에서 표지(73)가 그 여유를 이미 갖고 있던 것과 같은 원리.
        static let decorationOffset: CGFloat = 14
    }

    /// 좌우 여백 26·간격 32는 개수(1·2·3개)와 무관하게 항상 고정하고, **아이템 폭도 실제 개수가 아니라
    /// 항상 3칸(API 캡 상한) 기준으로 계산해 개수와 무관하게 항상 같은 크기**로 나온다(사용자 확정,
    /// 2026-08-27 — 처음엔 실제 개수로 나눠 1개일 때 아이템이 더 크게 나왔는데, "개수가 아니라 기기
    /// 폭에 따라서만 크기가 달라져야 한다"는 피드백으로 계산 기준을 3칸 고정으로 바꿨다). **아이템
    /// 폭에 상한을 두지 않는다**(한때 88로 캡했다가 되돌림, 2026-08-27) — 캡을 두면 화면이 넓은
    /// 기기(Pro Max 등)에서 남는 공간이 전부 여백으로 몰려 여백 26이라는 약속이 깨진다(실측 확인).
    /// 3칸 기준으로 정확히 화면을 채우는 계산값을 그대로 쓰면 여백은 어떤 기기에서도 정확히 26을
    /// 유지하고, 대신 아이템(표지) 자체가 화면이 넓을수록 그만큼 커진다 — "여백 고정"과 "아이템 크기
    /// 고정" 중 여백 고정을 우선한 결정. 3개(꽉 찼을 때)는 정확히 다 채워지고, **1·2개는 좌측
    /// 정렬**해 3칸분 자리 중 못 채운 칸만큼을 trailing(맨 오른쪽)에 남긴다. 예: 1개면
    /// "좌여백+3칸기준아이템+남는여백", 3개면 "좌여백+아이템+간격+아이템+간격+아이템+우여백"
    /// (3개일 땐 좌우 여백이 정확히 26로 같다).
    ///
    /// ⚠️ **이 화면은 과거 거의 같은 방향(동일폭 슬롯 leading 정렬 → `GeometryReader`로 폭을 재
    /// 간격을 역산)을 두 번 시도했다가 되돌린 이력이 있다**(`UserPageFeature/CLAUDE.md` 참고) —
    /// `GeometryReader`는 폭을 측정하는 데 한 프레임이 걸려, 처음 그려질 때 항목이 몰려 있다가 다음
    /// 프레임에 벌어지는 게 실사용자에게 눈에 띄었다. `CappedLeadingRowLayout`(아래, `Layout`
    /// 프로토콜)은 SwiftUI의 실제 레이아웃 계산 단계 안에서 각 서브뷰 폭을 동기적으로 확정하므로
    /// "일단 그리고 → 측정값을 state로 반영해 다시 그리는" 2단계 지연 자체가 없다 — 이 방식으로
    /// 다시 시도하는 것이지, 되돌려진 `GeometryReader` 방식을 반복하는 게 아니다.
    var body: some View {
        FillingLeadingRowLayout(spacing: Metric.itemSpacing) {
            ForEach(previews, id: \.id) { preview in
                Button {
                    onItemTapped(preview.id)
                } label: {
                    collectionItem(imageURL: preview.representativeNovel.thumbnailImage, title: preview.name)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Metric.horizontalMargin)
    }

    private func collectionItem(imageURL: URL?, title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .center) {
                // 장식 사각형은 표지와 같은 비율로 함께 커지고 작아진다 — 단, 겹침 정도를 나타내는
                // `.offset(x:)` 자체는 고정 픽셀로 둔다(비례시키려면 실제 렌더 폭을 다시 읽어야 해
                // `GeometryReader` 재도입이 필요한데, 장식 디테일이라 이번 범위에서는 단순화한다).
                RoundedRectangle(cornerRadius: 6.57)
                    .fill(WSSColor.wssGrayToast.swiftUIColor)
                    .aspectRatio(Metric.coverAspectRatio, contentMode: .fit)
                    .offset(x: 14)

                RoundedRectangle(cornerRadius: 6.57)
                    .fill(WSSColor.wssGray80.swiftUIColor)
                    .aspectRatio(Metric.coverAspectRatio, contentMode: .fit)
                    .offset(x: 7)

                // `aspectRatio:`를 넘기면 "폭은 부모(Layout)가 준 만큼, 높이는 비율로" 채운다
                // (`WSSNovelGridCell`과 동일 패턴) — raw `AsyncImage`는 URL이 nil이면 `.empty`
                // phase에서 영영 못 벗어나 `ProgressView()`가 멈추지 않고 계속 돈다.
                // `WSSNovelCoverImage`가 그 문제를 피한다.
                WSSNovelCoverImage(url: imageURL, aspectRatio: Metric.coverAspectRatio)
                    .clipShape(RoundedRectangle(cornerRadius: 6.57))
            }
            // ⚠️ 장식 사각형이 오른쪽으로 튀어나오는 만큼(`Metric.decorationOffset`) 미리 여유를 둔다 —
            // 이게 없으면 표지가 칸 폭을 꽉 채운 뒤 그 위로 더 튀어나가 옆 아이템과의 간격(32)을
            // 침범해 간격이 좁아 보인다(실측, 2026-08-27).
            .padding(.trailing, Metric.decorationOffset)
            .shadow(color: Color.black.opacity(0.1), radius: 12.68, x: 0, y: 1)

            Text(title)
                .applyWSSFont(.body5)
                .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        // `.buttonStyle(.plain)` 래핑만으론 표지 바깥 여백·텍스트 아래 빈 공간까지 탭되지 않는다 —
        // 히트영역을 칸 전체로 넓힌다(`CollectionSection.header`와 동일 관례, 상위 CLAUDE.md의
        // "커스텀 탭 영역은 `.contentShape(Rectangle())`" 참고).
        .contentShape(Rectangle())
    }
}

/// `CollectionPreviewRow` 전용 레이아웃 — 좌우 여백은 바깥 `.padding(.horizontal:)`이 맡고, 이
/// `Layout`은 "간격 고정 + 폭은 항상 3칸 기준으로 계산 + 좌측 정렬(남는 칸은 trailing)"만 책임진다.
/// 상한을 두지 않으므로 3개(꽉 찼을 때)는 정확히 화면을 채워 좌우 여백이 항상 정확히 26로 같고,
/// 1·2개는 3칸분 자리 중 못 채운 칸만큼이 trailing에 남는다(사용자 확정, 2026-08-27).
private struct FillingLeadingRowLayout: Layout {

    let spacing: CGFloat

    /// ⚠️ 아이템 폭은 **실제 서브뷰 개수가 아니라 항상 이 값(3, API가 미리보기를 캡하는 상한)으로
    /// 나눠 계산한다**(사용자 확정, 2026-08-27) — 개수로 나누면 1개일 때 아이템이 3개 꽉 찼을 때보다
    /// 커져버려 "개수가 바뀌면 같은 기기에서도 크기가 달라 보이는" 문제가 생긴다. 크기가 달라지는
    /// 축은 오직 화면 폭(기기)이어야 하고, 개수는 "몇 칸을 채우느냐"에만 영향을 준다.
    private static let referenceItemCount: CGFloat = 3

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        guard !subviews.isEmpty else { return CGSize(width: width, height: 0) }

        // ⚠️ 서브뷰의 "이상적 높이"를 `.unspecified`(폭 제약 없음)로 물으면 안 된다 — 이 화면의
        // 아이템은 비율(aspectRatio) 기반이라, 폭이 무제한이라고 답하면 그 비율에 맞춰 높이도
        // 비정상적으로 커진 값을 보고해버린다. 실제로 배치될 때 줄 폭(itemWidth)으로 물어야
        // 정확한 높이가 나온다 — placeSubviews와 동일한 계산을 여기서도 그대로 쓴다.
        let itemWidth = Self.itemWidth(forTotalWidth: width, spacing: spacing)

        let height = subviews
            .map { $0.sizeThatFits(ProposedViewSize(width: itemWidth, height: nil)).height }
            .max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }

        let itemWidth = Self.itemWidth(forTotalWidth: bounds.width, spacing: spacing)

        var x = bounds.minX
        for subview in subviews {
            subview.place(
                at: CGPoint(x: x, y: bounds.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: itemWidth, height: proposal.height)
            )
            x += itemWidth + spacing
        }
    }

    private static func itemWidth(forTotalWidth totalWidth: CGFloat, spacing: CGFloat) -> CGFloat {
        let totalSpacing = spacing * (referenceItemCount - 1)
        return max(0, (totalWidth - totalSpacing) / referenceItemCount)
    }
}
