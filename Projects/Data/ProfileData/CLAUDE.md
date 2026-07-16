<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# ProfileData

`ProfileDomain.ProfileRepository` 구현 — 프로필 등록/조회/수정, 닉네임·선호·계정·공개범위. (DTO가 가장 많음)

- 식별자: `ModuleType.data(.profile)` / 의존: `ProfileDomain`, `BaseDomain`, `BaseData`, `Networking`, `Logger`
- 진입점: `ProfileDataFactory.makeProfileRepository(client:localStorage:logger:)`

## 핵심 시나리오

- **로컬+서버 혼합 구현**: Factory가 `localStorage: AppStorage`를 받는다. 일부 필드(userID/닉네임/성별/프로필캐릭터ID)는 userDefaults에서 읽고/쓰고, 나머지는 서버에서. (도메인 `ProfileRepository` 주석이 어느 게 로컬인지 명시)
- `ProfileTarget`(.me/.user)에 따라 userID 출처 분기.

## 주의사항 (작업 중 발견 시 누적)

- 로컬/서버 책임이 메서드마다 다름 → 수정 전 `DefaultProfileRepository`에서 해당 메서드가 localStorage를 쓰는지 확인.
- `GenrePreferences`(DTO) DTO의 `genreImage`는 더 이상 매핑에 쓰이지 않는 죽은 필드다 — `GenrePreference`(Domain)가 서버 이미지 URL 대신 `NovelGenre`의 로컬 에셋(`WSSComponent`)을 쓰도록 바뀌었기 때문. 디코딩만 하고 의도적으로 버림.
- **성별 로컬 저장 포맷("MALE"/"FEMALE")이 계정정보 API 포맷("M"/"F")과 다르다.** `syncUserBasicInfo()`가 `UserInfoResponse.gender` 원문을 그대로 userDefaults `.gender`에 저장하는 반면, 계정정보 API(`AccountInfoResponse`/`AccountInfoRequest`)는 "M"/"F"를 쓴다. `ProfileMapper.gender`/`genderRawValue`(M/F, API용)와 `localGender`/`localGenderRawValue`(MALE/FEMALE, userDefaults용)를 혼용하지 말 것. `saveAccountInfo(_:)`는 PUT 성공 후 로컬 포맷으로 변환해 userDefaults도 갱신한다.
