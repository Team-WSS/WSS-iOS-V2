//
//  CollectionPreviewRow.swift
//  UserPageFeature
//
//  Created by Guryss on 8/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import CollectionDomain
import DesignSystem
import WSSComponent

/// 컬렉션 미리보기 항목들(대표 표지 1장씩) — `CollectionSection`(마이페이지, "컬렉션 N개" 헤더)과
/// `UserPageView`의 컬렉션 섹션("컬렉션" 타이틀 + 화살표, 헤더 스타일이 다르다)이 공유한다.
/// `LibrarySection`/`GenreSection`이 "콘텐츠만" 재사용되고 타이틀 행은 화면마다 로컬로 짓는 것과
/// 동일한 분리 — 헤더 스타일이 화면마다 달라 헤더까지 통째로 공용화하면 오히려 분기가 늘어난다.
struct CollectionPreviewRow: View {

    let previews: [CollectionPreview]

    private enum Metric {
        /// 미리보기 항목 사이 간격(사용자 확정, 2026-08-21) — 화면 폭 기준 역산 대신 고정값으로 정했다.
        static let itemSpacing: CGFloat = 30
        /// 2개 이하일 때 좌측 정렬 기준점 — 헤더 행의 좌측 패딩(`.padding(.horizontal, 20)`)과 동일해야
        /// 미리보기 시작 위치가 헤더 타이틀과 맞아떨어진다.
        static let leadingInset: CGFloat = 20
    }

    /// 3개가 꽉 찼을 때는 항목 사이 간격 고정 30 + 묶음 전체를 화면 가운데 정렬한다(사용자 확정,
    /// 2026-08-21) — `HStack`은 내용물 크기만큼만 차지하고, 그 바깥 `.frame(maxWidth: .infinity)`가
    /// 화면 전체 폭을 차지해 기본 정렬(`.center`)로 가운데 놓는다. 자세한 시행착오는
    /// `UserPageFeature/CLAUDE.md` 참고 — 화면 폭 기준 정밀 대칭(간격 역산)을 시도했다가 되돌린 이력이 있다.
    /// 2개·1개일 땐 가운데 정렬 시 헤더 타이틀과 시작 위치가 어긋나 보여, 헤더와 동일한 좌측 인셋(20)에
    /// 맞춰 왼쪽 정렬한다(사용자 확정, 2026-08-22).
    var body: some View {
        HStack(spacing: Metric.itemSpacing) {
            ForEach(previews, id: \.id) { preview in
                collectionItem(imageURL: preview.representativeNovel.thumbnailImage, title: preview.name)
            }
        }
        .frame(maxWidth: .infinity, alignment: previews.count < 3 ? .leading : .center)
        .padding(.leading, previews.count < 3 ? Metric.leadingInset : 0)
    }

    private func collectionItem(imageURL: URL?, title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 6.57)
                    .fill(WSSColor.wssGrayToast.swiftUIColor)
                    .offset(x: 14)
                    .frame(width: 73, height: 108)

                RoundedRectangle(cornerRadius: 6.57)
                    .fill(WSSColor.wssGray80.swiftUIColor)
                    .offset(x: 7)
                    .frame(width: 73, height: 108)

                // 크기 고정 자리라 aspectRatio 없이 .frame으로 직접 크기를 준다(`WSSComponent/CLAUDE.md`
                // 정본 패턴). raw `AsyncImage`는 URL이 nil이면 `.empty` phase에서 영영 못 벗어나
                // `ProgressView()`가 멈추지 않고 계속 돈다 — `WSSNovelCoverImage`가 그 문제를 피한다.
                WSSNovelCoverImage(url: imageURL)
                    .frame(width: 73, height: 108)
                    .clipShape(RoundedRectangle(cornerRadius: 6.57))
            }
            .shadow(color: Color.black.opacity(0.1), radius: 12.68, x: 0, y: 1)

            Text(title)
                .applyWSSFont(.body5)
                .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                .lineLimit(1)
        }
        .frame(width: 88)
    }
}
