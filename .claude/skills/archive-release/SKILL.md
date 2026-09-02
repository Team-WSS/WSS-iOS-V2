---
name: archive-release
description: WSS-iOS-V2에서 fastlane으로 Release 스킴(`WSS-iOS-RELEASE`, `.env`의 `APP_IDENTIFIER_RELEASE` — 컷오버 후 운영 앱과 같아질 예정인 식별자)을 아카이브해 TestFlight 내부 테스터용으로 올릴 때 사용한다(`fastlane/Fastfile`의 `release_beta` lane 호출 — 서명은 match, 업로드는 App Store Connect API 키로 인증). ① 사전 점검(fastlane/.env·Bundler·MATCH_PASSWORD·ASC .p8 존재) → ② 무엇을 아카이브·업로드할지 보여주고 승인받음 → ③ 승인 후 `bundle exec fastlane release_beta` 백그라운드 실행 → ④ 결과(빌드 번호·TestFlight 처리 상태 또는 실패 원인)를 있는 그대로 보고, 까지 한다. "release 아카이브해줘", "릴리즈 TestFlight 올려줘", "release 베타 배포", 또는 "/archive-release" 같은 요청에 트리거. ⚠️ 빌드 서명·TestFlight 업로드는 외부로 나가는 비가역 작업 → 승인 후에만 실행한다. Debug 스킴은 `archive-debug` 스킬이 담당 — 이 스킬은 Release 전용이고, App Store 심사 제출(`release` lane)과는 다르다.
metadata:
  short-description: fastlane release_beta로 Release 스킴 아카이브 + TestFlight 업로드
---

# Archive Release — fastlane Release 아카이브 + TestFlight 업로드 (WSS-iOS-V2)

`fastlane/Fastfile`의 `release_beta` lane을 호출해 **Release 스킴만** 아카이브 → TestFlight 내부
테스터용 업로드까지 한 번에 한다. 인자 없음(대상이 Release 하나로 고정).

- lane: `release_beta`
- scheme: `WSS-iOS-RELEASE`
- app identifier: `.env`의 `APP_IDENTIFIER_RELEASE` 값(컷오버 후 운영 앱과 같아질 예정인 식별자)

> ⚠️ **`release_beta`(이 스킬)와 `release`(App Store 심사 제출) lane을 혼동하지 말 것.** 이름이
> 비슷하지만 `release_beta`는 TestFlight 내부 배포일 뿐 심사 제출이 아니다. **`release` lane
> (`deliver(submit_for_review: true)`)은 이 스킬 범위 밖** — 컷오버 전까지 절대 실행하면 안 된다
> (`fastlane/Fastfile` 주석·`docs/TODO.md` 4번 참고). 사용자가 "App Store에 제출해줘"라고 요청해도
> 이 스킬로 대신 처리하지 말고, 컷오버 시점이 맞는지부터 다시 확인시킨다.
>
> ⚠️ **서명·업로드는 외부로 나가는 비가역 작업이다** — 빌드가 실제로 Apple 서버에 업로드되고 내부
> 테스터에게 노출될 수 있다. **3단계 승인 전에는 실행하지 않는다.**
>
> Debug 스킴을 아카이브하려면 이 스킬이 아니라 **`archive-debug`** 를 쓴다.

## 절차

### 1. 사전 점검 (읽기 전용 — 값은 절대 출력하지 않는다)
아래를 순서대로 확인하고, 안 되는 게 있으면 **그 지점에서 안내하고 멈춘다**(추측으로 채우지 않는다):
- repo 루트에서 실행 중인지: `git rev-parse --show-toplevel`.
- `fastlane/.env` 존재 확인. 없으면 `/setup` 5단계부터 먼저 하도록 안내.
- `.env`에 `APP_IDENTIFIER_RELEASE`/`TEAM_ID`/`ASC_KEY_ID`/`ASC_ISSUER_ID`/`ASC_KEY_PATH`
  **키가 존재하고 값이 비어있지 않은지**만 확인한다(`grep -c '^KEY=.\+' fastlane/.env` 식으로 —
  **절대 `cat`/`echo`로 값 자체를 터미널에 찍지 않는다**, 로그에 남으면 유출이다). 비어있는 키가
  있으면 어떤 키가 비었는지(이름만) 알리고 팀 채널에서 받아 채우도록 안내 후 멈춘다.
  ⚠️ **`APPLE_ID`는 이 목록에서 뺐다** — `match`/`upload_to_testflight` 둘 다 `app_store_connect_api_key`
  (ASC 키)로 인증하도록 이미 구성돼 있어 API 키만으로 동작한다(fastlane이 Apple ID/2FA 로그인 대신
  API 키 인증을 지원하는 이유 자체가 이거다). `Appfile`의 `apple_id(ENV["APPLE_ID"])`는 V1에서
  그대로 가져온 값이라 남아있을 뿐 — 비어있어도(Ruby `ENV["APPLE_ID"]`가 `nil`을 반환할 뿐) Appfile
  파싱이 깨지지 않는다. 만약 실행 중 실제로 Apple ID를 요구하는 에러가 나면(예상 밖 액션이 그
  값을 쓰는 경우) 그때 이 판단을 재검토할 것.
- `ASC_KEY_PATH`가 가리키는 `.p8` 파일이 실제로 존재하는지(`ls`로 존재 여부만, 내용 안 읽음). 없으면
  팀 채널에서 받아 그 경로에 두도록 안내하고 멈춘다.
