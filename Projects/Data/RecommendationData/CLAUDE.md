<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# RecommendationData

`RecommendationDomain.RecommendationRepository` 구현 — 홈 추천 5종 fetch.

- 식별자: `ModuleType.data(.recommendation)` / 의존: `RecommendationDomain`, `BaseData`, `Networking`
- 진입점: `RecommendationDataFactory.makeRepository(network:logger:)`

## 주의사항 (작업 중 발견 시 누적)

- Factory 파라미터명이 `client`가 아니라 **`network:`** (다른 모듈과 네이밍 불일치). 조립 코드 작성 시 주의.
- 홈 데이터 합성(4종 순차 호출)은 Domain의 `LoadHomeDataUseCase` 책임 — 여기선 개별 fetch만 구현.
