# 작업 방식 (Workflow)

전체 구조는 [ARCHITECTURE.md](ARCHITECTURE.md), 코드 규칙은 각 레이어 가이드(`Projects/<Layer>/CLAUDE.md`) 참고.
이 문서는 **프로세스**(브랜치·커밋·PR·모듈 추가·테스트·CI)만 다룬다.

## 브랜치 · 커밋 · PR

- **브랜치**: `Type/#이슈번호` — 예: `Feat/#108`, `Fix/#88`, `Docs/#130`, `Chore/#98`, `Refactor/#96`, `Design/#123`.
- **커밋 메시지**: `[Type] #이슈번호 - 한글 설명` — 예: `[Feat] #108 - 홈 화면 추천 섹션 구현`.
  - 양식은 `.githooks/commit-msg` 훅이 로컬 커밋 시 검증한다(Xcode/터미널 직접 커밋 포함). Type 어휘의 단일 진실 소스는 `.claude/skills/commit-types.md`. 훅 활성화는 클론 후 1회 `git config core.hooksPath .githooks`(`/setup`이 안내).
- **base 브랜치**: `develop` (운영 릴리스는 `main`).
- **머지는 반드시 PR 경유** — 브랜치 보호 규칙이 직접 push를 막는다.
- 작업 시작: `develop` 최신화 → `Type/#이슈`로 분기.

## 스킬 체인 (작업 한 사이클)

한 작업은 아래 스킬 순서를 탄다. 메인이 **전환점마다 다음 스킬을 능동 제안**한다(행동 규칙은 루트 `CLAUDE.md` "작업 흐름" 절). 절차·함정은 각 `SKILL.md`가 정본.

1. **`new-issue`** — GitHub 이슈 생성 + `Type/#이슈` 브랜치 분기·push (외부 비가역 → 승인 게이트).
2. **`new-feature`** *(Feature 작업 한정)* — 모듈 생성 → View/VM·Factory 골격 → Figma→WSS UI → 리뷰 수렴.
3. **`make-PR`** — 통합 리뷰 수렴 → 관련 문서 동기화 → PR 본문 검토 → GitHub PR 생성 (**PR 생성까지만**).
4. **`ready-merge`** — 작업 브랜치를 `develop` 위로 rebase + `--force-with-lease` push로 머지 가능 상태로 (**머지 버튼은 사람이**).

비-Feature 작업은 2번을 건너뛴다(`new-issue` → 작업 → `make-PR` → `ready-merge`).

## 테스트 (필수)

- 새 **Domain** 코드(UseCase/Entity/정책)는 **테스트 없이 머지 금지**.
- 철학·컨벤션·Mock 패턴은 [docs/TESTING.md](TESTING.md) (테스트=읽히는 명세).
- **테스트 없이 머지 금지 의무는 Domain 한정**. 단 Data·Feature에도 테스트가 있으면 CI가 함께 돌려 지킨다.

## CI

- 워크플로: `.github/workflows/test.yml` (`Run Tests`).
- 트리거: **develop 대상 PR을 올리면 자동 실행**. `/domain-test` 댓글·수동 `workflow_dispatch`는 재실행용.
- `Project.swift`가 `.tests` 타깃을 선언한 **정식 모듈(Domain·Data·Feature)** 을 자동 스캔해 모듈별 병렬 테스트.
- 유령 폴더(레지스트리에 없는 rename/브랜치 잔재)는 `Project.swift`가 없어 자동 제외된다 — 폴더 잔재가 매트릭스를 깨지 않는다.
- **머지 게이트**: `All Tests Passed` job이 전체 통과를 판정한다. develop 브랜치 보호에서 이 체크를 필수 통과(required status check)로 지정하면 빨간 PR은 머지가 막힌다(GitHub → Settings → Branches → develop → Require status checks → `All Tests Passed`).
- **아키텍처 검사**: `Architecture Rules` job이 자체 SwiftSyntax 검사기(`Tooling/ArchLint`)로 VM 계약(`ObservableObject` 계열 금지)을 **error**(막음), Service 분기를 **warning**(리포트만)으로 본다 — ubuntu + 공식 swift 컨테이너라 Xcode 불필요. 이 job(`Architecture Rules`)도 별도 필수 통과 체크로 걸 수 있다(develop이 초록인 걸 확인한 뒤). 규칙 추가·심각도 정책은 `Tooling/ArchLint/README.md`.

## 새 모듈 추가 절차

> ⚡ **`/new-module <layer> <ModuleName>`** 스킬이 아래를 자동화한다 (의존성 추론 포함). 수동 시 아래 순서대로.

1. **레지스트리 먼저**: `Plugins/DependencyPlugin/ProjectDescriptionHelpers/ModuleType.swift`의 해당 enum(`DomainModule`/`DataModule`/...)에 case 추가. (단일 진실 소스)
2. **Project.swift**: `Projects/<Layer>/<Module>/Project.swift`를 템플릿(`Project.create<Layer>Module(...)`)으로 작성, `internalDependencies` 선언.
3. **`tuist generate`** 로 프로젝트 재생성.
4. 코드 작성은 해당 레이어 가이드(`Projects/<Layer>/CLAUDE.md`) 준수.
5. **모듈 가이드 작성**: `docs/MODULE_GUIDE_TEMPLATE.md`를 복사해 `Projects/<Layer>/<Module>/CLAUDE.md` 생성 (함정·시나리오 중심).
6. 테스트 작성 (Domain은 필수). `Project.swift`에 `.tests`를 선언하면 CI가 자동 인식한다.

## 자주 쓰는 명령

```bash
mise install        # Tuist 설치
tuist install       # 의존성 설치
tuist generate      # 프로젝트 생성
```

## 문서 유지

- 코드와 문서가 다르면 **코드가 진실** — 가장 가까운 가이드(`CLAUDE.md`)를 즉시 고친다.
- 작업 중(코드 변경 포함) 함정을 발견하면 `/learn`을 기다리지 말고 **스스로** 해당 문서의 "주의사항" 절에 누적한다(`/learn`은 수동 트리거).
