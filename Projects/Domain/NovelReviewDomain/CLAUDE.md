<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# NovelReviewDomain

작품 리뷰 초안(Draft) 도메인 — 조회 / 저장 / 삭제.

- 식별자: `ModuleType.domain(.novelReview)` / 의존: `BaseDomain`

## 핵심 시나리오

- `NovelID` 기준으로 사용자의 리뷰 초안(`NovelReviewDraft`)을 다룬다.
- `loadNovelReviewDraft(novelID:)` → **`NovelReviewDraft?` (옵셔널)** — 초안이 없으면 nil.

## 주의사항 (작업 중 발견 시 누적)

- 조회 결과가 옵셔널이므로 "초안 없음(nil)"과 "에러(throw)"를 구분해 처리할 것.
- UseCase 3개(조회·저장·삭제)는 **일부러 테스트가 없다**(#293). 저장소에 넘기기만 해서 지킬 규칙이 없다 — 다시 넣으면 ArchLint `test-passthrough`가 막는다. `MockNovelReviewRepository`도 그 테스트만 써서 지웠다. `.testing` 타깃의 UseCase Mock 2개는 **NovelReviewFeature 테스트가 쓰므로 남겼다**(조회용 `MockLoadNovelReviewDraftUseCase`는 용어상 Stub이지만 Feature 테스트를 건드려야 해 이름은 그대로).
- 기간 정규화(`ReadingPeriod.normalized(for:)`)와 평점 검증은 **BaseDomain 코드**라 그 테스트도 BaseDomain에 있다. 여기선 초안이 정규화를 "적용하는지"만 본다.
- `setKeywords`는 `Set`을 거쳐 담아 **순서가 보존되지 않는다** — 명세가 아니라 테스트도 순서를 보지 않는다.
