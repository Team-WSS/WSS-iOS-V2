# Core 레이어

의존성을 최소화한 **재사용 가능한 기반 기술**. 비즈니스 로직을 담지 않는다.

- 모듈 식별자: `ModuleType.core(.xxx)` → 모듈명은 **suffix 없음** (`Networking`, `Keychain`, `Logger`)
- 디렉토리: `Projects/Core/<Module>/`

## 모듈

| 모듈 | 책임 |
|---|---|
| `Networking` | 네트워크 클라이언트, 요청/응답 추상화, `NetworkingError` |
| `Keychain` | 보안 저장소, 키체인 접근 래퍼 |
| `Logger` | 로깅 추상화, 콘솔 로거 |

## 의존 규칙

- ✅ 다른 Core 모듈, 표준 라이브러리.
- ❌ Domain / Data / Feature / UI / App import 금지. **Core는 위를 모른다.**
- 도메인 개념(Entity 등)을 알면 안 된다. 순수 기술만.

## 코드 규칙

- 공개 API는 **프로토콜 우선** (예: `NetworkingRequestable`). 구현체는 주입 가능하게.
- 에러는 모듈 자체 에러 타입으로 정의 (예: `NetworkingError`). Domain의 `RepositoryError`로의 변환은 **Data 레이어 책임**이지 Core가 하지 않는다.
- `Demo` 타깃으로 단독 검증 가능하게 구성.

## 주의사항 (작업 중 발견 시 누적)

- (없음 — 발견 시 추가)
