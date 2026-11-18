# SettingDomain 테스트 명세

<!-- 자동 생성 파일 — 손으로 고치지 않는다. 갱신: swift run --package-path Tooling/ArchLint ArchLint --write-test-specs . -->

## 강제 업데이트 판단

`Tests/AppUpdate/Entity/AppUpdatePolicyTests.swift`

- 앱 버전이 최소 버전보다 낮으면 강제 업데이트가 필요하다
- 앱 버전이 최소 버전과 같거나 높으면 강제 업데이트가 필요 없다
  - `AppVersion(major: 1, minor: 0, patch: 0)` — 최소 버전과 딱 같음
  - `AppVersion(major: 1, minor: 0, patch: 1)` — patch 하나 위

## 앱 버전

`Tests/AppUpdate/Entity/AppVersionTests.swift`

### 문자열 읽기

- 숫자가 하나나 둘이면 비어 있는 자리를 0으로 채운다
  - `("1", AppVersion(major: 1, minor: 0, patch: 0))` — minor·patch가 빔
  - `("1.2", AppVersion(major: 1, minor: 2, patch: 0))` — patch만 빔
- 숫자가 셋이면 그대로 읽는다
- 앞뒤 공백은 무시하고 읽는다
- 버전 모양이 아니면 오류로 처리한다
  - `""` — 아무것도 없음
  - `"   "` — 공백뿐
  - `"1.2.3.4"` — 숫자가 넷
  - `"a.b.c"` — 숫자가 아님
  - `"1.-2.3"` — 음수
  - `"v1.2.3"` — 앞에 글자가 붙음
  - `"1..2"` — 가운데 자리가 빔
  - `"1."` — 끝 자리가 빔
  - `".1"` — 첫 자리가 빔

### 비교

- 앞자리부터 차례로 비교해 처음 다른 자리로 크기를 정한다
  - `(AppVersion(major: 1, minor: 9, patch: 9), AppVersion(major: 2, minor: 0, patch: 0))` — major가 작으면 minor·patch가 커도 작다
  - `(AppVersion(major: 1, minor: 2, patch: 9), AppVersion(major: 1, minor: 3, patch: 0))` — major가 같으면 minor가 작은 쪽이 작다(patch가 커도)
  - `(AppVersion(major: 1, minor: 2, patch: 3), AppVersion(major: 1, minor: 2, patch: 4))` — major·minor가 같으면 patch로 정한다
- 세 자리가 모두 같으면 크기가 같다

## 약관 동의

`Tests/TermsAgreement/Entity/TermsAgreementDraftTests.swift`

### 처음 상태

- 아무 값 없이 만들면 모든 약관이 미동의다
- 값을 주지 않은 약관은 미동의로 채운다

### 동의 여부 편집

- 약관 하나에 동의하거나 철회하면 그 약관만 바뀐다
  - `true` — 전부 미동의인 상태에서 하나만 동의
  - `false` — 전부 동의한 상태에서 하나만 철회
- 모두 동의하면 선택 약관까지 전부 동의가 된다

### 제출

- 필수 약관 중 하나라도 동의하지 않으면 제출할 수 없다
  - `[.serviceAgreement: false, .privacyPolicy: true, .marketingConsent: true]` — 서비스 이용약관만 빠짐
  - `[.serviceAgreement: true, .privacyPolicy: false, .marketingConsent: true]` — 개인정보 처리방침만 빠짐
- 선택 약관인 마케팅 수신에 동의하지 않아도 제출할 수 있다
