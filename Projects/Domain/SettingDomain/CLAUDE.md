<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# SettingDomain

설정 도메인 — **두 하위 영역**: `AppUpdate/`(강제 업데이트 정책) + `TermsAgreement/`(약관 동의).

- 식별자: `ModuleType.domain(.setting)` / 의존: `BaseDomain`

## 핵심 시나리오

- **강제 업데이트(`CheckForceUpdateUseCase`)**: 서버의 `AppUpdatePolicy`(min 버전)와 `AppVersionProviding.currentVersion`(현재 앱 버전)을 비교해 강제 업데이트 여부 판단.
- **약관(`TermsAgreementRepository`)**: 동의 초안(`TermsAgreementDraft`) 조회/저장, `TermsType`별.

## 주의사항 (작업 중 발견 시 누적)

- **Repository 2개** (`AppUpdateRepository`, `TermsAgreementRepository`) — 영역이 다르다.
- `AppVersionProviding`는 현재 버전을 주입받는 프로토콜 (Bundle 등 외부 의존을 도메인 밖으로 뺀 것). 테스트 시 여기에 가짜 버전 주입.
