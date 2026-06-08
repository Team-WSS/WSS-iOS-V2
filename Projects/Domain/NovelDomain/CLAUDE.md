<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# NovelDomain

작품(Novel) 도메인 — 조회·검색·서재·관심 등록의 비즈니스 로직과 계약.
구성요소 목록은 `Sources/{Entity,UseCase,Repository}/`를 직접 보면 된다. 여기엔 **코드만 봐선 모르는 것**만 적는다.

- 식별자: `ModuleType.domain(.novel)` / 의존: `BaseDomain` only

## 핵심 시나리오

- **작품 상세(`LoadNovelUseCase`)**: 키워드 매핑을 위해 `KeywordRepository`에서 캐시 키워드를 모아
  `NovelRepository.fetchNovel(id:cachedKeywords:)`에 주입한다. → 이 UseCase는 NovelRepository + KeywordRepository **둘 다** 의존.
- **관심 토글**: 도메인 정책은 Entity `Novel`의 `mutating` 메서드(`markAsInterested`/`toggleInterest`)가 담당. 서버 반영(`addNovelInterest`/`removeNovelInterest`)은 Repository 별도 호출.
- **검색/서재**: 결과는 `(Paginated<T>, Int)` = (페이지 목록, 총 개수) 튜플.

## 주의사항 (작업 중 발견 시 누적)

- `fetchMyLibraryNovels`/통계는 **로그인 사용자 기준** (구현체가 저장된 userID 사용). 타 사용자 조회는 `fetchUserLibraryNovels(id:_:)` 별도.
- 키워드 캐시가 호출 측 주입 구조라, UseCase 시그니처에 키워드 의존이 숨어있음.
