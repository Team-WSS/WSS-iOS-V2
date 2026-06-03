<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# SocialDomain

소셜 안전 도메인 — **차단(Block)** + **신고(Report)**.

- 식별자: `ModuleType.domain(.social)` / 의존: `BaseDomain`

## 핵심 시나리오

- **차단**: `blockUser(id: UserID)` / `loadBlockedUsers() -> [BlockedUser]` / `unblockUser(id: BlockID)`.
- **신고**: 피드/댓글 각각에 대해 스포일러·부적절 4종 (`reportSpoilerFeed`, `reportImproperFeed`, `reportSpoilerComment`, `reportImproperComment`).

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ **차단은 `UserID`로, 차단 해제는 `BlockID`로** 한다 (차단 시 생성된 차단 레코드 ID). 둘을 혼동하지 말 것.
- 댓글 신고는 `feedID` + `commentID` 둘 다 필요.