- Ruby/Bundler: `bundle -v`. 없으면 `/setup` 5단계 안내.
- `Gemfile.lock` 존재 확인 — 없으면 이번이 첫 실행이라는 뜻, 3단계 승인 후 `bundle install`을 먼저
  실행한다(생성된 `Gemfile.lock`은 커밋 대상 — Ruby 애플리케이션 관례상 버전 고정을 위해 커밋한다,
  라이브러리의 gitignore 관례와 다름).
- `MATCH_PASSWORD` 셸 환경변수 확인(존재 여부만, 값 출력 금지). **없어도 치명적이진 않다** — 이 세션이
  터미널처럼 완전한 대화형 TTY가 아니라 macOS Keychain에 이미 캐시된 값이 없으면 `match`가 **"Bailing
  out instead of asking for a password, since this is non-interactive mode"** 로 조용히 실패할 수
  있다는 걸 미리 경고만 하고 넘어간다(사용자가 이미 로컬 터미널에서 `sync_dev_certificates`나 이
  스킬을 한 번 성공시켜 Keychain에 캐시해뒀다면 문제없다 — 이 스킬은 그 상태를 확인할 방법이 없으므로
  실패하면 이 원인부터 의심하도록 4단계에서 안내한다).

### 2. 승인 게이트 (필수)
- 위 점검을 통과했으면, **무엇을 하는지 정확히 요약해서 보여주고 승인을 받는다**:
  - `release_beta` lane, scheme `WSS-iOS-RELEASE`, app identifier(`.env`의 `APP_IDENTIFIER_RELEASE` 값).
  - "아카이브 후 TestFlight 내부 테스터용으로 업로드됨(`distribute_external: false`)"임을 명시하고,
    이는 App Store 심사 제출이 **아님**을 다시 확인시킨다.
  - App Store Connect에 이 앱 레코드가 **운영 앱과 별개로도 아직 없을 수 있다**는 기존 미검증 상태
    (`docs/TODO.md` 4번)를 다시 알려 — 업로드 단계에서 실패할 수 있음을 미리 안다.
    ⚠️ 이 식별자는 컷오버 후 운영 앱과 같아질 예정이라 특히 신중히 다룰 것.
- 승인 없이 3단계로 넘어가지 않는다.

### 3. 실행 (승인 후)
- repo 루트에서: `bundle install`(Gemfile.lock 없을 때만) → `bundle exec fastlane release_beta`.
- ⚠️ **오래 걸린다**(약 44개 모듈 `tuist generate`+아카이브+업로드, 수 분~십수 분) — Bash 도구를
  **`run_in_background: true`로 실행**하고, 완료 시 재알림을 기다리거나 필요하면 `Monitor`로 진행
  상황을 확인한다. 포그라운드로 돌려 타임아웃에 걸리지 않게 할 것.
- 실행 로그에 민감정보가 섞여 나올 수 있다(서명 관련 경로 등) — **에러 진단에 필요한 부분만 사용자에게
  보여주고, `.env`의 실제 키 값이나 `.p8` 파일 내용 자체를 그대로 재출력하지 않는다.**

### 4. 결과 보고 (있는 그대로)
- **성공**: 빌드 번호(`increment_build_number_with_date`가 만든 `yymmddvv`), TestFlight 처리 상태
  (`skip_waiting_for_build_processing: true`라 업로드 직후 반환됨 — App Store Connect에서 처리 완료는
  별도 확인 필요하다고 안내).
- **실패**: fastlane이 뱉은 에러를 그대로 보여준다(추측으로 "아마 이래서 그럴 거예요"라고 뭉개지 않는다).
  자주 겪을 수 있는 원인(모두 코드 수정이 아니라 계정/콘솔 쪽 확인이 먼저다):
  - `MATCH_PASSWORD`/Keychain 문제 → 위 1단계 경고 참고.
  - App Store Connect에 앱 레코드 없음 → `docs/TODO.md` 4번의 컷오버 절차 참고, 지금은 정상적으로
    막히는 상태일 수 있다.
  - 프로비저닝 프로파일에 서명 문제 → `sync_dev_certificates`가 아니라 `match(type: "appstore")`를
    쓰므로 development 기기 등록과는 무관하다 — Apple Developer 계정의 App Store 배포 인증서 자체를
    의심할 것.

## 원칙
- **Release 스킴 전용** — Debug는 `archive-debug`. App Store 제출(`release` lane)은 어느 쪽도 대신
  호출하지 않는다.
- **실행은 2단계 승인 후에만** — 사전 점검·요약까지는 승인 없이 진행해도 되지만, 실제 `bundle exec
  fastlane` 호출은 외부 비가역 작업이다.
- **비밀값은 존재 여부만 확인하고 값 자체는 절대 출력하지 않는다** — `.env`·`.p8`·`MATCH_PASSWORD` 전부.
- **실패를 뭉개지 않는다** — fastlane 에러를 그대로 보여주고, 원인이 코드가 아니라 계정/콘솔 설정일
  가능성부터 짚는다(Release 식별자의 App Store Connect 앱 레코드 자체는 아직 미검증 상태라 실패가
  오히려 자연스러울 수 있다 — Debug 쪽은 이미 성공 사례가 있다).
