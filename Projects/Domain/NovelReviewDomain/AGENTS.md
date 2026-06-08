<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/AGENTS.md(레이어 규칙)와 함께 자동 로드됨. -->
# NovelReviewDomain

작품 리뷰 초안(Draft) 도메인 — 조회 / 저장 / 삭제.

- 식별자: `ModuleType.domain(.novelReview)` / 의존: `BaseDomain`

## 핵심 시나리오

- `NovelID` 기준으로 사용자의 리뷰 초안(`NovelReviewDraft`)을 다룬다.
- `loadNovelReviewDraft(novelID:)` → **`NovelReviewDraft?` (옵셔널)** — 초안이 없으면 nil.

## 주의사항 (작업 중 발견 시 누적)

- 조회 결과가 옵셔널이므로 "초안 없음(nil)"과 "에러(throw)"를 구분해 처리할 것.
