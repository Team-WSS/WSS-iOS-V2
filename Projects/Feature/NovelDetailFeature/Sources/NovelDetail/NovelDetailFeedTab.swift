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
    /// 피드 로드 실패(첫 페이지·더보기 공통) — 탭 자리를 실패 뷰로 대체할지 가르는 값.
    let hasLoadFailed: Bool
    /// 셀 y 실측에 쓸 ScrollView 좌표공간 이름(threedots 드롭다운 앵커 계산용).
    let scrollSpaceName: String
    let onReachEnd: () -> Void
    /// 실패 뷰의 재시도 → 첫 페이지부터 다시 로드 요청.
    let onRetry: () -> Void
    /// 셀 탭 → 피드 상세 진입. 화면 전환은 호출자(App 조정 계층)가 수행한다.
    let onFeedTapped: (FeedID) -> Void
    /// 프로필 영역(이미지+닉네임) 탭 → 유저 프로필 진입. 내 글이면 호출하지 않는다(셀 매핑에서 차단).
    let onUserProfileTapped: (UserID) -> Void
    /// 프로필 영역 탭이 탈퇴 유저(`Author.accessibleUserId == nil`)를 가리킬 때 호출 — 화면 전환 대신
    /// 안내 토스트를 띄우는 건 호출자(`NovelDetailView`, VM의 `userProfileUnavailable` 액션) 몫이다.
    let onUnavailableUserProfileTapped: () -> Void
    /// 연결 작품 배너 탭 → 해당 작품 상세 진입. 화면 전환은 호출자(App 조정 계층)가 수행한다.
    let onNovelTapped: (NovelID) -> Void
    /// threedots 탭 → 셀 드롭다운 표시 요청. 두 번째 값은 드롭다운 앵커(threedots 하단의 화면 y).
    let onThreeDotsTapped: (TotalFeed, CGFloat) -> Void
    /// 좋아요 탭 → 낙관 토글 요청(반영·롤백은 VM 소관).
    let onToggleLike: (FeedID) -> Void

    /// 각 셀 상단의 화면 y(스크롤 좌표공간 실측)를 담는 참조 박스 — threedots 앵커 계산용.
    /// 값은 **threedots 탭 시점에만 읽으므로** 뷰가 반응할 필요가 없다.
    ///
    /// ⚠️ **`@State var [FeedID: CGFloat]` 딕셔너리로 되돌리지 말 것** — 그 형태에선 셀 y가 바뀔 때마다
    /// (모든 스크롤·재배치) @State 쓰기가 body 무효화를 일으켜, 필요 없는 재평가가 상시로 돈다.
    /// 참조 타입 내부 변경은 SwiftUI가 관찰하지 않아 이 낭비가 없다(@State는 인스턴스 보유용일 뿐).
    /// 이 화면의 간헐 라이브락(무한 레이아웃 루프 — 모듈 CLAUDE.md 주의사항) 조사 중에 사이클 한 겹을
    /// 끊으려 전환했다 — **단독 해결책은 아니었지만**(전환 후에도 재현) 되돌릴 이유도 없다.
    @MainActor
    private final class CellTopYStore {
        var values: [FeedID: CGFloat] = [:]
    }
    @State private var cellTopYs = CellTopYStore()

    /// 셀 상단 → threedots 하단 거리 = 셀 상단 패딩(20) + 헤더 높이(32). 드롭다운이 이 바로 아래에 뜬다.
    private let threeDotsBottomOffset: CGFloat = 52

    var body: some View {
        // ⚠️ 실패는 목록보다 **먼저** 판단한다 — 더보기가 실패하면 목록이 남아 있는데, 그대로 두면
        // 실패를 알릴 자리가 없어 사용자가 "왜 안 늘어나지"로 갇힌다(서재에서 실제로 겪은 문제).
        // 재시도 버튼이 달린 실패 뷰로 탭 자리를 대체해 복구 경로를 준다.
        if hasLoadFailed {
            NetworkErrorView { onRetry() }
        } else if feeds.isEmpty {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 90)
            } else {
                VStack(spacing: 0) {
                    Spacer().frame(height: 70)
                    NovelDetailEmptyView(message: "아직 글이 없어요\n최초로 남겨보세요!")
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
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .onChange(of: proxy.frame(in: .named(scrollSpaceName)).minY,
                                              initial: true) { _, newY in
                                        // 참조 박스 내부 쓰기 — 뷰 무효화를 만들지 않는다(위 CellTopYStore 주석).
                                        cellTopYs.values[feed.feedId] = newY
                                    }
                            }
                        )
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
    private func feedCell(_ feed: TotalFeed) -> some View {
        WSSFeadView(
            header: FeedHeader(
                profileImageURL: feed.author.profileImage,
                nickname: feed.author.nickname,
                createdDate: feed.createdDate,
                isEdited: feed.isModified
            ),
            profileImageTapped: {
                // 내 글이면 이동하지 않는다.
                guard !feed.isMyFeed else { return }
                // 탈퇴 유저(Author.accessibleUserId == nil)면 이동 대신 안내 토스트만 띄운다.
                guard let userId = feed.author.accessibleUserId else {
                    onUnavailableUserProfileTapped()
                    return
                }
                onUserProfileTapped(userId)
            },
            threeDotsButtonTapped: {
                onThreeDotsTapped(feed, (cellTopYs.values[feed.feedId] ?? 0) + threeDotsBottomOffset)
            },
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
                        novelRating: connected.rating ?? 0,
                        linkNovelTapped: { onNovelTapped(connected.id) }
                    )
                }
            },
            react: WSSFeedReact(
                likeCount: feed.likeCount,
                commentCount: feed.commentCount
            ),
            isLiked: feed.isLiked,
            likeButtonTapped: { onToggleLike(feed.feedId) },
            isSpoiler: feed.isSpoiler,
            isPrivate: !feed.isPublic
        )
    }

    private var thinDivider: some View {
        Rectangle()
            .fill(Color.wssGray70)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}
