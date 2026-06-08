# 도메인 용어집 (Ubiquitous Language)

웹소소(WSS)는 **웹소설 기록·리뷰·추천·커뮤니티** 앱이다. 제품 용어 ↔ 코드 타입을 매핑한다.
(코드 기반 정리 — 제품 뉘앙스가 다르면 바로잡아 누적할 것)

## 작품 (Novel)

| 용어 | 타입 | 의미 |
|---|---|---|
| 작품 | `Novel` / `NovelInformation` | 웹소설. Novel=헤더, NovelInformation=상세 |
| 서재 | `LibraryNovel`, `LibraryFilter`, `MyLibraryFilter` | 사용자가 등록·기록한 작품 목록 |
| 관심 | `Novel.isInterested` / `addNovelInterest` | 작품 찜(관심 등록). 관심 수 = `interestCount` |
| 등록 작품 통계 | `RegisteredNovelStats` | 사용자가 서재에 등록한 작품 통계 |
| 장르 | `NovelGenre` | BL/로맨스/판타지/무협 등 |
| 평점 | `Rating` | 작품 별점 |
| 독서 상태 | `ReadingStatus` | 보는 중/봤음 등 (`watching`/`watched`...) |
| 매력 포인트 | `AttractivePoint` | 세계관/캐릭터 등 작품 매력 태그 |
| 연재 상태 | `NovelPublicationStatus` | 완결/연재중 |
| 플랫폼 | `NovelPlatform` | 작품 연재 플랫폼 |
| 키워드 | `Keyword`, `KeywordGroup` | 작품 태그 키워드(로컬 캐시) |

## 추천 / 홈 (Recommendation)

| 용어 | 타입 | 의미 |
|---|---|---|
| 홈 데이터 | `HomeData` | 홈 화면 추천 묶음 (4종 합성) |
| 오늘의 발견 | `TodayDiscovery` | 홈 추천 작품 |
| 트렌딩 피드 | `TrendingFeed` | 인기 피드 |
| 관심 피드 | `InterestFeed`, `InterestFeedState` | 관심 기반 피드 |
| 선호 장르 작품 | `PreferenceGenreNovel`, `...State` | 선호 장르 기반 추천 |
| 소소픽 | `SosoPick` | 큐레이션 추천 픽 |

## 피드 / 댓글 (Feed / Comment)

| 용어 | 타입 | 의미 |
|---|---|---|
| 피드 | `TotalFeed`, `FeedDetail`, `FeedDraft` | 커뮤니티 글 (목록/상세/작성초안) |
| 소소피드 | `SosoFeedOption` | 전체 공개 피드 흐름 |
| 내 피드 | `MyFeedOption` | 내가 쓴 피드 |
| 연결 작품 | `ConnectedNovel`, `ConnectedNovelDetail` | 피드에 연결된 작품 |
| 댓글 | `FeedComment`, `CommentDraft` | 피드 댓글 |
| 좋아요 | `addLike`/`deleteLike` | 피드 좋아요 |

## 프로필 (Profile)

| 용어 | 타입 | 의미 |
|---|---|---|
| 프로필 | `Profile`, `ProfileDraft` | 사용자 프로필 |
| 프로필 캐릭터 | `ProfileCharacter` | 아바타 캐릭터 |
| 닉네임 | `NicknameDraft` / `validateNickname` | 닉네임(중복 검사) |
| 선호 장르 | `GenrePreference` | 선호 장르 설정 |
| 선호 작품 | `NovelPreference` | 선호 작품 설정 |
| 공개 범위 | `ProfileVisibility` | 프로필 공개 설정 |
| 계정 정보 | `AccountInfoDraft` (`BirthYear`/`Gender`) | 생년/성별 등 |
| 프로필 등록 | `ProfileRegistration` | 온보딩 시 프로필 생성 |
| 본인/타인 | `ProfileTarget(.me/.user)` | 조회 대상 분기 |

## 리뷰 / 알림 / 설정 / 소셜 / 인증

| 용어 | 타입 | 의미 |
|---|---|---|
| 리뷰 초안 | `NovelReviewDraft` | 작품 리뷰 작성 초안 |
| 알림 | `NotificationItem`, `NotificationDetail`, `PagedNotifications` | 인앱 알림 |
| 미읽음 상태 | `UnreadNotificationStatus` | 안 읽은 알림 여부 |
| 푸시 설정 | `PushPreference`, `DevicePushToken` | 푸시 on/off, 기기 토큰 |
| 강제 업데이트 | `AppUpdatePolicy`, `AppVersion` | 최소 버전 정책 |
| 약관 | `TermsAgreementDraft`, `TermsType` | 약관 동의 |
| 차단 | `BlockedUser` (UserID로 차단, BlockID로 해제) | 사용자 차단 |
| 신고 | `reportSpoiler/Improper Feed/Comment` | 스포일러·부적절 신고 |
| 온보딩 | `NeedOnboarding` | 로그인 후 온보딩 필요 여부 |
| 소셜 로그인 | `SocialLoginCredential` | 카카오/애플 로그인 |

## 주의사항 (작업 중 발견 시 누적)

- 제품에서 쓰는 정확한 한글 명칭(특히 소소픽/소소피드 구분)은 디자인·기획과 대조해 보정.
