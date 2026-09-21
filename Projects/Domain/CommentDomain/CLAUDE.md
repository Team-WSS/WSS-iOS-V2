<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# CommentDomain

피드 댓글 도메인 — 조회 / 작성 / 수정 / 삭제.

- 식별자: `ModuleType.domain(.comment)` / 의존: `BaseDomain`

## 핵심 시나리오

- 모든 동작이 **`FeedID` 컨텍스트**에 묶인다 (댓글은 항상 특정 피드 소속).
- `fetchComments(feedID:)` → `[FeedComment]` 목록을 반환. 총 개수는 `FeedDetail.commentCount`가 단일 진실 소스이므로 댓글 응답에서는 빼고 있다.
- 작성/수정은 `CommentDraft`로 입력받음.

## 주의사항 (작업 중 발견 시 누적)

- 수정/삭제는 `CommentID` + `FeedID` **둘 다** 필요.
- `FeedComment`의 `isSpoiler`/`isBlocked`/`isHidden`은 서로 배타적이지 않은 독립 플래그라 동시에 여러 개가 `true`일 수 있다 — 겹칠 때 무엇을 먼저 보여줄지(차단 > 숨김 > 스포일러)는 **Domain의 정책**(`FeedComment.visibility` 계산 프로퍼티, `CommentVisibility` enum)이 결정한다. Feature(`CommentRow`)는 이 우선순위를 다시 계산하지 않고 결과값만 받아 표시만 한다.
