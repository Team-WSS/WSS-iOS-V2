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
- `ProfileAvatar.avatarProfileLine`(→ `ProfileCharacter.line`)은 `"%s"` 자리표시자를 포함한 포맷 문자열이다(서버가 그대로 내려줌) — 닉네임 치환은 매퍼가 아니라 소비하는 Feature 쪽 책임이니 `profileAvatars(from:)`에서 임의로 치환하지 말 것.
- `ProfileAvatarResponse.avatarProfiles` 배열은 **열 우선(2행 그리드 기준 왼 위→왼 아래→오른쪽 위→오른쪽 아래) 순서**로 내려온다 — `profileAvatars(from:)`는 `.map`으로 순서를 그대로 보존한다. 행 우선으로 다시 정렬하지 말 것(그리드 표시용 재배치는 소비 측 책임).
- `PATCH /profile`(`UpdateProfileRequest`)은 **바뀐 필드만 값을 보내고 나머지는 `nil`**로 보내야 한다(서버가 `nil`을 "변경 없음"으로 해석). `updateProfile(_:)`이 `ProfileDraft`의 `isNicknameChanged`/`isCharacterChanged`/`isIntroductionChanged`로 각 필드를 개별 게이팅하는 이유. **`genrePreferences`만 예외** — 서버가 `null`을 허용하지 않아, 장르가 안 바뀌었어도 매 호출마다 현재 전체 목록을 그대로 보내야 한다(DTO 타입도 `[String]`으로 non-optional). 저장 호출 자체를 스킵하는 가드도 소개/장르뿐 아니라 닉네임·캐릭터 변경까지 포함해야 한다 — 하나라도 빠지면 그 필드 변경이 조용히 유실된다.
- **타 유저 비공개 프로필(`USER-015`) 감지는 공용 `NetworkingError.toRepositoryError()`(BaseData)가 아니라 `fetchGenrePreferences`/`fetchNovelPreferences`의 `catch let error as NetworkingError` 안에서 개별로** `body?.code == "USER-015"` → `RepositoryError.privateProfile`을 throw한다(HTTP 상태 코드는 안 봄) — 이 코드는 "타 유저 조회" 두 메서드에만 의미가 있어 공용 변환기를 건드리지 않기로 했다(UserPageFeature #172).
- ⚠️ **로컬 캐시(닉네임/캐릭터ID) 쓰기는 반드시 `service.putProfile(request)` 성공 뒤에 한다.** `updateProfile(_:)`이 한때 이 두 `localStorage.set`을 PATCH 요청 **이전**에(성공 여부와 무관하게) 실행했었다 — 요청이 실패해도 로컬 캐시는 이미 새 값으로 덮어써진 채 롤백되지 않아, `MyPageEditView`(로컬 `characterID` 기준 아바타)와 `MypageView`(서버 `/profile` 응답 기준 아바타)가 서로 다른 캐릭터를 보여주는 버그로 이어졌다(#185). `saveAccountInfo(_:)`처럼 "서버 확정 후에만 로컬 갱신" 순서를 지킬 것 — 로컬+서버 혼합 필드를 새로 추가할 때도 같은 순서를 따를 것.
