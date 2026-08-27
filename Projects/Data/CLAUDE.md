# Data 레이어

Domain의 `Repository` 프로토콜을 **구현**하고, 외부 데이터(네트워크 등)를 연결하는 레이어.

- 모듈 식별자: `ModuleType.data(.xxx)` → 모듈명 `XxxData`
- 디렉토리: `Projects/Data/<Module>Data/`
- 비동기: **Swift Concurrency** (`async/await`)

## 의존 규칙

- ✅ 대응 `XxxDomain` (구현 대상 프로토콜·Entity), `BaseDomain`, `BaseData`, `Core`(Networking 등) 의존.
- ❌ Feature / App / 다른 Data 모듈 import 금지.
- 의존성 방향: **Data → Domain** (Domain은 Data를 모른다).

## 디렉토리 구조

```text
Projects/Data/<Module>Data/
├── Project.swift
├── Sources/
│   ├── DTO/           # Response / Query (서버 통신 모델)
│   │   ├── Response/
│   │   └── Query/
│   ├── Endpoint/      # XxxEndPoint (경로·메서드 정의)
│   ├── Service/       # XxxService(protocol) + DefaultXxxService (네트워크 호출)
│   ├── Mapper/        # XxxMapper (DTO → Domain Entity 변환)
│   ├── Repository/    # DefaultXxxRepository (Domain 프로토콜 구현)
│   ├── Factory/       # XxxDataFactory (조립 진입점)
│   └── Logger/        # XxxAction (로깅 액션 정의)
├── Testing/
└── Tests/
```

## 핵심 흐름: Service → Repository → Mapper

`DefaultXxxRepository`가 오케스트레이션한다:
1. `Service` 로 네트워크 호출 → `Response`(DTO) 수신
2. `Mapper` 로 DTO → Domain Entity 변환
3. 성공/실패를 `logger` 로 기록
4. 에러를 **Domain의 `RepositoryError`로 변환**해 throw

```swift
struct DefaultNovelRepository: NovelRepository {   // internal — 외부는 Factory가 반환하는 Domain 프로토콜만 본다
    private let service: NovelService
    private let appStorage: AppStorage
    private let logger: DataLogger?

    public func fetchNovel(id: NovelID, cachedKeywords: [Keyword]) async throws(RepositoryError) -> NovelInformation {
        let action = NovelAction.fetchNovel
        do {
            let basic = try await service.getNovelBasicInfo(novelID: id.value)
            let detail = try await service.getNovelDetailInfo(novelID: id.value)
            let result = try NovelMapper.novelInformation(id: id, from: basic, from: detail, cachedKeywords: cachedKeywords)
            logger?.logSuccess(action: action.text)
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.text, error: error)
            throw error.toRepositoryError()      // 네트워크 에러 → RepositoryError
        } catch let error as MappingError {
            logger?.logMappingError(action: action.text, error: error)
            throw .invalidData                    // 매핑 실패 → invalidData
        } catch {
            logger?.logUnknownError(action: action.text, error: error)
            throw .unknown
        }
    }
}
```

## 코드 규칙

- **Repository 구현체는 `DefaultXxxRepository` (struct)**. 외부에 노출되는 생성은 Factory로만.
- **에러 변환 규칙은 고정**:
  - `NetworkingError` → `error.toRepositoryError()`
  - `MappingError` → `.invalidData`
  - 그 외 → `.unknown`
  - 모든 catch 분기에서 logger 기록.
- **Service**: `protocol XxxService` + `DefaultXxxService(client:)`. 함수는 `async throws`(타입 미지정) 로 두고, RepositoryError 변환은 Repository가 담당.
- **DTO**: `Response`(서버→앱), `Query`(앱→서버) 분리. Entity와 혼용 금지.
- **Mapper**: `enum XxxMapper`의 static 함수. DTO ↔ Entity 변환만. 변환 실패 시 `MappingError`.
- **Factory**: `enum XxxDataFactory.makeXxxRepository(client:appStorage:logger:)` — 의존성을 조립해 Domain 프로토콜 타입으로 반환. **상위 레이어는 Factory만 알면 된다.**
- **접근제어(구조 강제)**: 모듈의 **top-level public은 `*DataFactory` 하나뿐**. Repository·Service·Mapper·DTO(`*Response`/`*Query`/`*Request`)·Logger(`*Action`)는 전부 `internal`로 둔다 — Factory가 같은 모듈 안에서 이들을 조립해 Domain 프로토콜/Entity로만 내보내므로 바깥에 열 필요가 없다. arch-lint `factory-exclusivity`(규칙⑫)가 CI에서 강제한다(→ `Tooling/ArchLint`). BaseData만 예외(다른 Data가 직접 import하는 공용 토대).
- 로컬 저장 접근은 `BaseData`의 `AppStorage` 사용 (`UserDefaultsStorage` 등).

## 주의사항 (작업 중 발견 시 누적)

- **Demo가 모듈 internal을 쓰면 `@testable import`**: Demo 앱은 별도 타깃이라 plain `import`로는 `public`만 본다. `factory-exclusivity`로 Repository·Logger·util 등이 internal이 된 뒤, 그걸 직접 시연하는 Demo(예: `NovelLoggerDemoView`가 `NovelAction`, `FeedDataDemoView`가 `ImageCompressor`)는 `@testable import XxxData`로 바꿔야 컴파일된다(Demo는 Debug라 testability 켜져 있어 동작). 자기 모듈 개발 하네스라 internal 접근은 정당 — 규칙에 예외를 뚫지 말고 이쪽을 쓴다.
- Tests는 `@testable import`가 기본이라 internal 타입에 그대로 접근된다(접근제어 조여도 테스트는 안 깨진다).
- **`Service` 프로토콜은 `: Sendable`이다(A4 #219).** Domain Repository 프로토콜이 Sendable이 되며 그 구현
  `Default*Repository`(internal struct)도 Sendable 검증을 받는데, `service`/`logger`/`appStorage` 의존이
  Sendable이어야 통과한다 — 그래서 Service 프로토콜·`DataLogger`·`AppStorage`가 전부 Sendable이다. 새 Service를
  만들면 `protocol XxxService: Sendable`로 둘 것(안 붙이면 그 Repository가 "non-Sendable stored property" 경고).
  구현 struct는 의존만 Sendable이면 **implicit Sendable**로 따라오니 impl엔 보통 손댈 게 없다. (actor/lock이
  아니라 Sendable conformance를 택한 배경 — Service·Storage·Logger가 스레드-안전 시스템 API 위 stateless
  추상화라서 — 은 #219 A4 커밋 이력 참조.)
