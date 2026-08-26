# ArchLint — WSS 아키텍처 검사기 (A2)

리뷰어 눈이 새고 코드만 봐선 못 잡는 아키텍처 규칙을 **CI에서 자동으로 실패**시키는 자체 검사기.
`swift-syntax`로 소스를 AST 파싱하므로 **주석·문자열 속 토큰을 오탐하지 않는다**(grep 대비 핵심 강점).

> 앱에 링크되지 않는 **개발 도구**다. `swift-syntax`는 Swift.org 공식 프로젝트라
> "외부 의존성 없음" 원칙(앱 런타임)과 무관하다. Tuist 그래프 밖의 독립 SwiftPM 패키지라
> 에디터(Xcode 인덱서)가 `No such module` 가짜 경고를 낼 수 있으나 `swift build`는 정상이다.

## 구조

- `Sources/ArchLintCore/` — 규칙 9개(파일 단위 8 + 모듈 단위 1) + 스캔/파싱 로직(라이브러리)
- `Sources/ArchLint/` — 얇은 실행 파일(`main.swift` → `runArchLint(...)` 호출)
- `Tests/ArchLintCoreTests/` — 규칙 자체 테스트

로직을 라이브러리로 뺀 이유: SwiftPM에서 **실행 타깃은 테스트가 import 못 하기** 때문(규칙을 테스트하려면 필수).

## 실행

```bash
swift run  --package-path Tooling/ArchLint ArchLint .   # 검사 실행 (인자: 레포 루트, 기본 ".")
swift test --package-path Tooling/ArchLint              # 규칙 자체 테스트 (회귀 그물)
ARCHLINT_DEBUG=1 swift run ...                          # 스캔·매칭 진단을 stderr로
```

`<root>/Projects` 아래 모든 `.swift`를 파싱해 규칙을 적용한다.
**error가 하나라도 있으면 종료코드 1**(게이트 실패), warning만 있으면 0.
CI(`GITHUB_ACTIONS=true`)에서는 `::error`/`::warning` 주석도 emit 해 위반이 PR diff에 인라인으로 붙는다.

## 심각도 — error vs warning (중요)

문법이 곧 위반인 규칙만 **error(하드 게이트)** 로 둔다. 문법이 위반의 *프록시*일 뿐인 규칙은
**warning(리포트만)** 으로 둔다 — 정당한 코드를 오탐해 멀쩡한 PR을 막지 않기 위해서.
(warning으로 수집하다 프록시 정확도가 실전에서 검증되면 error로 승격 — A4 철학.)

| 규칙 | id | 심각도 | 대상 | 내용 |
|---|---|---|---|---|
| ① VM 계약 | `vm-contract` | **error** | `Projects/{Feature,UI}/**/Sources` | `ObservableObject` 채택·`@Published`·`@StateObject`·`@ObservedObject`·`@EnvironmentObject` 금지. 문법==의미라 예외 없음. |
| ②-포지티브 VM 상태 | `vm-observable-state` | **error** | `Projects/{Feature,UI}/**/Sources` | `*ViewModel`은 `@Observable` + `private(set) var state` 필수(①의 짝 — "있어야 하는 것"). `*ViewModel` 네이밍 기준. |
| ③ 의존성 방향 | `dependency-direction` | **error** | `Projects/**/Project.swift` | 모듈이 선언한 internalDependencies의 레이어 방향 강제(App→Feature→(UI/Domain)←Data→Core). `ui→domain`은 허용. 매니페스트 선언이라 명확한 위반. |
| ⑤ Service 분기 | `service-no-branch` | warning | `Projects/Data/**/*Service*` (Sources) | `if`/`switch`/삼항(`?:`) 금지(매핑 leak 방지). `guard`·에러 전파는 제외. 분기≠항상 leak이라 프록시. |
| ⑦ Service 쿼리 조립 | `service-no-query-build` | warning | `Projects/Data/**/*Service*` (Sources) | `XxxQuery(...)` 생성자 호출 금지 — 완성 Query를 Input으로 받게 강제해 매핑 leak을 문법적으로 예방. `*Query` 네이밍 휴리스틱이라 프록시. |
| ⑧ VM 네이밍(역방향) | `vm-naming-reverse` | **error** | `Projects/{Feature,UI}/**/Sources` | `@Observable` class는 이름이 `*ViewModel`이어야 한다(②의 역방향 — "@Observable ⇔ ViewModel"을 닫는다). `@Observable`는 class 전용 매크로라 예외 없음. |
| ⑨ UseCase 네이밍 | `usecase-naming` | **error** | `Projects/Domain/**/Sources/UseCase` | 폴더의 **protocol**은 이름이 `*UseCase`. 곁에 사는 `Default*` 구현·반환 Entity(`HomeData` 등)는 대상이 아니라 protocol만 본다. |
| ⑩ Repository 네이밍 | `repository-naming` | **error** | `Projects/Domain/**/Sources/Repository` | 폴더의 **protocol**은 이름이 `*Repository`. 곁 enum(`AuthError`·`ProfileTarget`)은 대상이 아니라 protocol만 본다. |
| ⑪ Factory 존재성 | `factory-existence` | **error** | `Projects/Data/<Module>` (모듈 단위) | 각 Data 모듈은 조립 진입점 `public *DataFactory`를 노출한다. BaseData(공용 토대)는 제외. 파일이 아니라 모듈 전체를 봐야 해 `ModuleRule`로 둔다. |
| ⑫ Factory 배타성 | `factory-exclusivity` | **error** | `Projects/Data/<Module>` (모듈 단위) | ⑪의 짝 — Data 모듈의 top-level public은 `*DataFactory` **하나뿐**이어야 한다(Repository·Service·Mapper·DTO·Logger 등 나머지는 internal). "상위 레이어는 Factory만 안다"를 조인다. 타입 내부 멤버 public은 바깥이 internal이면 무해라 top-level만 본다. BaseData 제외. |

