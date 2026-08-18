<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# CollectionDomain

사용자가 만든 작품 모음(컬렉션)의 조회·생성·수정·삭제·좋아요. 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.domain(.collection)` / 의존: `BaseDomain`만
- 서버 명세: `/api-spec collection` (엔드포인트 8개가 REST Docs로 문서화돼 있다)

## 핵심 시나리오

- **한 응답을 두 Entity로 나눠 매핑한다.** 목록 API(`/users/{userId}/collections`)는 `representativeNovel`(대표 작품 하나)과
  `recentNovels`(표시 순서 앞 5개)를 **항상 둘 다** 내려주고, 서버가 "무엇을 쓸지는 화면이 정하라"고 명시적으로 위임한다.
  그 선택을 화면마다 반복하지 않도록 매핑 시점에 고정했다 → 마이페이지 섹션은 `CollectionPreview`(대표 작품만),
  컬렉션 리스트·좋아요 목록은 `CollectionCard`(미리보기 5개).
- **마이페이지 컬렉션 섹션에는 전용 API가 없다.** 같은 목록 API를 `size=3`으로 호출해 구성한다(서버 명세가 지시).
  size는 상수로 박지 말고 화면이 정해 내려보낸다 — 서재에서 같은 이유로 이미 관통시킨 선례가 있다(#184).
- **목록 반환은 `(CursorPaginated<T>, Int)` 튜플.** 두 번째 값은 응답 최상위의 `collectionsCount`(조회자가 볼 수 있는
  **전체** 개수, 이번 페이지 개수가 아니다) — 마이페이지 "컬렉션 N개" 표시가 이 값이다. 서재와 같은 형태.

## 주의사항 (작업 중 발견 시 누적)

- **`isPrivate`은 서버 `isPublic`의 반대값이다.** 기획·화면 용어가 일관되게 "나만 보는 컬렉션"이라 도메인을 그 방향으로 맞췄다.
  뒤집기는 Mapper 한 곳에서만 일어나야 한다 — Entity나 화면에서 다시 뒤집지 말 것.
  (`FeedDetail`·`TotalFeed`는 `isPublic`으로 남아 있어 도메인 간 표기가 갈린다. 컬렉션 안에서의 일관성을 택한 결과다.)
- **`representativeNovel`과 `recentNovels`는 배타적이지 않다.** 대표 작품이 표시 순서 앞쪽이면 양쪽에 **함께** 내려온다.
  "대표는 미리보기에 없다"고 가정한 코드를 짜지 말 것. 걸러낼지는 화면이 정한다(서버가 걸러주지 않는다).
- **`novelCount`는 컬렉션의 전체 작품 수**다. `recentNovels.count`(최대 5)가 아니다 — 서버 명세가 못박아 둘 만큼 흔한 혼동이다.
- 좋아요한 컬렉션 목록 응답에는 카드마다 `likeCount`가 딸려 오지만 그 화면이 좋아요 수를 쓰지 않아 **의도적으로 매핑하지 않는다**.
  필요해지면 `CollectionCard`에 옵셔널로 얹지 말고 그 화면 전용 타입을 두는 편이 낫다(두 목록이 같은 카드를 공유하는 구조가 깨진다).
- 작품을 다루지만 `BaseDomain.Novel`을 쓰지 않는다 — 컬렉션 화면은 평점·관심수·장르를 쓰지 않고 서버도 주지 않아서,
  `Novel`을 쓰면 없는 값을 0으로 채우게 된다. 경량 `CollectionNovel`을 쓴다(`LibraryNovel`·`SosoPick`과 같은 패턴).
- 컬렉션 소유자는 `BaseDomain.Author`를, 상세 정렬은 `BaseDomain.SortType`(`recent`/`old`)을 그대로 쓴다 —
  서버의 `owner`·`sortCriteria`와 필드가 정확히 맞아 새 타입을 만들지 않았다.
