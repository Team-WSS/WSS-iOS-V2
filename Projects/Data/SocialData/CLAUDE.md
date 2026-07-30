<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# SocialData

`SocialDomain.SocialRepository` 구현 — 차단 + 신고.

- 식별자: `ModuleType.data(.social)` / 의존: `SocialDomain`, `BaseDomain`, `BaseData`, `Networking`, `Logger`
- 진입점: `SocialDataFactory.makeSocialRepository(client:logger:)` — 다른 Data 모듈과 동일하게 `DataLogger?`를 직접 받는다(호출부가 `DataLogger(moduleName: "SocialData", underlying:)`를 조립해 넘김).

## 주의사항 (작업 중 발견 시 누적)

- 특이사항 없음.