## 규칙 추가하기

1. `Sources/ArchLintCore/`에 `Rule` 채택 struct + `SyntaxVisitor` 서브클래스를 만든다
   (`VMContractRule.swift` 참고). `applies(to:)`로 경로 스코프를, `check(...)`로 위반을 낸다.
2. `Linter.swift`의 `allRules` 배열에 등록한다.
3. **함정 — 삼항은 `TernaryExprSyntax`가 아니다**: 연산자 폴딩 전 raw 트리에선 삼항이
   `SequenceExpr` 안의 **`UnresolvedTernaryExprSyntax`** 로 나타난다. 폴딩을 돌리지 않으므로
   `visit(UnresolvedTernaryExprSyntax)`를 잡아야 한다(`if`/`switch`는 구문 단위라 정상). `ServiceBranchRule` 참고.
4. **`Tests/ArchLintCoreTests`에 테스트를 추가한다** — 소스 문자열에 규칙을 돌려 위반을 단언한다
   (error/warning 경로 + 오탐 없음 둘 다). 레포가 이미 초록이라 **위반 경로는 이 테스트로만 검증된다** →
   규칙을 나중에 건드려 감지가 깨지면 `swift test`가 잡는다(회귀 그물).

### 모듈 단위 규칙(`ModuleRule`)

"이 파일에 X가 있으면 안 된다"가 아니라 **"이 모듈에 X가 있어야 한다"** 같은 집계 조건은
파일 단위 `Rule`로 표현할 수 없다. 그럴 땐 `ModuleRule`을 채택하고 `allModuleRules`에 등록한다.
드라이버는 **Project.swift를 가진 정식 모듈만** 골라(유령 폴더 자동 제외) 모듈별로 `check(moduleName:files:)`를
부른다 — `files`는 그 모듈에서 규칙의 `applies`를 통과한 파일들. 테스트는 `lintModule(sources:moduleName:rule:)`로
여러 소스를 한 모듈로 묶어 돌린다(`FactoryExistenceRule` 참고).

## CI

`.github/workflows/test.yml`의 `arch-lint` job(`name: Architecture Rules`)이 PR마다 ubuntu +
공식 `swift:6.3.3` 컨테이너에서 돈다(Xcode 불필요). job은 **먼저 `swift test`로 규칙 자체를 검증**한 뒤
`swift run`으로 레포를 검사한다(규칙이 깨졌으면 레포 검사 전에 먼저 빨간불). 이 **job 이름을 develop
보호의 필수 통과 체크**로 건다 — 단일 job이라 test 매트릭스의 `All Tests Passed` 같은 gate 래퍼가 필요 없다.
단, 필수 체크로 켜는 건 **develop이 초록인 걸 확인한 뒤**(그전엔 모든 PR이 막힌다).
