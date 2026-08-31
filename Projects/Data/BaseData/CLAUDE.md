<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# BaseData

Data 레이어의 **공통 인프라**. 거의 모든 Data 모듈이 의존한다. (= 여기 바꾸면 광범위 영향)

- 식별자: `ModuleType.data(.base)` / 의존: `BaseDomain`, `Networking`, `Keychain`, `Logger`

## 여기 들어있는 핵심 인프라

- **에러 변환의 본진**: `NetworkingError.toRepositoryError()` — 401→`authenticationRequired`, 403→`forbidden`, 404→`notFound`, 5xx→`serverUnavailable`, decoding→`invalidData`, unknown→`networkUnavailable`. (전 Data 모듈이 이걸 씀)
- **로컬 저장**: `AppStorage` 프로토콜 + `UserDefaultsStorage` 구현 + `StorageKey<V>`(타입 안전 키). 예: `appStorage.get(.userID)`.
- **온보딩 힌트 저장**(`Onboarding/`, #221): `DefaultOnboardingHintRepository`가 `BaseDomain.OnboardingHintRepository`를 구현 — 힌트별 키를 `onboardingHint.<rawValue>`로 네임스페이스해 `Bool`로 저장한다. ⚠️ **네트워크가 없어(순수 로컬) Factory 없이 App(DI)이 `DefaultOnboardingHintRepository(appStorage:)`로 직접 조립**한다(BaseData는 `factory-exclusivity` 예외라 public struct를 그대로 열어도 됨 — `UserDefaultsStorage`와 같은 결).
- **앱 리뷰 게이트 저장**(`AppReview/`, #221): `DefaultAppReviewRequestRepository`가 `BaseDomain.AppReviewRequestRepository`를 구현 — `appReview.engagementCount`(Int)·`appReview.engagementCountVersion`(String, 그 카운트가 쌓인 버전)·`appReview.lastRequestedVersion`(String) 세 키를 UserDefaults에 저장하고, `currentAppVersion`은 **init에서 `Bundle`(`CFBundleShortVersionString`)을 1회 읽어 고정**(`Bundle` 미보유 → Sendable-safe, `NetworkingConfig`의 plist 읽기와 같은 패턴). ⚠️ 이 repo는 **순수 저장소**라 "버전 바뀌면 카운트 리셋" 같은 정책 판단을 하지 않는다 — 값만 넣고 빼고, 리셋은 `AppReviewRequestUseCase`(Domain)가 `engagementCountVersion` 비교로 한다(테스트 가능성 때문). 온보딩과 마찬가지로 Factory 없이 App(DI)이 직접 조립. ⚠️ **`StorageKey<Int>`/`<String>` 키를 `static let`으로 두면 "StorageKey는 Sendable 아님" 컴파일 에러**라 `static var { StorageKey(...) }` computed로 매 접근 새로 만든다(온보딩이 인스턴스 키를 인라인 생성하는 것과 같은 회피).
- **로깅**: `DataLogger` (모듈명 + underlying `Logger`).
- **에러 타입**: `MappingError`, `CacheError`.
- **Keyword 전체 스택**: `DefaultKeywordRepository`/`Service`/`Mapper`/`Endpoint`/`Factory` + `KeywordCache`. → BaseDomain `KeywordRepository`의 실제 구현이 여기 있다. `KeywordRepository.fetchPopularKeywords`(실시간 인기 키워드)만 캐시를 안 거치고 **매번 서버 직접 호출** — 나머지(`fetchKeywords`/`searchKeywords`)는 캐시 경유이니 혼동 말 것.
- `NetworkingConfig` (Bundle plist에서 `BASE_URL`/`TEST_API_KEY`/`BUCKET_URL` 로드).
- **이미지 URL 해석**: `ImageURLResolver.resolve(from:)` — 서버가 full URL과 버킷 상대 경로를 섞어 주는 이미지 문자열을 URL로 통일(경로형은 `@{scale}x.png` 조립). **모든 매퍼의 이미지 필드는 예외 없이 이걸 경유**(직조립 금지) — 전 Data 모듈 매퍼에 전수 적용 완료. ⚠️ 단 **이미지가 아닌 외부 링크**(예: `NovelMapper`의 `platformUrl` — 플랫폼 사이트 주소)는 대상이 아니다(`URL(string:)` 유지, 실패 시 throw). 신규 매퍼도 이미지 필드는 반드시 경유할 것. ⚠️ **`KeywordMapper`는 예외** — DTO의 `categoryImage`는 존재하지만 의도적으로 미사용(카테고리 아이콘이 로컬 고정 에셋으로 바뀌어 서버 URL을 안 쓴다). 새 이미지 필드를 추가할 때 이 필드를 참고해 실수로 되살리지 말 것.

## 주의사항 (작업 중 발견 시 누적)

- **`ImageURLResolver.displayScale`은 UI 컨텍스트(루트 뷰 `@Environment(\.displayScale)`)에서 1회 주입**해야 한다 — 매퍼(백그라운드)에서 `UITraitCollection.current`를 읽으면 0이 나올 수 있어 값 주입 방식을 택했다. 미주입 시 기본 3(@3x — 전 기기에서 다운스케일이라 안전).
- **plist 키(`BASE_URL` 등)는 Tuist `ModuleInfoPlist`가 featureDemo/data 타깃에만 주입**한다 — 새 키를 추가하면 xcconfig뿐 아니라 `Tuist/ProjectDescriptionHelpers/ModuleInfoPlist.swift`에도 넣어야 Bundle에서 읽힌다(빼먹으면 조용히 빈 문자열).
- `KeywordCache`는 **파일 기반**(캐시 디렉토리의 `keywords.json` JSON). "로컬 DB"라 부르지만 실제론 파일 캐시. 실패는 `CacheError`.
- 키워드는 `syncKeywords()`로 서버→파일 동기화 후, 다른 도메인이 캐시에서 읽어 주입받는 구조.
- `StorageKey` 추가 시 타입(`V`)을 정확히 — `UserDefaultsStorage`는 `as? V` 캐스팅이라 타입 불일치는 조용히 nil.
  - 대부분 스칼라 키지만 `myLibraryFilter`(#221)는 **`StorageKey<Data>`**(JSON 스냅샷 직렬화) — 저장/조회 값도 항상 `Data`여야 한다(구조체를 직접 넣으면 `as? Data`에 걸려 조용히 nil). 복잡한 값은 이렇게 Data로 감싸 넣는다.
- **`KeywordEndpoint`의 토큰 정책은 케이스마다 다르다**: `searchKeywords`는 `.requireToken`, `getPopularKeywords`는 `.usesTokenIfAvailable`(#165 전후로 분리) — 인기 키워드는 비로그인도 봐야 하는 화면이라 토큰 없이도 호출되지만, 로그인 상태면 토큰을 붙여야 서버가 유저 문맥이 필요한 응답(개인화 등)을 줄 수 있다. 새 케이스 추가 시 한 값으로 뭉뚱그리지 말고 화면 성격별로 정책을 나눠 볼 것 — `NovelData`의 검색 API도 `.withoutToken`으로 뭉쳐놨다가 최근 검색어 미기록 버그가 났었다(#165).
