---
name: setup
description: WSS-iOS-V2를 클론한 뒤 개발 환경을 처음 셋업할 때 사용한다. mise install → tuist install → tuist generate → git 훅 활성화(core.hooksPath) → Config 비밀값 확인 → .mcp.json 신뢰 승인까지 단계별로 점검·실행·안내한다. "초기 셋업", "환경 세팅", "처음 클론했어", 또는 "/setup" 같은 요청에 트리거. 실제 Config 비밀키 값·MCP 신뢰 승인 클릭·머신 설치(Xcode/Node)는 사람만 할 수 있어 스킬은 그 지점을 정확히 안내하고 멈춘다.
metadata:
  short-description: 클론 후 초기 개발환경 셋업 (도구·Tuist·git훅·Config·MCP 점검·안내)
---

# Setup — 초기 개발환경 셋업 (WSS-iOS-V2)

레포를 클론한 직후 한 번 돌린다. 인자: 없음. 이미 셋업된 환경에서 다시 돌려도 안전하다(각 단계 **멱등** — 이미 됐으면 스킵/재생성만).

> ⚠️ 스킬이 **실행**하는 것(도구·Tuist·git 훅)과 **사람만 할 수 있는 것**을 구분한다.
> **실제 Config 비밀키 값**·**`.mcp.json` 신뢰 승인 클릭**·**Xcode/Node 머신 설치**는 추측해서 대신하지 않고, 그 지점에서 **안내하고 멈춘다**.

## 절차

### 1. 사전 점검 (읽기 — 되돌릴 것 없음)
- repo 루트 확인: `git rev-parse --show-toplevel`.
- 도구 존재 확인: `mise`, `node`/`npx`(XcodeBuildMCP가 npx로 구동), `xcodebuild -version`(Xcode + iOS 시뮬레이터 런타임).
- **없는 것만** 설치 안내(mise → https://mise.jdx.dev, Node → nodejs.org/brew/nvm, Xcode → App Store). 다 있으면 다음 단계로.

### 2. 도구·의존성·프로젝트 (멱등)
- `mise install` — `.mise.toml`의 tuist(4.29.1) 설치.
- `tuist install` → `tuist generate`.
- `WSS-iOS-V2.xcworkspace` 생성 확인. 이미 있으면 `tuist generate`만 재실행(stale 방지).
- ⚠️ generate가 **Config 누락**으로 실패하면 4번을 먼저 처리하고 재시도.

### 3. git 훅 활성화 (멱등 — 클론 후 1회)
- `git config --get core.hooksPath` 확인 → `.githooks`가 아니면 `git config core.hooksPath .githooks`.
- 효과: 브랜치 전환 시 프로젝트 구조(매니페스트·파일 추가/삭제/이름변경)가 바뀌면 `.githooks/post-checkout`가 자동으로 `tuist generate`(mise 경유). 단순 내용 수정은 건드리지 않는다.

### 4. Config 비밀값 (안내 중심 — 스킬은 실제 키를 모른다)
- `Config/Config_Shared.xcconfig`·`Config_Debug.xcconfig`·`Config_Release.xcconfig` 존재 확인(`*.xcconfig`는 `.gitignore`되어 커밋 안 됨).
- **있으면**: 통과.
- **없으면** 둘 중 하나를 안내하고 사람이 고르게 한다:
  - ⓐ **실제 키(일반 개발)** — 팀 내부 배포(공유 채널/1Password 등)로 받아 `Config/`에 둔다.
  - ⓑ **placeholder(빌드/구조 확인용)** — `.github/workflows/test.yml`의 placeholder 형식으로 임시 생성(원하면 스킬이 만들어 줌). **네트워크 기능(로그인·API)은 동작하지 않음**을 분명히 밝힌다.

### 5. MCP 신뢰 승인 (안내 — 클릭은 사람)
- Node/npx 재확인(1번에서 없었으면 먼저 설치).
- `.mcp.json`(XcodeBuildMCP)은 **Project scope**라 **첫 세션에서 신뢰 승인 1회**가 필요하다 → Claude Code 승인 프롬프트에 동의. 이미 떠 있는 세션이면 **세션 재시작 후** 승인(reconnect만으론 부족할 수 있음).
- 확인: `claude mcp list`에 `XcodeBuildMCP ... ✔ Connected`.
- user scope 충돌 함정·워크플로 등 상세는 → [docs/BUILD_AND_TEST.md](../../../docs/BUILD_AND_TEST.md).

### 6. 검증
- `WSS-iOS-V2.xcworkspace` 존재 확인.
- (선택) 빌드 한 번 — XcodeBuildMCP `build_sim`(예: scheme `BaseDomain`) 또는 Domain 테스트 `test_sim`(scheme `XxxDomainTests`).
- MCP 도구 로드 확인(예: `build_sim`·`tap` 가용).

### 7. 마무리 보고
- 각 단계 결과(실행/스킵/사람 대기)를 요약하고, **사람 손이 남은 항목(Config 실제 키, MCP 승인 클릭)** 을 체크리스트로 남긴다.

## 원칙
- **멱등** — 이미 된 단계는 스킵/재생성만. 여러 번 돌려도 안전.
- **사람 몫과 자동을 분리** — 비밀키·승인 클릭·머신 설치는 안내하고 멈춘다. 더미 값을 진짜처럼 채우지 않는다.
- **단일 진실 소스** — 명령·함정은 `README.md` 셋업 섹션과 [docs/BUILD_AND_TEST.md](../../../docs/BUILD_AND_TEST.md)를 따른다(여기 복제 최소화).
