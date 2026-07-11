//
//  NovelDetailFeedTab.swift
//  NovelDetailFeature
//
//  Created by YunhakLee on 7/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import FeedDomain
import DesignSystem
import WSSComponent

/// 피드 탭: 작품에 연결된 피드 목록(WSSFeadView 재사용) + 커서 페이지네이션.
struct NovelDetailFeedTab: View {

    let feeds: [TotalFeed]
    let isLoading: Bool
    /// 첫 페이지 로드 실패 — "진짜 빈 목록"과 구분해 거짓 빈 상태를 보여주지 않기 위한 값.
    let hasLoadFailed: Bool
    let onReachEnd: () -> Void
    /// 셀 탭 → 피드 상세 진입. 화면 전환은 호출자(App 조정 계층)가 수행한다.
    let onFeedTapped: (FeedID) -> Void
    /// 프로필 이미지 탭 → 유저 프로필 진입. 내 글이면 호출하지 않는다(셀 매핑에서 차단).
    let onUserProfileTapped: (UserID) -> Void

    var body: some View {
        if feeds.isEmpty {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 90)
            } else {
                VStack(spacing: 0) {
                    Spacer().frame(height: 70)
                    // 재시도는 피드 탭 재탭 시 VM이 다시 첫 페이지를 요청한다.
                    NovelDetailEmptyView(
                        message: hasLoadFailed
                            ? "피드를 불러오지 못했어요"
                            : "아직 글이 없어요\n최초로 남겨보세요!"
                    )
                    Spacer().frame(height: 70)
                }
            }
        } else {
            LazyVStack(spacing: 0) {
                ForEach(feeds, id: \.feedId) { feed in
                    feedCell(feed)
                        // 셀 어디를 탭해도 피드 상세로 — 셀 내부 탭 요소(프로필·threedots·좋아요)는
                        // 더 깊은 제스처라 hit-test 우선이므로 자연히 공존한다.
                        .contentShape(Rectangle())
                        .onTapGesture { onFeedTapped(feed.feedId) }
                        .onAppear {
                            // 마지막 행 노출 시 다음 페이지 요청(중복 방지는 VM 가드가 담당).
                            if feed == feeds.last {
                                onReachEnd()
                            }
                        }
                    thinDivider
                }
                if isLoading {
                    ProgressView()
                        .padding(.vertical, 20)
                }
                // 플로팅 작성 버튼에 마지막 피드가 가리지 않도록 여유 공간.
                Spacer().frame(height: 90)
            }
        }
    }

    /// 도메인 `TotalFeed` → 공용 피드 셀 입력값 매핑.
    /// 좋아요·threedots 액션, 스포일러(isSpoiler) 가림 처리는
    /// 이번 범위 밖(TODO — #154 이후 이슈, 스포일러는 WSSFeadView 확장 필요).
    private func feedCell(_ feed: TotalFeed) -> some View {
        WSSFeadView(
            header: FeedHeader(
                profileImageURL: feed.author.profileImage,
                nickname: feed.author.nickname,
                createdDate: feed.createdDate,
                isEdited: feed.isModified,
                profileImageTapped: {
                    // 내 글이면 이동하지 않는다. userId가 없으면(응답 미제공) 이동할 곳이 없다.
                    guard !feed.isMyFeed, let userId = feed.author.userId else { return }
                    onUserProfileTapped(userId)
                },
                threeDotsButtonTapped: {}
            ),
            content: feed.content,
            feedImage: feed.thumbnailImageURL.map {
                WSSFeedImage(thumbnailImageURL: $0, imageCount: feed.imageCount)
            },
            // 연결 작품 배너는 장르가 있어야 그릴 수 있다(WSSLinkNovel이 장르 필수).
            linkNovel: feed.connectedNovel.flatMap { connected in
                connected.genre.map {
                    WSSLinkNovel(
                        genreType: $0,
                        novelTitle: connected.title,
                        novelRating: connected.rating ?? 0
                    )
                }
            },
            react: WSSFeedReact(
                likeCount: feed.likeCount,
                commentCount: feed.commentCount,
                likeButtonTapped: {}
            )
        )
    }

    private var thinDivider: some View {
        Rectangle()
            .fill(Color.wssGray70)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}
