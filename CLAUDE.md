# CLAUDE.md — WSS-iOS-V2 작업 허브

웹소소(WSS) 앱의 차세대 iOS 클라이언트. **Tuist 멀티 모듈 + Clean Architecture**.

이 파일은 항상 로드되는 **진입점**이다. 세부 규칙은 여기 담지 않고, 아래 "문서 자동 로딩" 방식으로
**작업 중인 위치에 해당하는 문서만** 컨텍스트에 들어오게 설계했다.

---

## 🚨 작업 전 반드시 알 것 (Non-negotiables)

1. **의존성은 단방향**: `App → Feature → (UI / Domain) ← Data → Core`
   - Domain은 상위 레이어도, 구현체(Data)도 import 하지 않는다. Data가 Domain 프로토콜을 구현한다.
2. **비동기 모델은 레이어마다 다르다**
   - Domain / Data: **Swift Concurrency** (`async/await`, `throws(RepositoryError)`)
   - UI / Feature: **Combine** (상태 바인딩·이벤트)
3. **모듈 레지스트리의 단일 진실 소스**는 코드다 →
   [`Plugins/DependencyPlugin/ProjectDescriptionHelpers/ModuleType.swift`](Plugins/DependencyPlugin/ProjectDescriptionHelpers/ModuleType.swift)
   문서/디스크보다 이 파일이 우선. 새 모듈은 여기 먼저 등록한다.
4. **테스트는 현재 Domain 레이어에만** 작성한다.
5. **외부 의존성 없음 원칙** — 서드파티 라이브러리를 함부로 추가하지 않는다.

---

## 📂 문서 자동 로딩 (컨텍스트 관리의 핵심)

문서는 **작업하는 디렉토리에 co-locate** 되어 있다. 어떤 파일을 열면 그 경로의
상위 `CLAUDE.md`들이 자동으로 함께 로드된다 → **필요한 문서만 정확히** 읽힌다.

```
CLAUDE.md                              ← 항상 (이 파일)
Projects/<Layer>/CLAUDE.md             ← 그 레이어 작업 시 자동 (레이어 코드 규칙)
Projects/<Layer>/<Module>/CLAUDE.md    ← 그 모듈 작업 시 자동 (모듈 시나리오·함정)
```

예: `Projects/Domain/NovelDomain/Sources/...`를 만지면 →
이 허브 + `Projects/Domain/CLAUDE.md` + `Projects/Domain/NovelDomain/CLAUDE.md` 가 함께 로드된다.

**→ 다른 레이어/모듈 문서를 일부러 찾아 읽지 말 것.** 작업 위치가 필요한 문서를 알아서 가져온다.
전체 구조를 알아야 할 때만 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)를 읽는다.

### 레이어 가이드 위치
| 레이어 | 가이드 |
|---|---|
| App | [Projects/App/CLAUDE.md](Projects/App/CLAUDE.md) |
| UI | [Projects/UI/CLAUDE.md](Projects/UI/CLAUDE.md) |
| Domain | [Projects/Domain/CLAUDE.md](Projects/Domain/CLAUDE.md) |
| Data | [Projects/Data/CLAUDE.md](Projects/Data/CLAUDE.md) |
| Core | [Projects/Core/CLAUDE.md](Projects/Core/CLAUDE.md) |
| Feature | [docs/layers/Feature.md](docs/layers/Feature.md) (폴더 미생성 → 생성 시 `Projects/Feature/CLAUDE.md`로 이동) |

---

## ✍️ 문서 작성·유지 규칙

- **새 모듈 가이드**: [docs/MODULE_GUIDE_TEMPLATE.md](docs/MODULE_GUIDE_TEMPLATE.md)를 복사해
  `Projects/<레이어>/<모듈>/CLAUDE.md`로 만든다.
- **무엇을 적나**: 코드/디렉토리만 봐도 아는 것(구성요소 나열)은 적지 않는다.
  **코드만 봐선 모르는 것**(핵심 시나리오, 숨은 의존, 함정, 이유)만 적는다. 함정 없으면 짧아도 된다.
- 코드와 문서가 다르면 **코드가 진실** — 발견 즉시 가장 가까운 `CLAUDE.md`를 고친다.
- 작업 중 발견한 함정은 해당 문서의 "주의사항" 절에 누적한다.

---

## 🛠 자주 쓰는 명령

```bash
mise install        # Tuist 설치
tuist install       # 의존성 설치
tuist generate      # 프로젝트 생성
```
