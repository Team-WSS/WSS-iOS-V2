# 작업 방식 (Workflow)

전체 구조는 [ARCHITECTURE.md](ARCHITECTURE.md), 코드 규칙은 각 `Projects/<Layer>/CLAUDE.md` 참고.
이 문서는 **프로세스**(브랜치·커밋·PR·모듈 추가·테스트·CI)만 다룬다.

## 브랜치 · 커밋 · PR

- **브랜치**: `Type/#이슈번호` — 예: `Feat/#108`, `Fix/#88`, `Docs/#130`, `Chore/#98`, `Refactor/#96`, `Design/#123`.
- **커밋 메시지**: `[Type] #이슈번호 - 한글 설명` — 예: `[Feat] #108 - 홈 화면 추천 섹션 구현`.
- **base 브랜치**: `develop` (운영 릴리스는 `main`).
- **머지는 반드시 PR 경유** — 브랜치 보호 규칙이 직접 push를 막는다.
- 작업 시작: `develop` 최신화 → `Type/#이슈`로 분기.

## 테스트 (필수)

- 새 **Domain** 코드(UseCase/Entity/정책)는 **테스트 없이 머지 금지**.
- 컨벤션·Mock 패턴은 [Projects/Domain/CLAUDE.md](../Projects/Domain/CLAUDE.md)의 "테스트" 절.
- 현재 테스트는 **Domain 레이어 한정** (Data/UI/Core/Feature는 미적용).

## CI

- 워크플로: `.github/workflows/test.yml` (`Run Domain Tests`).
- 트리거: **PR에 `/domain-test` 댓글** 또는 수동 `workflow_dispatch`.
- `Projects/Domain` 하위 폴더를 자동 스캔해 도메인별 병렬 테스트.
- ⚠️ 빈/잔재 폴더는 매트릭스를 깨뜨린다 → 정식 `XxxDomain` 폴더만 유지.

## 새 모듈 추가 절차

1. **레지스트리 먼저**: `Plugins/DependencyPlugin/ProjectDescriptionHelpers/ModuleType.swift`의 해당 enum(`DomainModule`/`DataModule`/...)에 case 추가. (단일 진실 소스)
2. **Project.swift**: `Projects/<Layer>/<Module>/Project.swift`를 템플릿(`Project.create<Layer>Module(...)`)으로 작성, `internalDependencies` 선언.
3. **`tuist generate`** 로 프로젝트 재생성.
4. 코드 작성은 해당 레이어 규칙(`Projects/<Layer>/CLAUDE.md`) 준수.
5. **모듈 가이드 작성**: `docs/MODULE_GUIDE_TEMPLATE.md`를 복사해 `Projects/<Layer>/<Module>/CLAUDE.md` 생성 (함정·시나리오 중심).
6. Domain이면 테스트 작성 (CI는 폴더만 있으면 자동 인식).

## 자주 쓰는 명령

```bash
mise install        # Tuist 설치
tuist install       # 의존성 설치
tuist generate      # 프로젝트 생성
```

## 문서 유지

- 코드와 문서가 다르면 **코드가 진실** — 가장 가까운 `CLAUDE.md`를 즉시 고친다.
- 작업 중 발견한 함정은 해당 문서의 "주의사항" 절에 누적.
