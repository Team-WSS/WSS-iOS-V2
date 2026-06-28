# 빌드 · 테스트 · UI 검증

에이전트(Claude Code)와 로컬에서 **빌드·테스트·Feature 화면 검증**을 어떤 도구로 돌리는지 정리한다.
주력은 **XcodeBuildMCP**(구조화된 저토큰 출력·시뮬레이터 수명관리·UI 조작). `tuist`는 프로젝트 생성 전용.

## 작업별 도구

| 작업 | 도구 | 비고 |
|---|---|---|
| 프로젝트 생성/의존성 | `tuist install` → `tuist generate` | 모든 빌드/테스트의 선행 |
| Domain 단위 테스트 | XcodeBuildMCP `test_sim` (scheme `XxxDomainTests`) | CI는 `xcodebuild test`(아래) |
| 모듈/앱 빌드 | XcodeBuildMCP `build_sim` / `build_run_sim` | 에러를 file:line으로 압축 반환 |
| **Feature 화면 띄우기** | `build_run_sim` (scheme **`XxxFeature`**) | 전체 App 조립 불필요, Demo 앱 단독 실행 |
| 시각 검증 | `screenshot` / `record_sim_video` | 스크린샷을 에이전트가 직접 봄 |
| 상태/요소 검증 | `snapshot_ui` | 접근성 트리(라벨·상태·`elementRef`) |
| **조작(탭·입력·스와이프)** | `tap` / `type_text` / `swipe` | `ui-automation` 워크플로 |
| 가벼운 SwiftUI 레이아웃 | (옵션) xcode MCP `RenderPreview` | `#Preview` 있을 때, Xcode 앱 열려 있어야 |
| CI 실패 정밀 재현 | `xcodebuild test ... \| xcbeautify` | `.github/workflows/test.yml`의 호출 그대로 |

## 도구 셋업이 팀 전체에 동일하게 적용되는 구조

- **`.mcp.json`(레포 루트, 커밋)** 가 XcodeBuildMCP 서버와 워크플로(`simulator,ui-automation,project-discovery`)를 정의한다.
  MCP scope 우선순위는 **Local > Project > User** — `.mcp.json`은 **Project scope**라 이 레포 안에서 개인 전역(User scope) 정의를 override한다(다른 프로젝트엔 영향 없음).
- **팀원은 레포 첫 진입 시 `.mcp.json` 신뢰 승인 1회**만 하면 도구가 로드된다(`claude mcp reset-project-choices`로 리셋).
- **함정(설정 적용 타이밍)**: `.mcp.json`을 **세션 도중 추가하면 `/mcp` reconnect로는 부족**하고 세션 재시작이 필요하다(세션 시작 시 발견·승인되므로). 팀원은 첫 세션에서 자동 발견되어 무관.
- **함정(본인 머신 등 user scope에 동명 서버가 있을 때)**: user scope에 같은 이름 서버가 이미 있으면 project `.mcp.json`이 **가려진다**(실측 — 문서상 precedence와 다름). 이땐 user scope 정의에 **같은 env를 넣어 맞추거나**(`claude mcp add ... -s user -e ...`) user scope를 제거한다. 팀원은 user scope에 없으니 영향 없음.
- 권한은 **`.claude/settings.json`**(`permissions.allow`)에 있어 `tuist`/`xcodebuild`/XcodeBuildMCP 호출이 프롬프트 없이 통과한다.

**각자 머신에 있어야 하는 것(공유 불가):** Xcode + iOS 시뮬레이터 런타임 · Node/npx(XcodeBuildMCP가 npx로 구동) · mise(tuist 관리).

## 함정 (실측으로 확인된 것 — 코드만 봐선 모름)

1. **incremental 빌드(xcodemake)는 Tuist 워크스페이스를 깬다.** `.mcp.json`에서 `INCREMENTAL_BUILDS_ENABLED=false`로 끈다(표준 xcodebuild 사용). 켜져 있으면 `preferXcodebuild` 폴백을 강제당한다.
2. **Feature 실행 스킴은 `XxxFeature`** — 별도 `XxxFeatureDemo` 스킴은 없다. 이 스킴의 LaunchAction이 `XxxFeatureDemo.app`을 띄운다.
3. **`launch_app_sim`용 bundleId는 `kr.websoso.app.XxxFeatureDemo`** — `build_run_sim`이 보고하는 bundleId는 framework(`...XxxFeature`)라 그걸 그대로 launch에 쓰면 `SBMainWorkspace` 거부로 실패. Demo 앱 ID는 `.app/Info.plist` 또는 `simctl listapps`로 확인.
4. **별점(★) 등 커스텀 드로잉은 접근성 tap 타겟으로 안 잡힌다** → `snapshot_ui`에 안 뜨면 좌표 탭. 표준 버튼/세그먼트/매력포인트는 `elementRef`로 잡힌다.
5. **Demo `Mock` 모드는 일부 화면 미연결**(예: 키워드 입력) — 네트워크 의존 플로우는 `실서버` 토글이 필요.
6. **`SNAPSHOT_EXPIRED`는 흔하다** — `tap`/`type_text` 직전에 `snapshot_ui`로 fresh `elementRef`를 다시 확보한다.
7. **`build_run_sim`은 Feature 스킴에서 install이 framework를 잡아 실패**할 수 있다("installable app 없음" / "did not contain any installable apps"). 컴파일은 되지만 설치 대상을 `XxxFeature.framework`로 고르기 때문. → `build_sim`(컴파일)으로 빌드한 뒤 `install_app_sim`+`launch_app_sim`(bundleId `...XxxFeatureDemo`)으로 띄운다.
