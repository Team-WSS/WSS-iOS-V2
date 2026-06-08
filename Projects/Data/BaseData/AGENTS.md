<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/AGENTS.md(레이어 규칙)와 함께 자동 로드됨. -->
# BaseData

Data 레이어의 **공통 인프라**. 거의 모든 Data 모듈이 의존한다. (= 여기 바꾸면 광범위 영향)

- 식별자: `ModuleType.data(.base)` / 의존: `BaseDomain`, `Networking`, `Keychain`, `Logger`

## 여기 들어있는 핵심 인프라

- **에러 변환의 본진**: `NetworkingError.toRepositoryError()` — 401→`authenticationRequired`, 404→`notFound`, 5xx→`serverUnavailable`, decoding→`invalidData`, unknown→`networkUnavailable`. (전 Data 모듈이 이걸 씀)
- **로컬 저장**: `AppStorage` 프로토콜 + `UserDefaultsStorage` 구현 + `StorageKey<V>`(타입 안전 키). 예: `appStorage.get(.userID)`.
- **로깅**: `DataLogger` (모듈명 + underlying `Logger`).
- **에러 타입**: `MappingError`, `CacheError`.
- **Keyword 전체 스택**: `DefaultKeywordRepository`/`Service`/`Mapper`/`Endpoint`/`Factory` + `KeywordCache`. → BaseDomain `KeywordRepository`의 실제 구현이 여기 있다.
- `NetworkingConfig` (Bundle plist에서 `BASE_URL`/`TEST_API_KEY` 로드).

## 주의사항 (작업 중 발견 시 누적)

- `KeywordCache`는 **파일 기반**(캐시 디렉토리의 `keywords.json` JSON). "로컬 DB"라 부르지만 실제론 파일 캐시. 실패는 `CacheError`.
- 키워드는 `syncKeywords()`로 서버→파일 동기화 후, 다른 도메인이 캐시에서 읽어 주입받는 구조.
- `StorageKey` 추가 시 타입(`V`)을 정확히 — `UserDefaultsStorage`는 `as? V` 캐스팅이라 타입 불일치는 조용히 nil.
