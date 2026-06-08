<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/AGENTS.md(레이어 규칙)와 함께 자동 로드됨. -->
# FeedDomain

피드 도메인 — 작성/수정/삭제(Draft), 상세 조회, 목록 조회(소스별), 좋아요.

- 식별자: `ModuleType.domain(.feed)` / 의존: `BaseDomain`
- 디렉토리가 기능별로 나뉨: `Entity|UseCase/{FeedDraft, FeedDetail, TotalFeed}`

## 핵심 시나리오

- **목록은 소스별 4종**: `fetchSosoFeeds`(소소피드, `SosoFeedOption`), `fetchMyFeeds`(`MyFeedOption`), `fetchUserFeeds(id:)`, `fetchNovelFeeds(id:)`. 모두 `Paginated<TotalFeed>` 반환.
- **페이지네이션은 `lastFeedID` 커서 방식** (page 번호 아님).
- 작성/수정은 `FeedDraft` 입력. 좋아요는 `addLike`/`deleteLike`.

## 주의사항 (작업 중 발견 시 누적)

- 커서가 `lastFeedID`라, 첫 페이지 호출 시 어떤 ID를 넣는지 호출 측 규약 확인 (Data 구현/매핑 참고).
