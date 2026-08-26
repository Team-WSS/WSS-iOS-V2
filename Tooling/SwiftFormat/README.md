# swift-format 스타일 게이트 (A3)

새로 짜는 Swift 코드의 스타일을 CI가 검사한다. 도구는 Apple **swift-format**(Swift 툴체인 번들 — 별도 설치 없음). AI 검증 체계(#205 축 A)의 A3.

## 구성

| 파일 | 역할 |
|---|---|
| `.swift-format` (레포 루트) | 규칙 allowlist(JSON). swift-format이 각 파일 기준 상위 탐색으로 자동 발견 |
| `Tooling/SwiftFormat/lint-changed.sh` | CI·로컬 공용. 변경된 `.swift`만 lint. report-only 기본 / `--strict`로 게이트 |
| `.github/workflows/test.yml`의 `Swift Format` job | `container: swift:6.3.3`, report-only. 첫 스텝 `swift format --version`으로 번들 실재 검증 |

## 왜 "변경 파일만"인가

`swift format lint`는 rule 몇 개가 아니라 **"이 파일을 format하면 바뀌는가?"의 전체 포매터 diff**다 —
들여쓰기·spacing·줄끝공백 같은 레이아웃 진단은 `rules`와 무관하게 항상 켜져 끌 수 없다. 그래서 레거시
886파일을 통째로 게이트하면 튜닝해도 ~8,500건이 쏟아진다. A3 목표는 "새로 짜는 코드의 스타일 검사"라,
base(develop) 대비 이번 브랜치가 건드린 파일만 본다(레거시 백로그 제외). 전체 1회 리포맷 후 whole-repo
`--strict`로 격상하는 계획은 `docs/TODO.md`(AI 검증 후속) 3번.

## 규칙 선정 — 왜 이렇게 껐나 (⚠️ `.swift-format` 되돌리기 전 필독)

전 규칙 41개를 켜서 실측한 위반수로 정했다(**ON 30 · OFF 11**). 대부분 레포가 이미 준수해 청소 비용 ~0의
"미래 드리프트 방지" 앵커다. `.swift-format`은 JSON이라 주석을 못 담으니 **OFF 근거를 여기 남긴다** —
자동수정·기본값 복귀로 되살리면 아래처럼 규약이 깨진다:

- **`OrderedImports`** — swift-format은 **알파벳 정렬**인데 `docs/CONVENTIONS.md`가 **레이어 순서**
  (Foundation→Domain→Data→Core→UI, Base 우선)를 규정 → **정면 충돌**(770곳, 대부분 정상 코드). **절대 켜지 말 것.**
- **`NoAccessLevelOnExtensionDeclaration`** — 레포가 `public extension`을 의도적 관용으로 196곳 사용.
- **문서화 3종**(`AllPublicDeclarationsHaveDocumentation`·`BeginDocumentationCommentWithOneLineSummary`·
  `ValidateDocumentationComments`) — 전면 문서화를 하지 않는다.
- **`NoEmptyLinesOpeningClosingBraces`** — 중괄호 안 빈 줄을 의도적으로 쓴다.
- **`NeverForceUnwrap`·`NeverUseForceTry`·`NeverUseImplicitlyUnwrappedOptionals`** — iOS 관용(`!`·`try!`·`String!`).
  스타일이 아니라 **팀 안전성 결정** 사안이라 스타일 게이트와 분리한다.
- **`OmitExplicitReturns`·`UseEarlyExits`** — 취향·혼용이라 강제하지 않는다.

## 로컬에서 돌려보기

```bash
Tooling/SwiftFormat/lint-changed.sh              # report-only (변경 파일만)
Tooling/SwiftFormat/lint-changed.sh --strict     # 위반 있으면 exit 1
swift format format -i <파일>                     # 자동 수정
```

## 승격(required check) 순서

report-only로 착지 → develop 초록 + 컨테이너에 swift-format 실재 확인 → `lint-changed.sh --strict` + `Swift Format`을
develop 보호의 필수 통과 체크로 승격(**사람 액션**). A1(`All Tests Passed`)·A2(`Architecture Rules`)와 동일 순서 —
새 기계 게이트는 "드러난 위반을 청소해 초록으로 만든 뒤" required로 올린다.
