<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# CollectionData

`CollectionDomain` 계약의 서버 구현. 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.data(.collection)` / 진입점: `CollectionDataFactory`
- 서버 명세: `/api-spec collection`

## 핵심 시나리오

- **하나의 목록 응답 DTO에서 두 Entity가 나온다.** 마이페이지용 `CollectionPreview`와 리스트용 `CollectionCard`는
  같은 엔드포인트·같은 DTO를 쓰고 **Mapper만 갈린다**. 화면이 늘어도 Endpoint·Service를 복제하지 말 것.
  (왜 나눴는지는 `CollectionDomain/CLAUDE.md` 참고.)

## 주의사항 (작업 중 발견 시 누적)

- **`isPublic` → `isPrivate` 뒤집기는 여기(Mapper)에서만 한다.** 도메인·화면은 이미 "나만 보는" 방향으로 통일돼 있으니
  어디서도 다시 뒤집지 말 것.
- **에러는 상태 코드가 아니라 `code` 문자열로 분기한다.** `400` 하나에 `BAD_REQUEST`·`COLLECTION-002`(작품 1~100개)·
  `COLLECTION-003`(중복 작품)·`COLLECTION-004`(대표 작품이 목록에 없음)·`COLLECTION-007`(잘못된 커서)·
  `COLLECTION-008`(size 범위)이 공존한다. `401`도 `AUTH-000`/`AUTH-001`/`AUTH-003`으로 갈린다.
  화면에서만 의미가 다른 코드는 공용 `NetworkingError.toRepositoryError()`에 섞지 말고 이 모듈의 리포지토리 메서드에서 변환한다
  (`RepositoryError.privateProfile` 선례 — `BaseDomain/CLAUDE.md`).
- 커서는 **서버가 발급한 불투명 문자열**이다. 마지막 아이템 ID로 유도하거나 파싱하지 말고 받은 값을 그대로 되돌려 보낸다.
