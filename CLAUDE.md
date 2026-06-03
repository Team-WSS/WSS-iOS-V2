# CLAUDE.md — WSS-iOS-V2 작업 허브

> 이 파일은 **문서 진입점(허브)** 입니다. 실제 작업 규칙은 여기 다 담지 않고,
> 아래 "문서 맵"을 따라 필요한 문서만 골라 읽습니다. (토큰 효율 + 최신성 유지)

웹소소(WSS) 앱의 차세대 iOS 클라이언트. **Tuist 멀티 모듈 + Clean Architecture**.

---

## 🚨 작업 전 반드시 알 것 (Non-negotiables)

1. **의존성은 단방향**: `App → Feature → (UI / Domain) ← Data → Core`
   - Domain은 어떤 상위 레이어도, 어떤 구현체(Data)도 import 하지 않는다.
   - Data는 Domain의 프로토콜을 구현한다. 반대 방향 금지.
2. **비동기 모델은 레이어마다 다르다**
   - Domain / Data: **Swift Concurrency** (`async/await`, `throws(RepositoryError)`)
   - UI / Feature: **Combine** (상태 바인딩·이벤트)
3. **모듈 레지스트리의 단일 진실 소스**는 코드다 →
   [`Plugins/DependencyPlugin/ProjectDescriptionHelpers/ModuleType.swift`](Plugins/DependencyPlugin/ProjectDescriptionHelpers/ModuleType.swift)
   - 새 모듈은 여기 먼저 등록한다. 문서/디스크보다 이 파일이 우선.
4. **테스트는 현재 Domain 레이어에만** 작성한다. → [docs/layers/Domain.md](docs/layers/Domain.md)
5. **외부 의존성 없음 원칙** — 서드파티 라이브러리를 함부로 추가하지 않는다.

---

## 🗺 문서 맵

작업 대상이 정해지면, 해당 레이어 문서 → 해당 모듈 문서 순으로 읽는다.

### 전체 개요
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — 레이어 구성, 의존성 방향, 데이터 흐름

### 레이어별 코드 작성 규칙
| 레이어 | 문서 | 한 줄 |
|---|---|---|
| App | [docs/layers/App.md](docs/layers/App.md) | DI·전역 흐름 조립 |
| Feature | [docs/layers/Feature.md](docs/layers/Feature.md) | 화면·기능 구현 (계획 단계) |
| UI | [docs/layers/UI.md](docs/layers/UI.md) | 디자인 시스템·재사용 컴포넌트 헬퍼 |
| Domain | [docs/layers/Domain.md](docs/layers/Domain.md) | Entity·UseCase·Repository 프로토콜 |
| Data | [docs/layers/Data.md](docs/layers/Data.md) | DTO·Service·Mapper·Repository 구현 |
| Core | [docs/layers/Core.md](docs/layers/Core.md) | Networking·Keychain·Logger 기반 기술 |

### 모듈별 문서
- 위치: `docs/modules/<레이어>/<모듈명>.md`
- 새 모듈 문서는 [docs/modules/_TEMPLATE.md](docs/modules/_TEMPLATE.md) 를 복사해 작성한다.
- 작성된 문서 인덱스: [docs/modules/README.md](docs/modules/README.md)

---

## 🛠 자주 쓰는 명령

```bash
mise install        # Tuist 설치
tuist install       # 의존성 설치
tuist generate      # 프로젝트 생성
```

---

## 📌 문서 유지 규칙

- 코드와 문서가 다르면 **코드가 진실**. 발견 즉시 문서를 고친다.
- 레이어 규칙이 바뀌면 → 해당 `docs/layers/*.md` 갱신.
- 모듈 책임/구성이 바뀌면 → 해당 `docs/modules/.../*.md` 갱신.
- 작업 중 발견한 함정·주의사항은 해당 문서의 "주의사항" 절에 누적한다.
