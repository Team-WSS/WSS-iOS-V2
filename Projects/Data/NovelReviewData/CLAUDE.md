<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# NovelReviewData

`NovelReviewDomain.NovelReviewRepository` 구현 — 리뷰 초안 조회/저장/삭제.

- 식별자: `ModuleType.data(.novelReview)` / 의존: `NovelReviewDomain`, `BaseData`, `Networking`
- 진입점: `NovelReviewDataFactory.makeRepository(client:logger:)`

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ `DateParser`가 **`yyyy-MM-dd` / `ko_KR` / `Asia/Seoul` 고정**. 날짜 포맷이 다른 API 응답이 오면 파싱이 nil 반환 → 매핑 실패. 새 날짜 필드 추가 시 포맷 확인.
- 조회는 도메인상 옵셔널(초안 없음 = nil) — 404 등을 에러가 아닌 nil로 처리하는지 매퍼/Repository 확인.
