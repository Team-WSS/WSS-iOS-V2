<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# CommentDomain

피드 댓글 도메인 — 조회 / 작성 / 수정 / 삭제.

- 식별자: `ModuleType.domain(.comment)` / 의존: `BaseDomain`

## 핵심 시나리오

- 모든 동작이 **`FeedID` 컨텍스트**에 묶인다 (댓글은 항상 특정 피드 소속).
- `fetchComments(feedID:)` → `(Int, [FeedComment])` = (총 개수, 목록).
- 작성/수정은 `CommentDraft`로 입력받음.

## 주의사항 (작업 중 발견 시 누적)

- 수정/삭제는 `CommentID` + `FeedID` **둘 다** 필요.
