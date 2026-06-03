# NovelDomain

- **레이어**: Domain → 규칙은 [../../layers/Domain.md](../../layers/Domain.md)
- **식별자**: `ModuleType.domain(.novel)`
- **위치**: `Projects/Domain/NovelDomain/`
- **한 줄 책임**: 작품(Novel) 도메인 — 조회·검색·서재·관심 등록의 비즈니스 로직과 계약.

## 의존성

- internal: `BaseDomain`
- external: 없음

## 주요 구성요소

| 종류 | 이름 | 역할 |
|---|---|---|
| Repository | `NovelRepository` | 작품 조회·검색·서재·관심·통계 계약 (프로토콜) |
| UseCase | `LoadNovelUseCase` | 작품 상세 조회 (+ 키워드 캐시 결합) |
| UseCase | `SearchNovelUseCase` | 텍스트/필터 검색 |
| UseCase | `LoadUserLibraryUseCase` / `LoadMyLibraryUseCase` | 타 사용자/내 서재 목록 |
| UseCase | `NovelInterestUseCase` | 관심 등록·해제 |
| UseCase | `LoadRegisteredNovelStatsUseCase` | 등록 작품 통계 |
| Entity | `Novel` | 작품 헤더 모델 (+ 관심 토글 정책 `markAsInterested` 등) |
| Entity | `NovelInformation`, `RegisteredNovelStats`, `UserNovelReview` | 상세·통계·리뷰 |
| Entity | `LibraryNovel(s)`, `LibraryFilter`, `MyLibraryFilter`, `SearchFilter` | 서재·검색 모델 |
| Entity(Assistant) | `NovelPlatform`, `NovelPublicationStatus`, `NovelRatingThreshold` | 보조 값 타입 |

## 핵심 동작 / 시나리오

- **작품 상세 조회**: `LoadNovelUseCase.execute(id:)` → `KeywordRepository`에서 캐시된 키워드를 모아
  `NovelRepository.fetchNovel(id:cachedKeywords:)`로 `NovelInformation` 반환. (헤더+상세를 한 번에)
- **검색**: `searchNovelByText(_:)` / `searchNovelByFilter(_:)` → `(Paginated<Novel>, Int)` (목록 + 총 개수).
- **관심 토글**: 도메인 정책은 `Novel.toggleInterest()`(Entity), 서버 반영은 `addNovelInterest/removeNovelInterest`.
- **서재**: 내 서재(`fetchMyLibraryNovels`, 내부 userID 기반) / 타 사용자 서재(`fetchUserLibraryNovels(id:_:)`).

## 주의사항 (작업 중 발견 시 누적)

- `fetchNovel`은 키워드 매핑을 위해 **호출 측이 캐시 키워드를 주입**하는 구조 — UseCase가 `KeywordRepository`에 추가 의존.
- 서재/통계 일부는 로그인 사용자 기준 (구현체에서 저장된 userID 사용).
