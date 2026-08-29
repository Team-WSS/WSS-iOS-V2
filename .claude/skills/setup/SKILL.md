---
name: setup
description: WSS-iOS-V2를 클론한 뒤 개발 환경을 처음 셋업할 때 사용한다. mise install → tuist install → tuist generate → git 훅 활성화(core.hooksPath) → Config 비밀값 확인 → fastlane 서명 환경(실기기 빌드용) → .mcp.json 신뢰 승인까지 단계별로 점검·실행·안내한다. "초기 셋업", "환경 세팅", "처음 클론했어", 또는 "/setup" 같은 요청에 트리거. 실제 Config 비밀키 값·fastlane .env/MATCH_PASSWORD·MCP 신뢰 승인 클릭·머신 설치(Xcode/Node)는 사람만 할 수 있어 스킬은 그 지점을 정확히 안내하고 멈춘다.
metadata:
  short-description: 클론 후 초기 개발환경 셋업 (도구·Tuist·git훅·Config·fastlane·MCP 점검·안내)
---

# Setup — 초기 개발환경 셋업 (WSS-iOS-V2)

레포를 클론한 직후 한 번 돌린다. 인자: 없음. 이미 셋업된 환경에서 다시 돌려도 안전하다(각 단계 **멱등** — 이미 됐으면 스킵/재생성만).

> ⚠️ 스킬이 **실행**하는 것(도구·Tuist·git 훅)과 **사람만 할 수 있는 것**을 구분한다.
> **실제 Config 비밀키 값**·**`.mcp.json` 신뢰 승인 클릭**·**Xcode/Node 머신 설치**는 추측해서 대신하지 않고, 그 지점에서 **안내하고 멈춘다**.

## 절차

