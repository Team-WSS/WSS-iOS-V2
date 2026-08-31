<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# SettingData

`SettingDomain`의 두 Repository를 구현 — `DefaultAppUpdateRepository` + `DefaultTermsAgreementRepository`.

- 식별자: `ModuleType.data(.setting)` / 의존: `SettingDomain`, `BaseDomain`, `BaseData`, `Networking`, `Logger`
- 진입점 3개 (앞 둘은 `DefaultSettingService` 공유):
  - `SettingDataFactory.makeAppUpdateRepository(client:logger:)`
  - `SettingDataFactory.makeTermsAgreementRepository(client:logger:)`
  - `SettingDataFactory.makeAppVersionProvider(bundle:)`
- `AppVersionProviding` 실구현은 **`BundleAppVersionProvider`**(#225, TODO 2절의 "실구현체 없음" 해소).
  파싱 실패 폴백은 `.zero`가 아니라 **절대 강제되지 않는 방향**(max 버전) — `.zero`면 앱이 업데이트 알럿에 잠긴다.

## 주의사항 (작업 중 발견 시 누적)

- Repository는 2개지만 **Service(`DefaultSettingService`)는 하나**를 공유한다.
- `DateParser`/`ConversionType` 매퍼 보조 존재 (날짜·타입 변환).
- **`BundleAppVersionProvider`는 `public`으로 못 만든다** — ArchLint `factory-exclusivity`가 비-Base Data 모듈에서
  `*DataFactory` 외 public 타입을 막는다(#225에서 실제로 CI required check가 걸렸다). 네트워크를 안 타는 provider라
  "팩토리를 거칠 이유가 없어 보이는" 함정이 있으니, 새 provider도 반드시 `SettingDataFactory` 진입점으로 노출할 것.
