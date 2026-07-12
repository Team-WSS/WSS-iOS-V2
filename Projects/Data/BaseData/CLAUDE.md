<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# BaseData

Data 레이어의 **공통 인프라**. 거의 모든 Data 모듈이 의존한다. (= 여기 바꾸면 광범위 영향)

- 식별자: `ModuleType.data(.base)` / 의존: `BaseDomain`, `Networking`, `Keychain`, `Logger`

## 여기 들어있는 핵심 인프라

- **에러 변환의 본진**: `NetworkingError.toRepositoryError()` — 401→`authenticationRequired`, 404→`notFound`, 5xx→`serverUnavailable`, decoding→`invalidData`, unknown→`networkUnavailable`. (전 Data 모듈이 이걸 씀)
- **로컬 저장**: `AppStorage` 프로토콜 + `UserDefaultsStorage` 구현 + `StorageKey<V>`(타입 안전 키). 예: `appStorage.get(.userID)`.
- **로깅**: `DataLogger` (모듈명 + underlying `Logger`).
- **에러 타입**: `MappingError`, `CacheError`.
- **Keyword 전체 스택**: `DefaultKeywordRepository`/`Service`/`Mapper`/`Endpoint`/`Factory` + `KeywordCache`. → BaseDomain `KeywordRepository`의 실제 구현이 여기 있다.
- `NetworkingConfig` (Bundle plist에서 `BASE_URL`/`TEST_API_KEY`/`BUCKET_URL` 로드).
- **버킷 이미지 URL 조립**: `BucketImageURL.imageURL(from:)` — 서버가 full URL과 버킷 상대 경로를 섞어 주는 이미지 문자열을 URL로 통일(경로형은 `@{scale}x.png` 조립).

## 주의사항 (작업 중 발견 시 누적)

- **`BucketImageURL.displayScale`은 UI 컨텍스트(루트 뷰 `@Environment(\.displayScale)`)에서 1회 주입**해야 한다 — 매퍼(백그라운드)에서 `UITraitCollection.current`를 읽으면 0이 나올 수 있어 값 주입 방식을 택했다. 미주입 시 기본 3(@3x — 전 기기에서 다운스케일이라 안전).
- **plist 키(`BASE_URL` 등)는 Tuist `ModuleInfoPlist`가 featureDemo/data 타깃에만 주입**한다 — 새 키를 추가하면 xcconfig뿐 아니라 `Tuist/ProjectDescriptionHelpers/ModuleInfoPlist.swift`에도 넣어야 Bundle에서 읽힌다(빼먹으면 조용히 빈 문자열).
- `KeywordCache`는 **파일 기반**(캐시 디렉토리의 `keywords.json` JSON). "로컬 DB"라 부르지만 실제론 파일 캐시. 실패는 `CacheError`.
- 키워드는 `syncKeywords()`로 서버→파일 동기화 후, 다른 도메인이 캐시에서 읽어 주입받는 구조.
- `StorageKey` 추가 시 타입(`V`)을 정확히 — `UserDefaultsStorage`는 `as? V` 캐스팅이라 타입 불일치는 조용히 nil.