### 1. 사전 점검 (읽기 — 되돌릴 것 없음)
- repo 루트 확인: `git rev-parse --show-toplevel`.
- 도구 존재 확인: `mise`, `node`/`npx`(XcodeBuildMCP가 npx로 구동), `xcodebuild -version`(Xcode + iOS 시뮬레이터 런타임), `jq`(Claude Code 훅 2종이 사용 — 없으면 훅이 **조용히 무력화**된다. macOS 15+는 기본 포함).
- **없는 것만** 설치 안내(mise → https://mise.jdx.dev, Node → nodejs.org/brew/nvm, Xcode → App Store, jq → `brew install jq`). 다 있으면 다음 단계로.

### 2. 도구·의존성·프로젝트 (멱등)
- `mise install` — `.mise.toml`의 tuist(4.29.1) 설치.
- `tuist install` → `tuist generate`.
- `WSS-iOS-V2.xcworkspace` 생성 확인. 이미 있으면 `tuist generate`만 재실행(stale 방지).
- ⚠️ generate가 **Config 누락**으로 실패하면 4번을 먼저 처리하고 재시도.

### 3. git 훅 활성화 (멱등 — 클론 후 1회)
- `git config --get core.hooksPath` 확인 → `.githooks`가 아니면 `git config core.hooksPath .githooks`.
- 효과: ① 브랜치 전환 시 프로젝트 구조(매니페스트·파일 추가/삭제/이름변경)가 바뀌면 `.githooks/post-checkout`가 자동으로 `tuist generate`(mise 경유, 단순 내용 수정은 건드리지 않음) ② 커밋 시 `.githooks/commit-msg`가 커밋 양식 `[Type] #이슈 - 내용`을 검증(Xcode/터미널 직접 커밋 포함 — Type 표는 `commit-types.md`).

### 4. Config 비밀값 (안내 중심 — 스킬은 실제 키를 모른다)
- `Config/Config_Shared.xcconfig`·`Config_Debug.xcconfig`·`Config_Release.xcconfig` 존재 확인(`*.xcconfig`는 `.gitignore`되어 커밋 안 됨).
- **있으면**: 통과.
- **없으면** 둘 중 하나를 안내하고 사람이 고르게 한다:
  - ⓐ **실제 키(일반 개발)** — 팀 내부 배포(공유 채널/1Password 등)로 받아 `Config/`에 둔다.
  - ⓑ **placeholder(빌드/구조 확인용)** — `.github/workflows/test.yml`의 placeholder 형식으로 임시 생성(원하면 스킬이 만들어 줌). **네트워크 기능(로그인·API)은 동작하지 않음**을 분명히 밝힌다.

### 5. fastlane 서명 환경 (실기기 빌드/아카이브용 — 안내 중심, 시뮬레이터만 쓰면 건너뛰어도 됨)
- 목적: 실기기에 앱을 설치·빌드·아카이브하려면 이 단계가 필요하다(시뮬레이터 빌드/테스트는 이 단계 없이도 된다).
- Ruby/Bundler 확인: `ruby -v`/`bundle -v`(mise가 Ruby를 관리하지 않는다 — 없으면 시스템 Ruby나 rbenv/rvm 등으로 설치 안내).
- `bundle install`(repo 루트) — `Gemfile`의 `fastlane` gem 설치.
- `fastlane/.env` 존재 확인(`.gitignore`돼 있어 커밋되지 않는다).
  - **없으면**: `APP_IDENTIFIER_DEBUG`·`APP_IDENTIFIER_RELEASE`·`TEAM_ID`를 팀 내부 배포(공유 채널/
    1Password 등)로 받아 채우도록 안내하고 멈춘다.
    (`APPLE_ID`는 `Appfile`에 남아있는 V1 잔재일 뿐 이 팀의 인증 경로엔 안 쓰인다 — `match`/
    `upload_to_testflight` 전부 App Store Connect API 키로 인증한다. 굳이 채우지 않아도 된다.)
- **`MATCH_PASSWORD`는 macOS Keychain에 등록해두는 걸 권장한다**(`.env`/셸 `export`보다 우선 권장) —
  `archive-debug`/`archive-release` 스킬은 Claude Code가 백그라운드로 fastlane을 돌리는 구조라
  TTY가 없어 **대화형으로 비밀번호를 물어볼 수 없다**. `match`는 비밀번호를 ① `MATCH_PASSWORD` 환경변수
  ② macOS Keychain(`match_login.keychain` 항목) 순서로 찾으므로(실제 gem 소스로 확인됨,
  `match/lib/match/encryption/openssl.rb`), Keychain에 미리 넣어두면 `.env`에 평문으로 두지 않고도
  두 스킬이 비대화형으로 동작한다.
  - 등록 여부 확인(값은 절대 출력하지 않는다): `security find-internet-password -s "match_login.keychain"`
    — 항목이 나오면 등록됨, `security: SecKeychainSearchCopyNext: ...` 에러면 없음.
  - **없으면** 사용자에게 팀 채널에서 실제 `MATCH_PASSWORD` 값을 받아 **본인 터미널에서 직접**
    아래 명령으로 등록하도록 안내하고 멈춘다(스킬이 대신 실행하지 않는다 — 값이 이 세션에 노출된다):
    ```
    security add-internet-password -a "" -s "match_login.keychain" -w "<받은 실제 값>"
    ```
    macOS 로그인 비밀번호를 묻는 키체인 접근 팝업이 뜰 수 있다(정상, 허용).
  - `fastlane/.env`에 `MATCH_PASSWORD=`를 채워뒀다면 **비워둘 것** — `match`가 환경변수를 Keychain보다
    먼저 확인하므로, 값이 남아있으면(특히 오타 등으로 틀렸다면) 항상 그게 Keychain보다 우선 적용된다.
- match 인증서 저장소 접근 확인: `git ls-remote git@github.com:Team-WSS/WSS-iOS-Certificates.git`.
  - **실패하면**: 레포 관리자에게 그 GitHub 저장소(private)의 협업자 초대를 요청하도록 안내하고 멈춘다.
- 위 넷(Ruby/Bundler, `.env`, `MATCH_PASSWORD`, GitHub 접근)이 전부 준비됐으면:
  `bundle exec fastlane sync_dev_certificates` — development 인증서·프로비저닝 프로파일을 로컬로 받는다.
- ⚠️ **처음 쓰는 실기기라면 이 한 번으로 안 끝날 수 있다** — `match`가 받아오는 development 프로파일은
  **그 시점에 Apple Developer 계정에 등록된 기기 UDID만** 포함한다. 새 기기는 Apple Developer 포털에
  UDID를 먼저 등록하고, 관리 권한 있는 사람이 `match`를 다시 돌려 프로파일을 그 기기 포함해서
  재생성해야 실기기 빌드가 된다 — 이건 스킬이 자동으로 처리할 수 없어 안내만 한다.
- 배포 lane(`debug_beta`/`release_beta`/`release`)에 필요한 `ASC_KEY_ID`/`ASC_ISSUER_ID`/`ASC_KEY_PATH`는
  `sync_dev_certificates`엔 필요 없다 — 배포까지 할 사람만 추가로 준비(자세한 내용은 `docs/TODO.md` 4번).

### 6. MCP 신뢰 승인 (안내 — 클릭은 사람)
- Node/npx 재확인(1번에서 없었으면 먼저 설치).
- `.mcp.json`(XcodeBuildMCP)은 **Project scope**라 **첫 세션에서 신뢰 승인 1회**가 필요하다 → Claude Code 승인 프롬프트에 동의. 이미 떠 있는 세션이면 **세션 재시작 후** 승인(reconnect만으론 부족할 수 있음).
- 확인: `claude mcp list`에 `XcodeBuildMCP ... ✔ Connected`.
- user scope 충돌 함정·워크플로 등 상세는 → [docs/BUILD_AND_TEST.md](../../../docs/BUILD_AND_TEST.md).

### 7. 검증
- `WSS-iOS-V2.xcworkspace` 존재 확인.
- (선택) 빌드 한 번 — XcodeBuildMCP `build_sim`(예: scheme `BaseDomain`) 또는 Domain 테스트 `test_sim`(scheme `XxxDomainTests`).
- MCP 도구 로드 확인(예: `build_sim`·`tap` 가용).
- (실기기 빌드까지 한다면, 선택) `bundle exec fastlane sync_dev_certificates`가 에러 없이 끝나는지.

### 8. 마무리 보고
- 각 단계 결과(실행/스킵/사람 대기)를 요약하고, **사람 손이 남은 항목**(Config 실제 키, `fastlane/.env`·
  `MATCH_PASSWORD`·인증서 저장소 협업자 초대, MCP 승인 클릭)을 체크리스트로 남긴다.

## 원칙
- **멱등** — 이미 된 단계는 스킵/재생성만. 여러 번 돌려도 안전.
- **사람 몫과 자동을 분리** — 비밀키·승인 클릭·머신 설치는 안내하고 멈춘다. 더미 값을 진짜처럼 채우지 않는다.
- **단일 진실 소스** — 명령·함정은 `README.md` 셋업 섹션과 [docs/BUILD_AND_TEST.md](../../../docs/BUILD_AND_TEST.md)를 따른다(여기 복제 최소화).
