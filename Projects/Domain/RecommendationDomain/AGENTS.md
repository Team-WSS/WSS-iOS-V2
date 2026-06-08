<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/AGENTS.md(레이어 규칙)와 함께 자동 로드됨. -->
# RecommendationDomain

홈 화면 추천 도메인 — 오늘의 발견 / 트렌딩 피드 / 관심 피드 / 선호 장르 작품 / 소소픽.

- 식별자: `ModuleType.domain(.recommendation)` / 의존: `BaseDomain`

## 핵심 시나리오

- **`LoadHomeDataUseCase`가 핵심**: Repository의 4개 호출(today/trending/interest/preference)을 **순차 실행**해 `HomeData` 하나로 합친다. 홈 진입 시 이걸 부른다.
- 소소픽(`LoadSosoPickUseCase`)은 별도.
- 일부는 상태 래퍼 반환: `InterestFeedState`, `PreferenceGenreNovelState` (로그인/비로그인·빈 상태 등 표현).

## 주의사항 (작업 중 발견 시 누적)

- `LoadHomeDataUseCase`의 4개 호출은 순차(`await` 연속) — 하나 실패 시 전체 실패. 병렬화/부분 실패 허용이 필요하면 여기 수정.
- 구현 클래스명이 `DefaultLoadDataUseCase` (프로토콜명 `LoadHomeDataUseCase`와 네이밍 불일치 — 오타성). 참조 시 주의.
