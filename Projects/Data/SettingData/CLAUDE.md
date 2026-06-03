<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# SettingData

`SettingDomain`의 두 Repository를 구현 — `DefaultAppUpdateRepository` + `DefaultTermsAgreementRepository`.

- 식별자: `ModuleType.data(.setting)` / 의존: `SettingDomain`, `BaseData`, `Networking`
- 진입점 2개 (둘 다 `DefaultSettingService` 공유):
  - `SettingDataFactory.makeAppUpdateRepository(client:logger:)`
  - `SettingDataFactory.makeTermsAgreementRepository(client:logger:)`

## 주의사항 (작업 중 발견 시 누적)

- Repository는 2개지만 **Service(`DefaultSettingService`)는 하나**를 공유한다.
- `DateParser`/`ConversionType` 매퍼 보조 존재 (날짜·타입 변환).
