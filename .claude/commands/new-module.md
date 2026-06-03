---
description: 새 Tuist 모듈을 생성한다 (레이어+모듈명 인자, 의존성 자동 추론)
---

새 모듈을 만든다. 인자: `$ARGUMENTS` (형식: `<layer> <ModuleName>`, 예: `data Foo`, `domain Foo`, `ui FooView`).
`layer` ∈ `domain | data | core | ui | feature`.

> ⚠️ **drift 방지**: 값을 추측하지 말고 항상 (1) `Plugins/DependencyPlugin/ProjectDescriptionHelpers/ModuleType.swift`
> 와 (2) **같은 레이어의 기존 모듈 `Project.swift`** 를 먼저 읽어 현재 패턴을 그대로 따른다.

## 절차

### 1. 인자 파싱
- `layer`, `ModuleName` 확보. 비면 사용자에게 묻는다.
- enum case는 camelCase (예: `novelReview`), 모듈명은 `ModuleType.name`이 만든다(`Xxx`+suffix). 헷갈리면 `ModuleType.swift`의 `name`/`directoryName` 로직 확인.

### 2. ModuleType.swift 등록 (단일 진실 소스)
- 해당 enum에 case 추가: `domain`→`DomainModule`, `data`→`DataModule`, `core`→`CoreModule`, `ui`→`UIModule`, `feature`→`FeatureModule`.
- 기존 정렬/스타일 유지. (UI는 `name` 커스텀 매핑이 있는지 확인)

### 3. 의존성 추론 (기본값 — 형제 모듈로 검증 후 조정)
- **domain**: `[.module(.domain(.base))]`
- **data**: `[.module(.core(.networking)), .module(.core(.logger)), .module(.data(.base)), .module(.domain(.base)), .module(.domain(.<같은이름>))]`
  - 토큰/인증 관련이면 `.module(.core(.keychain))` 추가.
  - ⚠️ 대응 `<같은이름>Domain`이 없으면 사용자에게 알리고, 먼저 domain부터 만들지 물어본다.
- **ui**: `[.module(.ui(.designSystem)), .module(.domain(.base))]`
- **core**: 기본 `[]`, 필요한 다른 core만.
- **feature** (미검증 레이어): `[.module(.domain(.base)), .module(.domain(.<같은이름>)), .module(.ui(.designSystem)), .module(.ui(.wssComponent))]` — 첫 생성이면 사용자와 확인.
- 추론한 의존성은 **왜 넣었는지 한 줄로 보고**하고, 애매하면 확인받는다.

### 4. Project.swift 생성
`Projects/<directoryName>/<ModuleName>/Project.swift` 생성. **같은 레이어 기존 모듈을 복제**해 `create<Layer>Module(...)` 형태/`targets`/`internalDependencies`를 맞춘다.
- targets 기본: domain `[.sources, .testing, .tests]`, data/core `[.sources, .demo, .testing, .tests]`, ui `[.sources, .demo]`.

### 5. 소스 디렉토리
- `Sources/` 생성. 레이어 표준 하위 폴더를 만든다(빈 폴더 대신 최소 placeholder 또는 첫 타입):
  - domain: `Entity/`, `UseCase/`, `Repository/`
  - data: `DTO/`, `Service/`, `Mapper/`, `Repository/`, `Factory/`, `Endpoint/`, `Logger/`
- domain이면 `Testing/`, `Tests/{Entity,UseCase}/`도.

### 6. 프로젝트 생성
- `tuist generate` 실행. 실패하면 출력 그대로 보고 (에셋/Derived 문제면 안내).

### 7. 모듈 가이드
- `docs/MODULE_GUIDE_TEMPLATE.md`를 복사해 `Projects/<dir>/<ModuleName>/CLAUDE.md` 작성 (시나리오·함정 중심, 지금은 골격만).

### 8. 마무리 보고
- 등록한 case, 생성 파일, **선택한 의존성과 근거**를 요약.
- domain이면: "테스트 필수 — `docs/TESTING.md`, CI는 `/domain-test`로 폴더 자동 인식" 안내.
- 커밋은 사용자가 지시할 때만. ([Type] #이슈 규약은 docs/WORKFLOW.md)
