# 빌드 · 테스트 · UI 검증

에이전트(Claude Code)와 로컬에서 **빌드·테스트·Feature 화면 검증**을 어떤 도구로 돌리는지 정리한다.
주력은 **XcodeBuildMCP**(구조화된 저토큰 출력·시뮬레이터 수명관리·UI 조작). `tuist`는 프로젝트 생성 전용.

## 작업별 도구

| 작업 | 도구 | 비고 |
|---|---|---|
| 프로젝트 생성/의존성 | `tuist install` → `tuist generate` | 모든 빌드/테스트의 선행 |
| Domain 단위 테스트 | XcodeBuildMCP `test_sim` (scheme **`XxxDomain`**) | CI는 `xcodebuild test`(아래) |
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
3. **`launch_app_sim`용 bundleId는 `<env.organizationName>.XxxFeatureDemo`**(`ProjectEnvironment.swift`의 `organizationName` 참고) — `build_run_sim`이 보고하는 bundleId는 framework(`...XxxFeature`)라 그걸 그대로 launch에 쓰면 `SBMainWorkspace` 거부로 실패. Demo 앱 ID는 `.app/Info.plist` 또는 `simctl listapps`로 확인.
4. **별점(★) 등 커스텀 드로잉은 접근성 tap 타겟으로 안 잡힌다** → `snapshot_ui`에 안 뜨면 좌표 탭. 표준 버튼/세그먼트/매력포인트는 `elementRef`로 잡힌다.
5. **Demo `Mock` 모드는 일부 화면 미연결**(예: 키워드 입력) — 네트워크 의존 플로우는 `실서버` 토글이 필요.
6. **`SNAPSHOT_EXPIRED`는 흔하다** — `tap`/`type_text` 직전에 `snapshot_ui`로 fresh `elementRef`를 다시 확보한다.
7. **`build_run_sim`은 Feature 스킴에서 install이 framework를 잡아 실패**할 수 있다("installable app 없음" / "did not contain any installable apps"). 컴파일은 되지만 설치 대상을 `XxxFeature.framework`로 고르기 때문. → `build_sim`(컴파일)으로 빌드한 뒤 `install_app_sim`+`launch_app_sim`(bundleId `...XxxFeatureDemo`)으로 띄운다.
8. ⚠️ **`XxxDomainTests`라는 스킴은 없다** — 테스트 타깃 이름일 뿐이라 `test_sim`에 넘기면 "workspace does not contain a scheme" 로 튕긴다(#179 실측). 테스트도 모듈 스킴(`RecommendationDomain`)으로 돌리면 그 안의 Tests 타깃이 함께 실행된다. `tuist test <모듈>`도 되지만 요약 출력이 XCTest 기준(`Executed 0 tests`)이라 **Swift Testing 결과가 안 보이므로**, 통과 건수를 확인하려면 `test_sim`을 쓴다.
9. ⚠️ **`gesture(preset: "swipe-from-left-edge")`로는 화면 가장자리 스와이프 뒤로가기(pop)를 검증할 수 없다**(실측 — delta·duration을 바꿔도 화면이 안 바뀜). **시스템 네비바가 살아 있어 스와이프백이 기본 동작해야 하는 대조군에서도 pop이 안 일어난다** → 도구 한계지 코드 문제가 아니다. 커스텀 헤더 화면(`toolbar(.hidden)` + `SwipeBackEnabler`)을 만들면 **스와이프백은 사람이 손으로 확인**해야 한다. 자동화로 안 된다고 코드를 고치러 들어가지 말 것(원인 오진으로 시간 낭비).
10. ⚠️ **`build_sim`은 호출 인자로 준 `scheme`보다 세션 기본 스킴(`session_show_defaults`의 scheme)을 우선한다**(실측). 기본이 `WSS-iOS`인데 `build_sim(scheme: "XxxFeature")`를 줘도 **`WSS-iOS`(Websoso.app)를 빌드**하고 성공(SUCCEEDED)까지 반환한다 → Feature framework는 **낡은 채로 남아** 코드 변경이 반영 안 된 Demo를 검증하게 된다(무증상, 빌드 3초 내외로 빨리 끝나면 의심). **Feature Demo를 검증할 땐 먼저 `session_set_defaults(scheme: "XxxFeature")`로 기본 스킴을 바꾼 뒤 빌드**할 것. 실제 리빌드는 프레임워크 바이너리 mtime(`.../Build/Products/Debug-iphonesimulator/XxxFeature.framework/XxxFeature`)이 갱신됐는지로 확인 가능.
    - **`build_sim`만 그런 게 아니다** — `get_sim_app_path`도 인자 스킴을 무시하고 **기본 스킴의 경로**(`HomeFeature.framework` 등)를 돌려주고, `launch_app_sim`은 인자로 준 `bundleId`를 아예 못 본 채 "bundleId is required"로 튕긴다. 즉 인자로 우회할 수 없으니 **세션 기본값 자체를 바꾸는 게 유일한 길**이다(`session_set_defaults`로 scheme·simulatorId·bundleId를 함께 지정).
    - 오진 경로가 특히 고약하다: 엉뚱한 스킴이 **SUCCEEDED로 끝나** 빌드가 통과한 줄 알게 되고, `get_sim_app_path`가 준 경로도 그럴듯해 **바꾼 코드가 컴파일조차 안 된 사실을 놓친다**(#181에서 실제로 발생). 빌드 로그의 `-scheme` 값(`grep -o "\-scheme [A-Za-z]*"`)을 보면 1초에 판별된다.
11. ⚠️ **`ready-merge.sh build-all`(= `tuist build`)은 첫 실패에서 멈추고, 그 실패가 내 변경과 무관할 수 있다** — 지금은 `Logger` 스킴이 항상 실패한다(`Demo/Demo.swift`가 헤더 주석만 있는 빈 스텁이라 `LoggerDemo` 앱에 `@main`이 없어 `Undefined symbols: _main`으로 링크가 깨진다). 그 뒤 scheme들은 **검증되지 않은 채 남으므로**, "전체 통과"로 읽지 말고 **변경한 모듈 스킴을 직접 지정해** 확인할 것(`tuist build <모듈> --platform ios -d "<시뮬레이터>"`). #195 rebase 검증에서 실제로 걸렸다.
    - 기본 시뮬레이터 이름(`iPhone 17`)이 그 머신에 없으면 코드와 무관하게 즉시 FAIL한다 — 출력의 `Did find` 목록에서 골라 인자로 넘긴다(`build-all "iPhone 17 Pro"`).
12. ⚠️ **rebase·브랜치 전환으로 파일이 새로 들어오면 빌드 전에 `tuist generate`를 다시 돌린다** — 생성된 프로젝트가 낡으면 그 파일이 **컴파일 대상에서 통째로 빠지고**, 에러는 엉뚱하게 그 타입을 쓰는 다른 모듈에서 `cannot find 'X' in scope`로 뜬다(#195 rebase에서 `LibraryPageSizePolicy`가 이렇게 걸렸다). "왜 방금 만든 타입을 못 찾지"가 신호다 — 그 모듈이 해당 `.swift`를 컴파일했는지 빌드 로그에서 먼저 확인할 것.
