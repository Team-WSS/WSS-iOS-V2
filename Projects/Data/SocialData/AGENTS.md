<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/AGENTS.md(레이어 규칙)와 함께 자동 로드됨. -->
# SocialData

`SocialDomain.SocialRepository` 구현 — 차단 + 신고.

- 식별자: `ModuleType.data(.social)` / 의존: `SocialDomain`, `BaseDomain`, `BaseData`, `Networking`, `Logger`
- 진입점: `SocialDataFactory.makeSocialRepository(client:underlying:)`

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ Factory 로깅 패턴이 다름: 다른 모듈은 `DataLogger`를 직접 받지만, 여기는 **`underlying: Logger?`를 받아 내부에서 `DataLogger(moduleName:"SocialData", ...)`를 생성**한다. 조립 시 넘기는 인자 타입 주의.
