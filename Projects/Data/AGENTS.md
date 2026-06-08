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
public struct DefaultNovelRepository: NovelRepository {
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
- 로컬 저장 접근은 `BaseData`의 `AppStorage` 사용 (`UserDefaultsStorage` 등).

## 주의사항 (작업 중 발견 시 누적)

- 테스트는 현재 Data 레이어에 적용하지 않음 (Domain 우선). `Testing/`, `Tests/` 폴더가 있어도 비어있을 수 있음.
