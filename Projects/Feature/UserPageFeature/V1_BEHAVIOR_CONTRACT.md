# UserPageFeature — V1 동작 계약 (V1 Behavior Contract)

> **이 문서는 무엇인가** — 운영 중인 **V1**(`Team-WSS/WSS-iOS`, UIKit·RxSwift)의 마이페이지/타유저 프로필
> 화면들이 **실제로 어떻게 동작했는지**를 코드에서 추출한 목록이다. V1은 "실제 운영으로 검증된 동작 기준"이고,
> V2가 이 각각을 **유지했는지 / 일부러 바꿨는지 / 삭제했는지**를 나중에 사람이 한 번에 점검하기 위한 재료다.
> (#205 축 C의 C1 산출물. 이슈 #222.)
>
> **이 문서가 아닌 것** — V2 화면의 정본 계약이 아니다. V2의 "코드만 봐선 모르는 것"은 여전히
> [`CLAUDE.md`](CLAUDE.md)가 정본이다. 이 문서는 **V1 기준으로 훑은 것**이고, 분류는 **초안**이다.

## 읽는 법 · 분류 범례

각 동작에 **초안 분류 배지**가 달려 있다. 나중에 사람이 와서 배지를 확정하고(바꾸면 바꾸고) 한 줄 근거를 남긴다.

| 배지 | 뜻 | 사용자가 할 일 |
|---|---|---|
| ✅ **Keep** | V2가 **같은 관찰 동작**을 유지(구현·구조는 달라도 됨) | 맞으면 그대로 |
| 🔧 **Improve** | V2가 V1의 버그·한계를 **의도적으로 고침**(근거 있음) | 근거 확인 |
| 🗑 **Delete** | V2가 **의도적으로 제거**한 동작 | 정말 버릴지 확인 |
| ❓ **Unknown** | 회귀일 수도, 의도일 수도 — **판정 대기** | **판정 필요** — 2026-08-28 기준 **0건**(전부 판정 완료) |

- 회귀 후보였던 항목(판정 완료)과 눈에 띄는 🔧/🗑는 [0 점검 대기 요약](#0-점검-대기-요약)에 모아뒀다.
- 근거는 **`repo@commit + 내부 경로`**로 남긴다(머신마다 다른 절대경로 금지). V1 스냅샷 기준 커밋: **`Team-WSS/WSS-iOS@eefcb9b2`**.
- V1 경로 접두사 생략형: `…/UserPage/` = `WSSiOS/Source/Presentation/UserPage/`.

## 화면 매핑 (V1 → V2)

### 내 마이페이지 (MyPage)

| V2 (이 모듈) | V1 원본 | 성격 차이 |
|---|---|---|
| `Sources/MyPage/MypageView.swift` (+`MypageViewModel`) | `…/MyPage/MyPageViewController/MyPageViewController.swift` (+`…/MyPageViewModel/MyPageViewModel.swift`) | 탭 콘텐츠(프로필 요약·서재 통계·컬렉션·장르·작품취향) |
| `Sources/MyPage/MyPageEdit/MyPageEditView.swift` (+VM) | `…/MyPage/MyPageViewController/MyPageEditProfileViewController.swift` (+`…/MyPageViewModel/MyPageEditProfileViewModel.swift`) | 프로필 편집(닉네임·소개·캐릭터·선호장르) |
| `Sources/MyPage/MyPageEdit/MypageCharacterEditSheet.swift` (+VM) | `…/MyPage/MyPageViewController/MyPageEditAvatarViewController.swift` (+`…/MyPageViewModel/MyPageEditAvatarViewModel.swift`) | **V1은 별도 모달 VC, V2는 `.sheet(item:)`** (3) |

### 타유저 프로필 (UserPage)

| V2 (이 모듈) | V1 원본 | 성격 차이 |
|---|---|---|
| `Sources/UserPage/UserPageView.swift` (+`UserPageViewModel`) | `…/UserPage/UserPageViewController/UserPageViewController.swift` (+`…/UserPageViewModel/UserPageViewModel.swift`) | push 프로필. **V1은 피드 셀 상호작용 no-op, V2는 좋아요·신고 지원** (4.5) |
| `Sources/UserPage/UserFeedList/UserFeedListView.swift` (+VM) | `…/UserPage/UserPageViewController/UserPageFeedDetailViewController.swift` (+`…/UserPageViewModel/UserPageFeedDetailViewModel.swift`) | "전체보기"로 진입하는 무한스크롤 전체 피드 목록 |

### 공용 컴포넌트

`Sources/Component/`의 `GenreSection`·`KeywordSection`·`LibrarySection`은 MyPage·UserPage가 함께 쓴다
(V1은 두 화면이 각각 `MyPagePreferencesView`/`UserPageOverviewView` 사본을 들고 있었다).

---

## 0. 점검 대기 요약

**판정 상태(2026-08-28 갱신)** — 모든 항목에 배지가 달려 있고 본문 각 절의 확정 배지와 일치한다. **판정 대기 0건.** 배지: ✅유지 · 🔧개선/고치기/미배선(되살리기·수정은 `docs/TODO.md` 9절에 구현 대기, 미배선은 App 배선 시 해소) · 🔨회귀 수정 · 🗑삭제 · ⏳⏸보류(`docs/PENDING_DECISIONS.md`) · 🆕V2 신규.

1. 🔧 **미배선(App 배선 — 서재 이동)** — **서재 통계 → 서재 이동이 V2에 미배선**. V1은 마이페이지의 읽기상태 버튼(관심/보는중/봤어요/하차) **각각**을 탭하면 그 읽기상태로 필터된 서재로 이동하고(마이페이지=탭 전환 notification, 타유저=UserLibrary push, **pageIndex 동반**), 타유저 프로필은 "서재" 타이틀 탭으로도 이동한다. **V2는 `LibrarySection` 전체가 버튼 하나이고 그 action이 `//TODO: - 서재 뷰로 이동`(마이·타유저 둘 다)** → 아직 안 눌린다. 읽기상태별 진입(pageIndex) 세분도 사라졌다. → [1.3](#13-서재-통계--서재-이동), [4.8](#48-서재-통계--네비게이션)
2. **타유저 프로필·전체 피드 목록의 재진입 재조회 없음**. V1은 `viewWillAppear`마다 프로필·피드를 다시 받는다(전체 피드 목록은 목록을 **비우고** 처음부터 다시 로드). V2 `UserPageViewModel.load()`·`UserFeedListViewModel.load()`는 **`!hasLoaded`/`!hasLoadedFirstPage` 1회 가드**라 push에서 돌아와도 재조회하지 않는다. → [4.1](#41-진입생명주기), [5.2](#52-진입생명주기)
   - **🔧 확정(2026-08-28, 사용자): 재진입 재조회 복원.** push 복귀 시 재조회하기로 결정(횡단 — 알림·작품상세와 함께, `docs/TODO.md` 9). 전체 피드 목록의 "비우고 처음부터"는 스크롤·상태 보존 위해 재검토.
3. **차단 성공 알림(토스트) 누락 가능성**. V1은 차단 성공 시 `NotificationCenter.blockUser`(닉네임)를 post해 **직전 화면에서 "차단했어요" 류 안내**를 띄우게 한다. V2는 차단 성공 시 화면만 `dismiss`하고 그런 신호가 없다. → [4.6](#46-차단)
   - **🔧 확정(2026-08-28, 사용자): 되살린다(소소).** 차단 성공 시 직전 화면에 "차단했어요" 안내 복원(V1 parity). 저우선 — `docs/TODO.md` 9 소소 묶음.
4. **타유저 "알 수 없는 유저"(USER-018) 처리 없음**. V1 UserPage는 `USER-018` 서버 에러를 잡아 **빈 프로필로 폴백**한다. V2는 `privateProfile`(USER-015)만 특별 처리하고 USER-018은 일반 로드 실패(`hasLoadError`)로 떨어진다. → [4.7](#47-비공개알-수-없는-프로필)
   - **🔧 확정(2026-08-28, 사용자): 전용 처리 복원.** USER-018 = "없는 유저" 폴백(탈퇴·삭제된 유저 진입 시). 지금은 "네트워크 오류"로 잘못 떨어져 재시도만 반복되는 잠재 회귀. `docs/TODO.md` 9.
5. **비공개 프로필에서 서재 통계 노출 여부**. V1은 비공개여도 서재 통계 조회(`getUserNovelStatus`)가 private 게이팅 밖이라 값이 바인딩된다. V2는 `isProfilePrivate`가 서면 **통계 탭 콘텐츠 전체(서재 섹션 포함)를** "비공개" 안내로 덮는다. → [4.7](#47-비공개알-수-없는-프로필)
   - **⏸ 보류(2026-08-28, 사용자): 기획 상의 필요.** "비공개인데 숫자는 노출"(V1) vs "통째로 가림"(V2) 판단은 제품·기획 몫. `docs/TODO.md` 10(판정 보류)에 모음.
6. 🔧 **미배선(App 배선)** — **마이페이지 설정 진입 미배선**. V1 마이페이지 우상단 설정 버튼 → 설정 화면 push. V2는 `//TODO: - 설정 뷰로 이동`. (설정은 `SettingFeature` 소관이라 App 배선 대기일 수 있음.) → [1.7](#17-설정-진입)
7. 🔧 **미배선(App 배선)** — **피드 연결작품 상세 이동 미배선**. V1은 피드 셀의 연결 작품 탭 → 작품 상세 push. V2 피드 셀의 `linkNovelTapped`는 `//TODO: - 연결 작품 상세로 이동`. → [4.5](#45-피드-셀-상호작용)
8. **마이페이지 스크롤 반응 네비 타이틀 없음**. V1 마이페이지는 스크롤 > 0이면 네비바에 "마이페이지" 타이틀이 나타난다. V2 마이페이지 툴바엔 설정 버튼만 있고 타이틀 표기가 없다(타유저 프로필의 스크롤 반응 닉네임 페이드는 4.10에서 유지). → [1.8](#18-스크롤-반응-네비-타이틀)
   - **🔧 확정(2026-08-28, 사용자): 되살린다(소소).** 마이페이지 스크롤>0 시 네비바 "마이페이지" 타이틀 복원(V1 parity). 저우선 — `docs/TODO.md` 9 소소 묶음.

**🔧 눈에 띄는 개선 (근거 확인)**

9. 🔧 **Improve** — **타유저 프로필/전체 피드 목록의 피드 셀에 좋아요·신고 추가**. V1은 이 두 화면의 피드 셀에서 드롭다운·좋아요를 **전부 no-op**(`return`)으로 뒀다(연결작품 탭만 동작). V2는 좋아요 토글(낙관 반영·롤백)과 스포일러/부적절 신고(2단 알럿)를 붙였다. → [4.5](#45-피드-셀-상호작용), [5.3](#53-피드-셀-상호작용)
10. 🔧 **Improve** — **차단에 확인 알럿 추가**. V1은 드롭다운 "차단하기" 탭 즉시 차단 API를 호출했다(확인 단계 없음). V2는 `WSSAlertType.blockUser` 확인 알럿을 거친다. → [4.6](#46-차단)
11. 🔧 **Improve** — **전체 피드 목록 로드 실패 표현**. V1 전체 피드 목록은 로드 실패 시 `print`만 하고 아무 표시가 없었다. V2는 첫 페이지 실패를 `NetworkErrorView`로 덮는다. → [5.1](#51-로드페이지네이션)

**🗑 눈에 띄는 삭제 (의도 확인)**

12. 🗑 **Delete** — 캐릭터 선택 **"변경 없음이면 아무것도 안 하고 닫기"** 최적화 제거(V1은 최종 선택이 대표 아바타와 같으면 notification을 post하지 않았다). → [3.3](#33-확인취소변경없음)

(나머지는 대부분 ✅ Keep 또는 문서화된 🔧 Improve.)

---

## 1. 내 마이페이지 (MyPage)

원본: `…/MyPage/MyPageViewController/MyPageViewController.swift`, `…/MyPage/MyPageViewModel/MyPageViewModel.swift`

### 1.1 진입·생명주기

- ✅ **Keep** — `viewWillAppear`마다 프로필·서재·취향을 다시 로드한다(1회 가드 없음). 프로필 편집에서 저장하고 돌아오면 바뀐 값을 비추기 위함.
  - V2: `onAppear`마다 `.load`, `loadTask == nil` 가드만 두고 최초 1회 가드는 두지 않음. "탭 복귀마다 다시 로드"를 명문화.
  - 근거: V1 `MyPageViewController.swift:50-53`, `MyPageViewModel.swift:91-112` · V2 `MypageViewModel.swift:118-125`, `MypageView.swift:90-92`, `CLAUDE.md`(탭 복귀마다 다시 로드)
- ✅ **Keep** — 재로드가 이미 그린 화면을 매번 깜빡이지 않게 한다. V1은 부분 relay가 개별 갱신돼 통째로 재구성되지 않았다.
  - V2: `isInitialLoading`(=`isLoading && !hasLoadedContent`)으로 **아직 보여줄 게 없을 때만** 로딩 뷰를 씌운다(홈과 동일 해법).
  - 근거: V1(relay별 부분 바인딩 구조) · V2 `MypageViewModel.swift:51-56`,`150-157`, `CLAUDE.md`(isInitialLoading)

### 1.2 콘텐츠 로드 (병렬 4종)

- ✅ **Keep** — 프로필·서재 통계·장르 취향·작품 취향을 한 진입에서 모두 받는다.
  - V2: `async let` 4종 병렬(`loadProfileUseCase(.me)`·`loadGenrePreferencesUseCase(.me)`·`loadNovelPreferencesUseCase(.me)`·`loadRegisteredNovelStatsUseCase()`). 하나 실패 시 화면 전체를 에러로.
  - **수단 차이**: V1은 헤더(프로필)를 **먼저** 받고 그 뒤 `Observable.concat`으로 서재→취향을 **순차**로 잇는다(장르·작품취향만 `zip` 병렬). V2는 4종을 전부 병렬로.
  - 근거: V1 `MyPageViewModel.swift:91-112`,`196-224` · V2 `MypageViewModel.swift:134-161`
- ✅ **Keep** — 취향 비어있음 처리. V1은 `(장르 비었나, 작품 비었나)` 2요소로 장르 섹션 숨김/작품 empty를 각각 판정.
  - V2: `hasNoGenrePreferenceData`(장르 전부 0개면 장르 섹션 숨김) + `hasNoPreferenceData`(작품 취향 없음 **또는** 장르 없음 → 작품 취향 콘텐츠를 "데이터 없음"으로). **미세 차이**: V2는 장르가 비면 작품 취향도 "데이터 없음"으로 넘어간다.
  - 근거: V1 `MyPageViewModel.swift:203-217` · V2 `MypageViewModel.swift:38-49`, `KeywordSection.swift:24-27`,`55-68`

### 1.3 서재 통계 → 서재 이동

- 🔧 **미배선(App 배선 — 서재 이동)** — V1은 서재 통계의 **읽기상태 버튼 4개(관심/보는중/봤어요/하차) 각각**이 탭 대상이고, 탭하면 그 읽기상태로 이동한다(`libraryStatusButtonDidTap` → `pushToSpecificLibraryViewController` → `NotificationCenter.moveToLibraryTab`에 **pageIndex** 전달).
  - **V2: `LibrarySection` 전체가 단일 버튼**이고 그 action이 `//TODO: - 서재 뷰로 이동`, 별도 `icNavigateRight` 버튼도 없음(마이페이지엔 서재 타이틀 행이 없다). 읽기상태별 세분 이동이 사라졌고 이동 자체가 미배선.
  - 근거: V1 `MyPageViewController.swift:86-90`,`183-188`, `MyPageViewModel.swift:147-151` · V2 `MypageView.swift:58-61`, `LibrarySection.swift:22-36`
  - **판정 근거**: 서재 통합 배선은 App에서 채운다(미배선, 삭제 아님). 읽기상태별 진입(pageIndex) 유지 여부는 배선 시 결정.

### 1.4 장르 취향 (대표 3 + 펼침)

- ✅ **Keep** — 대표 장르 3개는 항상 노출, 나머지는 펼침 토글(`showGenreOtherView`)로 표/접기. 펼침 상태는 영속화하지 않음.
  - V2: `GenreSection`이 `topGenrePreferences`(prefix 3) + `remainingGenrePreferences`(dropFirst 3), `isExpanded` 로컬 State. "펼침은 화면 전환마다 초기화되는 순수 UI 상태"로 컴포넌트가 소유.
  - 근거: V1 `MyPageViewController.swift:92-95`,`174-181`, `MyPageViewModel.swift:124-128` · V2 `GenreSection.swift:23-89`

### 1.5 작품 취향 (매력포인트 + 키워드)

- ✅ **Keep** — 매력포인트 문구 + 키워드 칩 목록. 데이터 없으면 "데이터 없음" 안내.
  - V2: `KeywordSection`(`attractivePointsText` + `CountedKeywordChip` FlowLayout / `preferenceNodataSection`).
  - **수단 차이**: V1 키워드 칩은 `UICollectionView`에 텍스트 폭 실측으로 셀 크기를 잡고(높이 relay로 컬렉션뷰 높이 재조정), V2는 `WSSFlowLayout`.
  - 근거: V1 `MyPageViewController.swift:214-226`, `MyPageViewModel.swift:226-232` · V2 `KeywordSection.swift:23-53`

### 1.6 컬렉션 (V2 신규)

- **V1 대응 화면 없음(V2 신규)** — V1 마이페이지엔 컬렉션 섹션이 없다. V2 `myCollectionSection`("컬렉션 N개" → `//TODO: - 컬렉션 뷰로 이동`)은 신규 기능(`CollectionFeature` 연계 대기).
  - 근거: V2 `MypageView.swift:162-188`

### 1.7 설정 진입

- 🔧 **미배선(App 배선)** — V1 마이페이지 우상단 설정 버튼 → 설정 화면 push(`pushToSettingViewController`).
  - **V2: 툴바에 설정 아이콘 버튼이 있으나 action이 `//TODO: - 설정 뷰로 이동`** → 미배선. (설정은 `SettingFeature` 소관이라 App 배선 대기일 수 있음.)
  - 근거: V1 `MyPageViewController.swift:55-58`,`101`,`116-121`, `MyPageViewModel.swift:131-133` · V2 `MypageView.swift:252-262`

### 1.8 스크롤 반응 네비 타이틀

- 🔧 **복원 확정→TODO** (되살린다 소소 — 9절) — V1 마이페이지는 스크롤 오프셋 > 0이면 네비바에 "마이페이지" 타이틀이 드러난다(`updateNavigationBar`, `isVisibleBeforeScroll: false`).
  - **V2: 마이페이지 툴바엔 설정 버튼만 있고 타이틀 표기가 없다** → 스크롤해도 "마이페이지"가 뜨지 않는다. (타유저 프로필의 스크롤 반응 닉네임은 4.10에서 유지.)
  - 근거: V1 `MyPageViewController.swift:55-58`, `MyPageViewModel.swift:114-121` · V2 `MypageView.swift:252-262`

### 1.9 프로필 편집 진입 + 저장 토스트

- ✅ **Keep** — 프로필 이미지 위 편집 어포던스 탭 → 프로필 편집 화면.
  - **수단 차이**: V1은 프로필 이미지 자체(`userImageChangeImageView`) 탭, V2는 프로필 이미지 우하단 연필 아이콘(`icEditProfileMypage`) 오버레이 탭. 둘 다 편집 화면으로.
  - 근거: V1 `MyPageViewController.swift:102`,`123-128`, `MyPageViewModel.swift:135-138` · V2 `MypageView.swift:126-133`,`93-102`
- ✅ **Keep** — 편집 저장 후 **돌아온 마이페이지가** "프로필 저장됨" 토스트를 띄운다(편집 화면이 아니라).
  - **수단 차이**: V1은 편집 완료 시 `NotificationCenter.editProfile`를 post하고 마이페이지가 그 알림을 받아 `showToast(.editUserProfile)`. V2는 `onSaved` 콜백 → `showWSSToast(.editProfile)`. 관찰 동작 동일.
  - 근거: V1 `MyPageViewController.swift:105`,`197-202`, `MyPageEditProfileViewModel.swift:173-177` · V2 `MypageView.swift:99`,`103`, `MyPageEditView.swift:88-92`, `CLAUDE.md`(저장 토스트는 복귀할 마이페이지가)

---

## 2. 프로필 편집 (MyPageEditProfile → MyPageEdit)

원본: `…/MyPage/MyPageViewController/MyPageEditProfileViewController.swift`, `…/MyPage/MyPageViewModel/MyPageEditProfileViewModel.swift`

### 2.1 진입·로드

- ✅ **Keep** — 편집 화면 진입 시 현재 프로필(닉네임·소개·선호장르·캐릭터)을 채운다.
  - **수단 차이**: V1은 진입 경로가 `.myPage`면 마이페이지가 넘겨준 `MyProfileEntity`를 그대로 쓰고, `.home`이면 서버에서 다시 조회. V2는 경로 구분 없이 `onAppear`마다 `loadInitialProfileUseCase`로 **항상 조회**(단발 가드 없음 — 완료 안 누르고 나갔다 오면 미저장 선택이 남는 걸 방지).
  - 근거: V1 `MyPageEditProfileViewModel.swift:102-127` · V2 `MyPageEditViewModel.swift:114-121`,`151-165`
- **⚠️ 진입 경로 `.home`은 V2 이 모듈 소관 아님** — V1은 온보딩/홈에서도 이 편집 VC로 들어올 수 있었다(`MyPageEditEntryType.home`). V2 UserPageFeature의 편집은 마이페이지 진입 전용이고, 최초 프로필 설정류는 `OnboardingFeature`가 담당(확인 필요).
  - 근거: V1 `MyPageEditProfileViewModel.swift:13-16`,`112-127`

### 2.2 닉네임 (중복확인·검증·글자수)

- ✅ **Keep** — 닉네임 유효 문자 규칙 `^[a-zA-Z0-9가-힣]{2,10}$`, 최대 10자. 위반 시 사유별 문구(공백 포함/형식·길이 초과/중복).
  - V2: 도메인 `NicknameDraft`(`validationState`)로 상태 관리, View가 사유별 캡션·색 매핑. `maxLength = NicknameDraft.maxLength`.
  - 근거: V1 `MyPageEditProfileViewModel.swift:30-32`,`219-229`,`351-385` · V2 `MyPageEditView.swift:169-189`,`364-389`, `MyPageEditViewModel.swift:93-96`
- ✅ **Keep** — 별도 "중복확인" 버튼으로 서버 중복 검사. 확인 통과해야 완료가 열린다(입력만으론 안 됨).
  - **수단 차이**: V1은 `checkButtonDidTap`에 `debounce(300ms)` + `getNicknameisValid`, 성공/실패 사유(USER-003 공백·USER-014 변경없음·중복). V2는 `checkNicknameDuplication`이 `validationState == .needDuplicatedCheck && !isCheckingNickname`일 때만 `validateNicknameUseCase` 호출.
  - 근거: V1 `MyPageEditProfileViewModel.swift:255-268`,`373-385`,`393-425` · V2 `MyPageEditViewModel.swift:135-139`,`182-191`, `MyPageEditView.swift:398-402`
- ✅ **Keep** — 닉네임을 현재 값과 같게 되돌리면 중복확인 요구가 해제된다(변경 없으면 확인 불필요).
  - 근거: V1 `MyPageEditProfileViewModel.swift:226-228`, `changeInfoData()` `:332-345` · V2 `NicknameDraft.validationState`(도메인), `MyPageEditView.swift:368`(`.notChanged` 캡션 없음)

### 2.3 소개

- ✅ **Keep** — 소개 최대 50자, 초과 입력 clamp. 공백만이면 유효하지 않음(완료 불가).
  - V2: `ProfileDraft.maxIntroductionLength = 50`, 소개 필드는 로컬 `@State` 버퍼 → `.onChange` 2단계 clamp(글자수 제한 트랩 회피).
  - 근거: V1 `MyPageEditProfileViewModel.swift:33`,`277-283`,`347-349` · V2 `MyPageEditView.swift:213-229`,`258`, `CLAUDE.md`(글자수 제한 TextField 2단계)

### 2.4 선호장르

- ✅ **Keep** — 편집 전용 장르 목록을 칩으로 토글(다중 선택). 선택은 영어 rawValue로 관리.
  - **값 동일성 확인 권장**: V1 목록 `NovelGenre.myPageEditGenres`, V2 `NovelGenre.profileEditGenre` — 이름이 다르니 구성이 같은지 확인.
  - 근거: V1 `MyPageEditProfileViewModel.swift:29`,`293-308` · V2 `MyPageEditView.swift:280-292`, `MyPageEditViewModel.swift:126-132`

### 2.5 저장

- ✅ **Keep** — 완료 시 프로필을 저장하고 곧바로 화면을 닫는다.
  - **수단 차이**: V1은 **바뀐 필드만** dict(`updatedFields`: avatarId/nickname/intro/genrePreferences)로 골라 PATCH. V2는 `updateProfileUseCase.execute(submittedDraft)`로 draft 전체를 넘김(변경분 계산은 도메인/데이터 소관 — 확인 권장).
  - 근거: V1 `MyPageEditProfileViewModel.swift:140-183`,`389-391` · V2 `MyPageEditViewModel.swift:141-144`,`195-206`
- ✅ **Keep** — 완료 버튼은 실제 변경이 있고 유효할 때만 활성(변경 없으면 비활성).
  - V2: `state.draft.isSubmittable`(도메인 판단)으로 완료 버튼 활성/비활성 + 색.
  - 근거: V1 `MyPageEditProfileViewModel.swift:185-196`,`332-345` · V2 `MyPageEditView.swift:333-350`, `MyPageEditViewModel.swift:141-144`
- 🔧 **저우선→TODO** (로컬 프로필 캐시 = TODO 1번과 함께) — V1은 저장 성공 시 새 닉네임을 **UserDefaults(`userNickname`)에도 반영**한다.
  - **V2: Feature 코드엔 이 저장이 없다** — 데이터/도메인 레이어가 캐시를 갱신하는지 별도 확인.
  - 근거: V1 `MyPageEditProfileViewModel.swift:170-171` · V2 `MyPageEditViewModel.swift:195-206`(Feature엔 없음)
- ✅ **Keep** — 저장 실패 시 에러 표시(화면 유지).
  - **수단 차이**: V1은 `onError`에서 `print`만(사실상 무처리). V2는 `presentedError` → 토스트(`.unknownError`). 관찰상 V2가 더 나음(경계 사례).
  - 근거: V1 `MyPageEditProfileViewModel.swift:179-181` · V2 `MyPageEditViewModel.swift:203-205`,`212-215`, `MyPageEditView.swift:87`

### 2.6 상호작용 가드

- ✅ **Keep** — 완료/뒤로/캐릭터진입/취소의 중복 탭을 막는다.
  - **수단 차이**: V1은 `throttle(.seconds(3))`을 각 버튼에 건다. V2는 `isSaving`·`loadTask == nil`·버튼 `disabled` 가드로 대체(명시적 throttle 없음).
  - 근거: V1 `MyPageEditProfileViewModel.swift:133-138`,`140-144`,`199-204` · V2 `MyPageEditViewModel.swift:117`,`141-142`, `MyPageEditView.swift:349`

---

## 3. 캐릭터(아바타) 선택 (MyPageEditAvatar → MypageCharacterEditSheet)

원본: `…/MyPage/MyPageViewController/MyPageEditAvatarViewController.swift`, `…/MyPage/MyPageViewModel/MyPageEditAvatarViewModel.swift`

### 3.1 로드·페이징 재배치

- ✅ **Keep** — 캐릭터 목록을 받아 **페이지당 10개(5열×2행), 열 우선 순서로 재배치**해 가로 페이징으로 보여준다.
  - V2: `characterPages`(pageSize 10) + `columnMajorOrdered`(열 우선 소스 → 행 우선 그리드 변환), `TabView(.page)` + 페이지 인디케이터. V1 `reorderAvatarsForPaging(rows:2, columns:5)`과 동일 의도.
  - 근거: V1 `MyPageEditAvatarViewModel.swift:47-63`,`129-149` · V2 `MypageCharacterEditSheet.swift:113-181`
- ✅ **Keep** — 초기 선택은 대표(`isRepresentative`) 캐릭터. 대표가 목록에 없으면 폴백.
  - V2: 진입 시 넘어온 `selectedCharacterID`가 목록에 없으면 대표(없으면 첫 번째)로 보정.
  - 근거: V1 `MyPageEditAvatarViewModel.swift:54-62` · V2 `MypageCharacterEditSheetViewModel.swift:99-102`

### 3.2 선택·대사 표시

- ✅ **Keep** — 선택한 캐릭터의 이름·대사(닉네임 치환)를 상단 미리보기로 보여준다. 대사에 유저 닉네임이 들어감.
  - V2: `greetingLine`이 `line`의 `"%s"`를 닉네임으로 치환(`String(format:)` 대신 단순 치환 — C 문자열 불일치 회피).
  - 근거: V1 `MyPageEditAvatarViewModel.swift:85-92` · V2 `MypageCharacterEditSheet.swift:82-111`

### 3.3 확인·취소·변경없음

- ✅ **Keep** — "확인"은 선택 결과를 상위(프로필 편집)로 전달하고 닫는다. "취소"는 닫기만.
  - **수단 차이**: V1은 `NotificationCenter.changeRepresentativeAvatar`(avatarId, url) post 후 dismiss. V2는 `onApply(characterID)` 콜백 후 dismiss(draft 반영·시트 dismiss는 부모 책임).
  - 근거: V1 `MyPageEditAvatarViewModel.swift:94-118` · V2 `MypageCharacterEditSheet.swift:193-215`, `MyPageEditView.swift:76-86`, `CLAUDE.md`(.sheet(item:) + onApply)
- 🗑 **Delete** — **"최종 선택 == 대표면 아무것도 안 하고 닫기"** 최적화. V1은 선택이 대표 아바타와 같으면 notification을 post하지 않고 그냥 dismiss했다.
  - V2: `onApply(selectedCharacterID)`를 항상 호출(부모의 `setCharacter`가 같은 값이면 draft가 실질 변화 없어 `isSubmittable`에 영향 없음 — 결과는 유사하나 최적화 자체는 제거).
  - 근거: V1 `MyPageEditAvatarViewModel.swift:98-102` · V2 `MypageCharacterEditSheet.swift:207-211`

---

## 4. 타유저 프로필 (UserPage)

원본: `…/UserPage/UserPageViewController/UserPageViewController.swift`, `…/UserPage/UserPageViewModel/UserPageViewModel.swift`

### 4.1 진입·생명주기

- 🔧 **복원 확정→TODO** (push 재진입 재조회 복원 — 9절) — V1은 `viewWillAppear`마다 프로필·서재·취향·피드를 **다시 로드**한다(`Observable.merge(viewWillAppearEvent, reloadSubject)`).
  - **V2: `load()`가 `guard !hasLoaded, loadTask == nil`** → 최초 1회만 로드. push에서 되돌아와도(피드 상세 등) 재조회하지 않는다.
  - **오탐 방지 참고**: 이 화면은 탭 콘텐츠가 아니라 push라서 [Feature/CLAUDE.md](../CLAUDE.md)의 "탭 복귀마다 갱신"이 직접 적용되진 않는다 — 그래서 1회 가드가 의도일 수 있으나 **문서화된 근거는 없다**.
  - 근거: V1 `UserPageViewController.swift:56-59`, `UserPageViewModel.swift:124-153` · V2 `UserPageViewModel.swift:207-212`, `UserPageView.swift:189-191`
  - **판정 근거**: 되살리기로 확정(횡단 push 재진입 재조회 결정 — `docs/TODO.md` 9절). '비우고 처음부터'는 스크롤·상태 보존을 위해 재검토.

### 4.2 콘텐츠 로드 (병렬)

- ✅ **Keep** — 프로필·서재 통계·장르 취향·작품 취향을 대상 userID로 받는다.
  - V2: `async let` 4종(`.user(userID)` / `LoadUserRegisteredNovelStatsUseCase(id:)`). 하나 실패 시 화면 전체 에러(단, `privateProfile`은 4.7로 분기).
  - **수단 차이**: V1은 헤더 먼저 → concat(서재 → 취향zip → 피드) 순차. V2는 통계·취향은 병렬, **피드는 활동 탭 탭 시 지연 로드**(4.4).
  - 근거: V1 `UserPageViewModel.swift:124-153`,`297-375` · V2 `UserPageViewModel.swift:273-292`

### 4.3 탭 구조 (통계/활동)

- ✅ **Keep** — 상단 스티키 헤더로 2개 탭(개요/통계 ↔ 피드/활동)을 전환. 스크롤 시 헤더가 상단 고정.
  - **수단 차이**: V1은 `mainStickyHeaderView`/`scrolledStickyHeaderView` 두 벌 + `updateStickyHeader`(스크롤 임계 초과 시 교체) + 콘텐츠뷰 제약 remake. V2는 `LazyVStack(pinnedViews:[.sectionHeaders])`의 Section header + `selectedTab`.
  - 근거: V1 `UserPageViewController.swift:116-124`,`163-266`, `UserPageViewModel.swift:186-198` · V2 `UserPageView.swift:84-121`,`284-324`

### 4.4 활동(피드) 미리보기 + 전체보기

- ✅ **Keep** — 활동 탭은 **최대 5개 미리보기**만 보여주고, 5개 초과면 "전체보기(활동기록 더보기)" 버튼으로 전체 목록 화면으로 push.
  - **수단 차이**: V1은 진입 시 `size: 6`으로 받아 `count > 5`면 더보기 버튼(`showFeedDetailButton`), `prefix(5)` 노출. V2는 첫 페이지를 받아 `visibleFeeds = prefix(5)`, `hasMoreFeeds = count > 5 || hasNext`.
  - 근거: V1 `UserPageViewModel.swift:378-413`, `UserPageViewController.swift:285-290`,`328-334` · V2 `UserPageViewModel.swift:82-91`,`294-318`, `UserPageView.swift:437-457`
- ✅ **Keep** — 활동 탭 데이터 로드 지연. V1도 프로필 로드 뒤 피드를 잇는다.
  - V2: 활동 탭 첫 탭에서 `loadFeeds`(NovelDetail 피드 탭과 동일 지연 패턴). 비공개면 재요청 안 함.
  - 근거: V1 `UserPageViewModel.swift:142-149` · V2 `UserPageViewModel.swift:216-222`,`296-299`

### 4.5 피드 셀 상호작용

- 🔧 **Improve** — **피드 셀 좋아요·신고 추가**. V1은 타유저 프로필 피드 셀의 드롭다운·좋아요를 **전부 no-op**(`return`)으로 뒀다(연결 작품 탭만 실제 동작). 즉 남의 프로필에서 그 글에 좋아요/신고를 할 수 없었다.
  - V2: 좋아요 토글(엔티티 정책 위임 + 낙관 반영 + 실패 롤백), threedots 드롭다운으로 스포일러/부적절 신고(2단 확인→접수완료 알럿). (V2 `CLAUDE.md`에 설계로 명문화.)
  - 근거: V1 `UserPageViewController.swift:405-421`(dropdown/like `return`) · V2 `UserPageViewModel.swift:226-236`,`246-264`,`320-359`, `UserPageView.swift:481-521`,`586-616`, `CLAUDE.md`(피드 신고)
- 🔧 **미배선(App 배선)** — 피드 셀의 **연결 작품 탭 → 작품 상세 이동**. V1은 `connectedNovelViewDidTap` → `pushToNovelDetailViewController`로 동작했다.
  - **V2: `linkNovelTapped`가 `//TODO: - 연결 작품 상세로 이동`** → 미배선.
  - 근거: V1 `UserPageViewController.swift:418-420`, `UserPageViewModel.swift:233-237` · V2 `UserPageView.swift:498-508`

### 4.6 차단

- 🔧 **Improve** — **차단에 확인 알럿 추가**. V1은 네비바 드롭다운 "차단하기" 탭 **즉시** 차단 API를 호출했다(확인 단계 없음).
  - V2: `blockUserTapped` → `WSSAlertType.blockUser` 확인 알럿 → `confirmBlockUser`.
  - 근거: V1 `UserPageViewModel.swift:200-212` · V2 `UserPageViewModel.swift:184-189`,`238-243`, `UserPageView.swift:158-166`,`575-580`
- ✅ **Keep** — 차단 성공 시 화면을 떠난다(상대 프로필을 더 볼 이유 없음).
  - **수단 차이**: V1은 `popViewController`(pop), V2는 `state.shouldDismiss` → `dismiss()`.
  - 근거: V1 `UserPageViewModel.swift:206-211` · V2 `UserPageViewModel.swift:336-344`, `UserPageView.swift:186-188`, `CLAUDE.md`(성공하면 dismiss)
- 🔧 **복원 확정→TODO** (되살린다 소소 — 9절) — 차단 성공 **알림(토스트)**. V1은 성공 시 `NotificationCenter.blockUser`(닉네임)를 post해 직전 화면에서 "차단했어요" 류 피드백을 띄우게 한다.
  - **V2: 화면 dismiss만** — 부모에게 차단 완료를 알리는 신호(토스트 등)가 없다.
  - 근거: V1 `UserPageViewModel.swift:207-210` · V2 `UserPageViewModel.swift:340`(shouldDismiss만)
- ✅ **Keep** — 차단 진입점은 네비바 우측 드롭다운(threedots) "차단하기".
  - 근거: V1 `UserPageViewController.swift:384-400` · V2 `UserPageView.swift:541-551`,`568-583`
- ✅ **Keep** — 차단/신고 실패는 에러 토스트(공용).
  - V2: `hasActionError` → `.unknownError` 토스트(차단·신고 공유). V1은 실패 표시가 사실상 없었으므로 이건 V2가 더 나음.
  - 근거: V1 `UserPageViewModel.swift:200-212`(실패 무처리) · V2 `UserPageViewModel.swift:374-377`, `UserPageView.swift:173`

### 4.7 비공개/알 수 없는 프로필

- ✅ **Keep (수단·감지 방식 차이 확인)** — 비공개 프로필이면 프로필 취향/피드 자리에 "비공개" 안내를 보여준다.
  - **감지 차이**: V1은 프로필 응답의 **`isProfilePublic == false` 필드**로 판단해 취향·피드 뷰를 `isPrivateUserPage(nickname:)`로 덮는다. V2는 장르/작품취향/피드 조회가 **`RepositoryError.privateProfile`(USER-015)**을 던지는지로 판단.
  - 근거: V1 `UserPageViewModel.swift:297-327`,`349-350`,`392-396`, `UserPageViewController.swift:179-185` · V2 `UserPageViewModel.swift:312-313`,`365-372`, `UserPageView.swift:98-100`,`200-217`, `CLAUDE.md`(USER-015 감지는 3곳)
- ⏸ **보류(기획)** (→ `docs/PENDING_DECISIONS.md` 4) — **비공개일 때 서재 통계 노출**. V1은 서재 통계 조회(`getUserNovelStatus`)가 비공개 게이팅 밖이라 통계 숫자가 바인딩된다(취향/피드만 비공개 처리).
  - **V2: `isProfilePrivate`가 서면 통계 탭 콘텐츠 전체(서재 섹션 포함)를** 비공개 안내로 대체한다 → 통계 숫자가 안 보인다.
  - 근거: V1 `UserPageViewModel.swift:331-338`(private 게이팅 밖) · V2 `UserPageView.swift:97-117`(private면 Section 전체 대체)
  - **판정 근거**: 기획 판단 → 보류([`PENDING_DECISIONS.md`](../../../docs/PENDING_DECISIONS.md) 4).
- 🔧 **복원 확정→TODO** (USER-018 전용 처리 복원 — 9절) — **"알 수 없는 유저"(USER-018) 폴백**. V1은 프로필 조회가 `USER-018`이면 빈 프로필 + private 처리로 폴백한다("현재 로직상 불가능하지만 대응" 주석).
  - **V2: USER-018 특별 처리 없음** → 일반 로드 실패(`hasLoadError`)로 떨어져 `NetworkErrorView`.
  - 근거: V1 `UserPageViewModel.swift:279-295`,`311-326` · V2 `UserPageViewModel.swift:365-372`(privateProfile만 분기)

### 4.8 서재 통계 → 네비게이션

- 🔧 **미배선(App 배선 — 서재 이동)** — V1 타유저 프로필은 서재 타이틀 탭(`libraryStatusViewDidTap` → 타유저 서재 push) **및** 읽기상태 버튼별 탭(pageIndex 동반 push) 둘 다로 서재로 이동한다.
  - **V2: `LibrarySection` 단일 버튼 + `icNavigateRight` 버튼 모두 `//TODO: - 서재 뷰로 이동`** → 미배선, 읽기상태별 세분도 없음.
  - 근거: V1 `UserPageViewController.swift:105-109`,`137-140`,`292-305`, `UserPageViewModel.swift:214-218`,`239-243` · V2 `UserPageView.swift:326-362`

### 4.9 스크롤 상단 클램프 / 바운싱

- ✅ **Keep (수단 차이)** — 위로 당겨도 흰 배경이 안 비치게 한다.
  - **수단 차이**: V1은 `scrollViewDidScroll`에서 `contentOffset.y < 0`을 0으로 **강제 클램프**(상단 바운스 자체를 죽임). V2는 바운스는 허용하되 프로필 섹션 배경을 위로 오버슈트한 사각형(+ ScrollView 뷰포트 흰 배경)으로 채운다.
  - 근거: V1 `UserPageViewController.swift:374-378` · V2 `UserPageView.swift:126-128`,`261-267`, `CLAUDE.md`(오버슈트 배경)

### 4.10 스크롤 반응 네비 타이틀

- ✅ **Keep** — 프로필이 화면 밖으로 스크롤되면 네비바에 닉네임이 나타난다.
  - **수단 차이**: V1은 `scrollOffset.y > 0`이면 `navigationItem.title = 닉네임`. V2는 프로필 섹션 `minY < -1`에서 principal 닉네임을 페이드인(`GeometryReader` + `onChange` → `@State`).
  - 근거: V1 `UserPageViewModel.swift:163-172`, `UserPageViewController.swift:154-161` · V2 `UserPageView.swift:86-95`,`553-560`, `CLAUDE.md`(스크롤 반응형 네비 타이틀)

---

## 5. 전체 피드 목록 (UserPageFeedDetail → UserFeedList)

원본: `…/UserPage/UserPageViewController/UserPageFeedDetailViewController.swift`, `…/UserPage/UserPageViewModel/UserPageFeedDetailViewModel.swift`

### 5.1 로드·페이지네이션

- ✅ **Keep** — 마지막 피드 ID를 커서로 다음 페이지를 이어 받는 무한 스크롤. 진행 중 중복 요청 가드.
  - **수단 차이**: V1은 `lastFeedIdRelay`(마지막 피드의 `feedId`) + `isFetching`/`isLoadable` 가드, 스크롤 오프셋 임계(`offsetY + frameHeight >= contentHeight - 10`)로 발화. V2는 `state.feeds.last?.feedId`를 커서로, `feedsTask == nil`/`hasNextFeeds` 가드, 마지막 셀 `onAppear`로 발화.
  - 근거: V1 `UserPageFeedDetailViewModel.swift:26-29`,`57-77`,`113-128`, `UserPageFeedDetailViewController.swift:84-94` · V2 `UserFeedListViewModel.swift:142-148`,`188-208`
- 🔧 **Improve** — **로드 실패 표현**. V1은 로드 실패 시 `isFetching = false` + `print`만(화면 표시 없음).
  - V2: 첫 페이지 실패면 `feedsLoadFailed` → `NetworkErrorView`(재시도). (#195 로드 실패 표현 계약 계승.)
  - 근거: V1 `UserPageFeedDetailViewModel.swift:73-76`,`96-99` · V2 `UserFeedListViewModel.swift:204-207`

### 5.2 진입·생명주기

- 🔧 **복원 확정→TODO** (push 재진입 — 9절, '비우고 처음부터'는 재검토) — V1 전체 피드 목록은 `viewWillAppear`마다 목록을 **비우고(feeds=[], lastFeedId=0) 처음부터** 다시 로드한다.
  - **V2: `load()`가 `guard !hasLoadedFirstPage`** → 최초 1회만 로드(재진입 재조회 없음).
  - 근거: V1 `UserPageFeedDetailViewModel.swift:79-100` · V2 `UserFeedListViewModel.swift:134-139`

### 5.3 피드 셀 상호작용

- 🔧 **Improve** — **좋아요·신고 추가**(4.5와 동일). V1 전체 피드 목록도 셀 드롭다운·좋아요가 no-op였고 연결 작품 탭만 동작했다.
  - V2: `UserFeedListViewModel`이 좋아요 토글·신고를 `UserPageViewModel`과 동일 패턴으로 독립 보유.
  - 근거: V1 `UserPageFeedDetailViewController.swift:125-141`(dropdown/like `return`) · V2 `UserFeedListViewModel.swift:151-182`,`210-239`

---

## 부록 A. 서버 요청 파라미터 매핑 (C2 비교 재료)

| 호출 | V1 요청 | V2 요청 | 상태 |
|---|---|---|---|
| 내 프로필 | `getMyProfileData()` (userId = UserDefaults) | `LoadProfileUseCase.execute(target: .me)` | ✅ Keep |
| 타유저 프로필 | `getOtherProfile(userId:)` (진입 profileId) | `LoadProfileUseCase.execute(target: .user(userID))` | ✅ Keep |
| 서재 통계 | `getUserNovelStatus(userId:)` | 내: `LoadRegisteredNovelStatsUseCase()`, 타: `LoadUserRegisteredNovelStatsUseCase(id:)` | ✅ Keep |
| 장르/작품 취향 | `getUserGenrePreferences`·`getUserNovelPreferences(userId:)` | `LoadGenrePreferencesUseCase`·`LoadNovelPreferencesUseCase(.me/.user)` | ✅ Keep |
| 유저 피드 | `getUserFeed(userId, lastFeedId, size, filterOption: nil, sortType: nil)` — 미리보기 `size:6`, 전체 `size:20` | `LoadUserFeedsUseCase.execute(userID, nickname, profileImage, lastFeedID)` | ✅ Keep (size·전송조건 확인) |
| 닉네임 중복 | `getNicknameisValid(nickname:)` | `ValidateNicknameUseCase.execute(_:)` | ✅ Keep |
| 프로필 저장 | `patchUserProfile(updatedFields:)` — **바뀐 필드만** dict | `UpdateProfileUseCase.execute(draft)` — draft 전체(변경분 계산은 데이터 소관) | ✅ Keep (변경분 전송 확인) |
| 아바타 목록 | `getAvatarList()` | `LoadProfileCharacterUseCase.execute()` | ✅ Keep |
| 차단 | `postBlockUser(userId:)` | `BlockUserUseCase.execute(id:)` | ✅ Keep |
| 피드 신고 | **없음**(V1 피드 셀 신고 no-op) | `ReportSpoilerFeedUseCase`·`ReportImproperFeedUseCase` | 🔧 Improve(신규) |
| 피드 좋아요 | **없음**(V1 피드 셀 좋아요 no-op) | `FeedLikeUseCase.like/unlike` | 🔧 Improve(신규) |

- **유저 피드는 응답에 author 정보가 없어** V1·V2 모두 **호출 측이 프로필의 닉네임·아바타를 채워 넣는다**(V1 `UserFeedListItem(avatarImage:nickname:)`, V2 `LoadUserFeedsUseCase(nickname:profileImage:)`). ✅ Keep.
- V1 `getUserFeed`의 `filterOption`/`sortType`은 항상 `nil`로 넘어가는 **죽은 파라미터**다(이 화면들에서 필터/정렬 없음) — 동작으로 적지 말 것.
  - 근거: V1 `UserPageViewModel.swift:455-457`, `UserPageFeedDetailViewModel.swift:132-134`
