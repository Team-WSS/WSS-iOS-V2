# SettingFeature — V1 동작 계약 (V1 Behavior Contract)

> **이 문서는 무엇인가** — 운영 중인 **V1**(`Team-WSS/WSS-iOS`, UIKit·RxSwift)의 설정 화면들이
> **실제로 어떻게 동작했는지**를 코드에서 추출한 목록이다. V1은 "실제 운영으로 검증된 동작 기준"이고,
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
- V1 경로 접두사 생략형: `…/MyPageSetting/` = `WSSiOS/Source/Presentation/UserPage/MyPage/MyPageSetting/`.

## 화면 매핑 (V1 → V2)

| V2 (이 모듈) | V1 원본 | 성격 차이 |
|---|---|---|
| `Sources/Setting/SettingView` (설정 메뉴 7항목) | **MyPageSetting 밖** — 최상위 "설정" 메뉴(`StringLiterals.MyPage.Setting`, 7항목)는 V1에선 MyPage 본체(`MyPageViewController`)가 호스팅 | 메뉴 항목·외부링크는 동일. V1 호스트 VC는 이 폴더 밖(UserPage 영역)이라 메뉴 enum만 대조 |
| `Sources/Setting/Account/SettingAccountInfoView` (계정정보) | `…/MyPageSettingViewController/MyPageInfoViewController` + `MyPageInfoViewModel` (`SettingInfo` 5항목) | 목록 셀 5개는 동일 |
| `Sources/Setting/Account/ChangeGenderOrAge/*` (성별·나이 변경) | `…/MyPageChangeUserInfoViewController` + `…/MyPageChangeUserBirthViewController`(연도 휠) | V1은 VM 없는 VC 직접 로직 |
| `Sources/Setting/ProfilePublic/*` (프로필 공개 설정) | `…/MyPageProfileVisibilityViewController` | VM 없음 |
| `Sources/Setting/Account/BlockUser/*` (차단유저 목록) | `…/MyPageBlockUserViewController` | VM 없음 |
| `Sources/Setting/NotifiactionSetting/NotificationSettingView` (알림 설정) | `…/MyPagePushNotificationViewController` | V1은 토글 1개뿐. V2는 완결/휴재 복귀 알림 행 추가(스텁) |
| `Sources/Setting/Account/Withdraw/WithdrawConfirmView` (탈퇴 경고·통계) | `…/MyPageDeleteIDWarningViewController` | 2단계 중 1단계 |
| `Sources/Setting/Account/Withdraw/WithdrawReasonView` (사유·확인·동의) | `…/MyPageDeleteIDViewController` + `MyPageDeleteIDViewModel` | 2단계 중 2단계 |

---

## 0. 점검 대기 요약

**판정 상태(2026-08-28 갱신)** — 모든 항목에 배지가 달려 있고 본문 각 절의 확정 배지와 일치한다. **판정 대기 0건.** 배지: ✅유지 · 🔧개선/고치기/미배선(되살리기·수정은 `docs/TODO.md` 12절에 구현 대기, 미배선은 App 배선 시 해소) · 🔨회귀 수정 · 🗑삭제 · ⏳⏸보류(`docs/PENDING_DECISIONS.md`) · 🆕V2 신규.

1. **탈퇴 요청 body에서 `refreshToken` 제거** — V1은 탈퇴 요청 body에 `{reason, refreshToken}`를 실었으나, V2는 `{reason}`만 싣는다(인증은 access 토큰 헤더로, 로컬 정리는 `clearTokens()`로). 경로는 둘 다 `/auth/withdraw`. ~~백엔드 V2 스펙이 body의 refreshToken을 요구하지 않는지 확인 필요.~~ → 불요 확정(아래). → [7](#7-회원탈퇴-withdraw-flow--mypagedeleteid), [부록 A](#부록-a-서버-요청-파라미터-매핑-c2-비교-재료)
   - **✅ Keep 확정(2026-08-28, 사용자: 탈퇴 body에 refreshToken 불요 — 헤더 access 토큰 인증).** 현행 `{ reason }` 유지. (보류 해제 — PENDING_DECISIONS 1 닫힘)
2. **연도 휠 상한** — V1 생년 휠은 `1900...2025`(126개), V2는 `BirthYear.minYear...maxYear = 1900...2024`. 2025가 사라진 게 의도인지(도메인 상한 정책) 단순 누락인지. → [3.2](#32-생년-선택-연도-휠)
   - ✅ **해소(#222)** — 한때 `BirthYear.maxYear = 2024` 하드코딩이었으나(2026-08-28 조사 시점) #222에서 **현재 연도 계산값**(`Calendar.current.component(.year, from: Date())`, computed property)으로 전환돼 stale 상수 문제가 사라졌다(`ProfileDomain/CLAUDE.md` 명문 — 계약서 미갱신분을 2026-09-01 코드 대조로 정정).
3. **성별/생년 로컬 캐싱 시점** — V1은 **계정정보 화면 진입 시** 서버 `getUserInfo`로 받은 `birth`를 `UserDefaults.userBirth`에 캐싱하고, 성별/나이 변경 화면이 그 캐시(+`userGender`)를 읽어 시작한다. V2 성별/나이 변경은 `LoadLocalGenderAndBirthUseCase`(로컬)로 시작하는데, **그 로컬값을 어디서 채우는지**(로그인·온보딩·다른 화면)가 이 모듈 밖이라 확인 필요 — 계정정보에 안 들렀다가 바로 변경 화면에 오면 최신이 아닐 수 있다. → [2.3](#23-부수-효과-생년-로컬-캐싱)
   - **✅ 판정(2026-08-28, 조사): ProfileRepository가 로그인·프로필 조회 시 채움(개선·Keep).** `DefaultProfileRepository`가 `.gender`·`.birthYear`를 localStorage에 write(로그인 getMe:36 / 프로필·계정정보 조회:115-116·151-152). V1의 "계정정보 진입 시 캐싱"보다 이른 시점이라 "계정정보 미방문 stale" 우려 완화. 수단은 로컬 UseCase지만 관찰 동작 동일.
4. **V1 "기기 알림 켜기" 유도 알럿의 출처** — V1 `StringLiterals.MyPage.PushNotification`에 `moveToSettingAlertTitle`("앱 알림을 켤까요?")·`moveCancel`·`moveAccept`가 정의돼 있으나 **`MyPagePushNotificationViewController`는 이 문자열을 쓰지 않는다**. V2는 시스템 푸시 권한 확인·유도 알럿을 **`SettingView`가 "알림 설정" 메뉴를 탭한 시점**에 한다(#193, `CLAUDE.md` 명문화). V1이 이 알럿을 어디서(혹은 실제로) 띄웠는지 불명 → V2 배치가 신규인지 이전인지. → [6.3](#63-시스템-푸시-권한-193)
   - **✅ 판정(2026-08-28, 조사): V1도 같은 위치(설정 메뉴 목록)에서 띄웠다 = Keep.** V1 `moveToSettingAlertTitle`("앱 알림을 켤까요?")은 `MyPageSettingViewController.swift:141`(설정 메뉴 목록 VC, PushNotification 서브VC 아님)에서 사용 — V2 `SettingView`의 "알림 설정" 메뉴 탭 시점(#193)과 **동일 위치**. 신규 배치 아님(수단만 다름).

**🔧 눈에 띄는 개선 (근거 확인)**

5. 🔧 **Improve 확정** (2026-08-28, 사용자 — #195 계약) — **프로필 공개 저장 실패를 V1이 조용히 삼켰다** — V1은 공개 설정 저장(PATCH)이 실패해도 `.catch { .empty() }`로 삼키고 **성공한 것처럼 화면을 pop + `ChangeVisibility` 알림까지 발송**한다(실패 무피드백·상태 불일치 버그). V2는 실패 시 토스트를 띄우고 화면을 닫지 않는다. → [4](#4-프로필-공개-설정-profilepublic--mypageprofilevisibility)
6. 🔧 **Improve 확정** (2026-08-28, 사용자 — #195 계약) — **알림 토글이 V1은 서버 성공을 기다렸고 실패를 무시했다** — V1 활동 알림 토글은 **낙관 업데이트가 아니라** 서버 성공 응답을 받은 뒤에야 UI를 바꾸고, `onFailure` 처리가 없어 실패 시 아무 일도 안 일어난다. V2는 즉시 반영(낙관) + 실패 시 이전 값 롤백 + 토스트. → [6.1](#61-활동-알림-토글)
7. 🔧 **Improve 확정** (2026-08-28, 사용자 — #195 계약, 본문 각 절의 Improve bullet 일괄) — **V1은 로드/액션 실패에 사용자 피드백이 거의 없었다** — 계정정보 이메일 로드·차단목록 로드/해제·프로필 공개 로드·알림 로드·로그아웃·탈퇴 실패가 대부분 `print(error)`뿐이다. V2는 전면 `NetworkErrorView`(로드 실패) / 토스트(액션 실패)로 표현한다. → 각 화면 섹션.

**🆕 V2 신규 (V1 대응 없음)**

8. 🆕 **V2 신규(미배선 스텁)** — **완결 알림 / 휴재 복귀 알림 상세** — V2 알림 설정에 두 navigate 행(+`CompletionNotificationListView`·`HiatusReturnNotificationListView`)이 있으나 **아직 미배선 스텁**(`action: {}` TODO, 목록은 `ForEach(0..<10)` 하드코딩). V1엔 없다. Delete 아님 = 신규. → [6.2](#62-완결휴재-복귀-알림-행-신규-스텁)

(나머지는 대부분 ✅ Keep — 구현 수단만 RxSwift·throttle·UINavigation → 구조적 동시성·guard 플래그·NavigationStack으로 바뀌고 관찰 동작은 같다.)

---

## 1. 설정 메뉴 (SettingView)

> ⚠️ V1의 최상위 "설정" 메뉴(7항목)를 **호스팅하는 VC는 이 폴더(MyPageSetting) 밖**(`MyPageViewController` 영역, UserPage 담당)이다. 여기서는 **메뉴 항목 enum만** 대조한다.

- ✅ **Keep** — 메뉴 7항목: 계정정보 · 프로필 공개 설정 · 알림 설정 · 웹소소 공식 계정 · 문의하기 & 의견 보내기 · 개인정보 처리방침 · 서비스 이용약관.
  - V2: `SettingView.SettingMenu` 7 case가 문자열까지 일치. 앞 3개는 앱 내부 push, 뒤 4개는 외부 URL(`openURL`)로 나간다.
  - 근거: V1 `WSSiOS/Resource/Constants/Strings/StringLiterals+MyPage.swift:36-44`(`enum Setting`) · V2 `Sources/Setting/SettingView.swift:196-227`
- ✅ **Keep** — 외부링크 4종(공식계정·문의·개인정보·약관)은 앱 내부 화면이 아니라 웹/외부로 나간다.
  - V2: `SettingMenu.externalURL`(인스타·에러리포트·개인정보·이용약관) → `openURL`. (V1 대응 URL 상수는 MyPage 호스트 VC에 있어 이 폴더에선 미확인 — 동작 성격만 대조.)
  - 근거: V2 `Sources/Setting/SettingView.swift:174-176,218-226`

---

## 2. 계정정보 (SettingAccountInfoView ↔ MyPageInfoViewController)

원본: `…/MyPageSettingViewController/MyPageInfoViewController.swift`, `…/MyPageSettingViewModel/MyPageInfoViewModel.swift`

### 2.1 목록·진입

- ✅ **Keep** — 셀 5개: 성별/나이 변경 · 이메일 · 차단유저 목록 · 로그아웃 · 회원탈퇴. 탭 라우팅도 1:1(성별나이→변경, 차단→목록, 로그아웃→알럿, 회원탈퇴→탈퇴 경고).
  - V2: `SettingAccountInfoView.SettingMenu` 5 case + `select(_:)` 라우팅 동일.
  - 근거: V1 `StringLiterals+MyPage.swift:46-52`(`SettingInfo`), `MyPageInfoViewModel.swift:56-79` · V2 `SettingAccountInfoView.swift:136-149,174-197`
- ✅ **Keep** — "이메일" 행은 **표시 전용**(탭해도 아무 동작 없음). 이메일 문자열을 행 아래에 보여준다.
  - V2: `email` case `isSelectable: false`, `bottomText: viewModel.state.email`.
  - 근거: V1 `MyPageInfoViewModel.swift:64-65`(`case 1: break`), `MyPageInfoViewController.swift:102-104` · V2 `SettingAccountInfoView.swift:81-83,146-147,191-196`
- ✅ **Keep** — 셀 탭 중복 방지(연타로 화면 두 번 push 방지).
  - V2: 수단 변경 — V1은 `itemSelected.throttle(2s)`, V2는 `NavigationStack` + `isPresented` bool(같은 화면 두 번 push 불가).
  - 근거: V1 `MyPageInfoViewModel.swift:57`(throttle 2초) · V2 `SettingAccountInfoView.swift:96-118`

### 2.2 이메일 로드

- ✅ **Keep** — 이메일은 **부가정보라 로드 실패해도 화면을 막지 않는다**(다른 액션은 이메일 없이도 가능).
  - V2: `loadEmail()` catch에서 로깅만, `email`은 nil로 둠(행 아래만 빔). V1도 `getUserInfo` 실패 시 `print`만.
  - 근거: V1 `MyPageInfoViewModel.swift:81-93` · V2 `SettingAccountInfoViewModel.swift:116-123`
- 🔧 **Improve** (수단) — V1은 계정정보 진입마다 서버 `getUserInfo`를 무조건 다시 부른다(가드 없음). V2는 `hasLoaded` 가드로 **1회만** 이메일을 로드한다.
  - 근거: V1 `MyPageInfoViewModel.swift:81-93`(`Observable.just(())` 무조건) · V2 `SettingAccountInfoViewModel.swift:100-103,119`

### 2.3 부수 효과 (생년 로컬 캐싱)

- ✅ **Keep 확정** (2026-08-28, 조사: ProfileRepository가 로그인·프로필/계정정보 조회 시 로컬에 채움 — 0절 3) — V1은 계정정보 화면이 `getUserInfo` 응답의 `birth`를 **`UserDefaults.userBirth`에 캐싱**한다. 성별/나이 변경 화면이 이 캐시를 읽어 시작하므로, **변경 화면의 초기값 신선도가 계정정보 진입에 의존**한다. V2는 `DefaultProfileRepository`가 로그인·조회 시점에 로컬을 채워 V1보다 이른 시점이라 stale 우려 완화(수단은 로컬 UseCase, 관찰 동작 동일).
  - V2: 성별/나이 변경이 `LoadLocalGenderAndBirthUseCase`(로컬)로 시작하나, **로컬값을 채우는 지점이 이 모듈 밖**이라 대조 불가. 계정정보에 안 들르고 바로 변경 화면에 와도 최신인지 확인 필요.
  - 근거: V1 `MyPageInfoViewModel.swift:89`(`UserDefaults.set(data.birth, …userBirth)`) · V2 `SettingChangeGenderOrAgeViewModel.swift:126-137`

### 2.4 로그아웃

- ✅ **Keep** — "로그아웃 할까요?" 알럿(취소/로그아웃) → 확인 시에만 로그아웃 실행. 실행엔 `refreshToken`(UserDefaults) + `deviceIdentifier`(Keychain)가 필요하고, 성공하면 세션(토큰·개인정보) 정리 후 로그인 화면으로.
  - V2: 알럿(`.logout`) → `confirmLogout` → `LogoutUseCase`(서버 `postLogout` + `clearTokens`) → `logoutSucceeded` → `onLogoutSuccess`(세션 종료·화면 전환은 App 책임). 알럿 문구·2버튼·라우팅 계승.
  - 근거: V1 `MyPageInfoViewController.swift:125-138`, `MyPageInfoViewModel.swift:95-118`, `StringLiterals+MyPage.swift:148-152` · V2 `SettingAccountInfoViewModel.swift:105-135`, `SettingAccountInfoView.swift:121-133`, `DefaultAuthRepository.swift:66-89`
- ✅ **Keep** — 로그아웃 요청 body는 `{refreshToken, deviceIdentifier}`.
  - 근거: V1 `WSSiOS/Source/Data/DTO/AuthResult.swift:35-38`(`LogoutRequest`) · V2 `DefaultAuthRepository.swift:76-77`
- ✅ **Keep** — 중복 실행 방지.
  - V2: 수단 변경 — V1 `throttle(3s)`, V2 `guard !state.isLoggingOut`.
  - 근거: V1 `MyPageInfoViewModel.swift:96` · V2 `SettingAccountInfoViewModel.swift:107`
- 🔧 **Improve** — **로그아웃 실패 피드백**. V1은 `onError`에서 `print`만(사용자 무피드백). V2는 `presentedError = .unknown` → `.unknownError` 토스트.
  - 근거: V1 `MyPageInfoViewModel.swift:114-116` · V2 `SettingAccountInfoViewModel.swift:132-133,141-144`, `SettingAccountInfoView.swift:129`

---

## 3. 성별/나이 변경 (ChangeGenderOrAge ↔ MyPageChangeUserInfo/Birth)

원본: `…/MyPageChangeUserInfoViewController.swift`, `…/MyPageChangeUserBirthViewController.swift`

### 3.1 성별·완료 버튼

- ✅ **Keep** — 성별 남/여 토글, 생년 버튼 탭 시 연도 선택 시트. "완료"는 **성별 또는 생년이 최초값과 달라졌을 때만** 활성화.
  - V2: `selectGender`/`selectBirthYear` + `hasChanges = state.draft != baselineDraft`(로드 기준선 대비).
  - 근거: V1 `MyPageChangeUserInfoViewController.swift:78-92,165-168`(`checkIsEnabledCompleteButton`) · V2 `SettingChangeGenderOrAgeViewModel.swift:38-39,89-92`
- ✅ **Keep** — 저장은 서버 PUT + 로컬(`userGender`/`userBirth`) 갱신을 함께 한다. 성공 시 화면을 닫고 부모(계정정보)가 변경 완료 토스트를 띄운다.
  - V2: `SaveAccountInfoDraftUseCase`(서버 PUT + UserDefaults 갱신, ProfileDomain 계약) → `shouldDismiss` → 부모 `onSaveSuccess`에서 `.changeInfo` 토스트. (V1은 성공 후 0.2s 지연 뒤 `ChangeUserInfo` 알림 발송 → 부모가 `showToast(.changeUserInfo)`.)
  - 근거: V1 `MyPageChangeUserInfoViewController.swift:100-123,158-161`, `MyPageInfoViewController.swift:83-87` · V2 `SettingChangeGenderOrAgeViewModel.swift:139-149`, `SettingAccountInfoView.swift:96-103,119-120`, `CLAUDE.md`(성별/나이 변경 = ProfileDomain 재사용)
- ✅ **Keep** — 저장 중복 실행 방지.
  - V2: 수단 변경 — V1 `throttle(3s)` + `isEnabledCompleteButton` 가드, V2 `guard !state.isSaving`.
  - 근거: V1 `MyPageChangeUserInfoViewController.swift:101-104` · V2 `SettingChangeGenderOrAgeViewModel.swift:117-119`

### 3.2 생년 선택 (연도 휠)

- ✅ **Keep** — 커밋-온-확인: 휠을 굴려 중앙 셀만 바뀌고, "완료"를 눌러야 부모 생년에 반영된다. X(취소)는 반영 없이 닫기만.
  - V2: `SettingChangeBirthYearPickerSheet`가 내부 `draftYear`만 갱신, "완료"에서 부모 `selectedYear`(Binding)로 커밋, X는 커밋 없이 닫기(`CLAUDE.md` 명문화).
  - 근거: V1 `MyPageChangeUserBirthViewController.swift:68-85`(cancel=dismiss, complete=getCenterCellYear→post) · V2 `CLAUDE.md`(커밋-온-확인 패턴)
- 🔧 **복원 확정→TODO** (생년 휠 상한 dynamic화 — 12절 소소 묶음) — 연도 범위 상한. V1 휠은 `1900...2025`, V2는 `BirthYear.minYear...maxYear = 1900...2024`.
  - 근거: V1 `MyPageChangeUserBirthViewController.swift:18`(`Array(1900...2025)`) · V2 `ProfileDomain/…/BirthYear.swift:12-13`
- ✅ **Keep** (수단) — 스냅 스크롤(가장 가까운 셀에 정렬)·중앙 셀 하이라이트. V2는 `WSSBirthYearWheel`(WSSComponent 공용, 연도 1열) 컴포넌트가 담당.
  - 근거: V1 `MyPageChangeUserBirthViewController.swift:105-146` · V2 `CLAUDE.md`(주의사항 — `WSSBirthYearWheel`)

---

## 4. 프로필 공개 설정 (ProfilePublic ↔ MyPageProfileVisibility)

원본: `…/MyPageProfileVisibilityViewController.swift`

- ✅ **Keep** — 진입 시 현재 공개 상태(`isProfilePublic`)를 서버에서 로드해 토글 초기화, "완료"는 **로드 기준선과 달라졌을 때만** 활성화.
  - V2: `LoadProfileVisibilityUseCase` → `baselineIsPublic`, `hasChanges = state.isPublic != baselineIsPublic`.
  - 근거: V1 `MyPageProfileVisibilityViewController.swift:67-81,113-116` · V2 `SettingProfilePublicViewModel.swift:41,100-128`
- ✅ **Keep** — "완료" 저장은 PATCH로 공개/비공개를 서버에 반영하고 화면을 닫는다.
  - V2: `UpdateProfileVisibilityUseCase` → `shouldDismiss`. 성공 후 부모(SettingView)가 공개/비공개별 토스트(`changePublic`/`changePrivate`)를 띄운다(V1은 `ChangeVisibility` 알림 발송, 토스트는 부모 몫).
  - 근거: V1 `MyPageProfileVisibilityViewController.swift:96-108,118-121` · V2 `SettingProfilePublicViewModel.swift:108-140`, `SettingView.swift:130-137,179-182`
- 🔧 **Improve 확정** (2026-08-28, 사용자 — #195 로드 실패 표현 계약) — **저장 실패를 V1이 조용히 삼켰다**. V1은 PATCH 실패 시 `.catch { Observable.empty() }`로 에러를 삼키고 **성공한 것처럼 pop + `ChangeVisibility` 알림까지 발송**한다(상태 불일치·무피드백 버그). V2는 실패 시 `toastError` 토스트를 띄우고 **화면을 닫지 않는다**(`shouldDismiss`는 성공에서만).
  - 근거: V1 `MyPageProfileVisibilityViewController.swift:96-108`(`.catch`→empty→pop) · V2 `SettingProfilePublicViewModel.swift:130-140`
- 🔧 **Improve** — **로드 실패 표현**. V1은 로드(`getUserProfileVisibility`)에 실패 처리가 없어 화면이 기본값(공개=true)에 멈춘다. V2는 `loadError` → 전면 `NetworkErrorView` + 재시도(저장 실패 토스트와 분리).
  - 근거: V1 `MyPageProfileVisibilityViewController.swift:67-74`(catch 없음) · V2 `SettingProfilePublicViewModel.swift:26-30,117-128,146-149`

---

## 5. 차단유저 목록 (BlockUserList ↔ MyPageBlockUser)

원본: `…/MyPageBlockUserViewController.swift`

- ✅ **Keep** — 진입 시 차단 목록 로드, 비어 있으면 빈 뷰("차단한 유저가 없어요") 표시.
  - V2: `LoadBlockedUsersUseCase` → `blockedUsers`, 빈 목록이면 빈 상태.
  - 근거: V1 `MyPageBlockUserViewController.swift:82-97`, `StringLiterals+MyPage.swift:74-78` · V2 `SettingBlockUserListViewModel.swift:95-120`
- ✅ **Keep** — 행(또는 "차단 해제" 버튼) 탭 시 **확인 알럿 없이 즉시 차단 해제**, 성공하면 목록에서 제거하고 닉네임이 담긴 토스트를 띄운다.
  - V2: `unblock(user)` → `UnblockUserUseCase` → 목록에서 제거 + `unblockedUser`(성공 토스트 "OO님을 차단 해제했어요"). 즉시 해제·무알럿 계승.
  - 근거: V1 `MyPageBlockUserViewController.swift:107-129` · V2 `SettingBlockUserListViewModel.swift:102-132`
- ✅ **Keep** — 차단 해제 중복 탭 방지.
  - V2: 수단 변경 — V1 `itemSelected.throttle(0.5s)`, V2 `unblockingBlockIDs: Set`(행별 진행 표시 + 재탭 차단).
  - 근거: V1 `MyPageBlockUserViewController.swift:108` · V2 `SettingBlockUserListViewModel.swift:24-25,102-107`
- 🔧 **Improve** — **해제 실패 피드백**. V1은 `onError`에서 `print`만(행은 그대로, 무피드백). V2는 `toastError` 토스트(목록·화면 유지).
  - 근거: V1 `MyPageBlockUserViewController.swift:126-128` · V2 `SettingBlockUserListViewModel.swift:128-132,143-145`
- 🔧 **Improve** — **로드 실패 표현**. V1은 로드 실패 처리가 없다. V2는 `loadError` → 전면 `NetworkErrorView`(해제 실패 토스트와 분리).
  - 근거: V1 `MyPageBlockUserViewController.swift:82-89`(catch 없음) · V2 `SettingBlockUserListViewModel.swift:29-33,97-99,138-140`

---

## 6. 알림 설정 (NotificationSetting ↔ MyPagePushNotification)

원본: `…/MyPagePushNotificationViewController.swift`

### 6.1 활동 알림 토글

- ✅ **Keep** — 앱 안 "활동 알림" on/off 토글 1개. 진입 시 서버에서 현재 값을 로드해 초기화, 탭하면 서버에 반전 값을 저장. (이 토글은 iOS 시스템 권한과 **별개** — `CLAUDE.md` 명문화.)
  - V2: `LoadPushPreferenceUseCase`/`UpdatePushPreferenceUseCase`, `WSSToggleButton`.
  - 근거: V1 `MyPagePushNotificationViewController.swift:57,73-84,90-108` · V2 `NotificationSettingViewModel.swift:100-131`, `NotificationSettingView.swift:48-52`
- 🔧 **Improve 확정** (2026-08-28, 사용자 — #195 로드 실패 표현 계약) — **낙관 업데이트 + 실패 롤백**. V1 토글은 **서버 성공을 기다린 뒤에야** UI를 바꾸고(`onSuccess`에서만 relay 갱신), `onFailure` 처리가 없어 저장 실패 시 아무 반응이 없다. V2는 즉시 반영(낙관) 후 실패하면 이전 값으로 롤백 + 토스트.
  - 근거: V1 `MyPagePushNotificationViewController.swift:101-108`(성공에서만 반영, 실패 무처리) · V2 `NotificationSettingViewModel.swift:100-105,123-130`
- 🔧 **Improve** — **로드 실패 표현**. V1은 로드 실패 시 `print`만(토글이 기본 true에 멈춤). V2는 `loadError` → 전면 `NetworkErrorView`(토글 실패 토스트와 분리).
  - 근거: V1 `MyPagePushNotificationViewController.swift:90-98` · V2 `NotificationSettingViewModel.swift:28-33,111-121,136-139`

### 6.2 완결/휴재 복귀 알림 행 (신규 스텁)

- 🆕 **V2 신규** — 알림 설정에 "완결 알림"·"휴재 복귀 알림" navigate 행이 추가됐다(각각 `CompletionNotificationListView`·`HiatusReturnNotificationListView`). V1엔 없다.
  - 상태: **미배선 스텁** — 행 `action: {}`(TODO), 상세 목록은 `ForEach(0..<10)` 하드코딩·"수정" 버튼 무동작. Delete 아님 = 신규 기능 골격.
  - 근거: V2 `NotificationSettingView.swift:53-60`, `Completion/CompletionNotificationListView.swift:26-33,68-74` · (V1 대응 없음)

### 6.3 시스템 푸시 권한 (#193)

- ✅ **Keep 확정** (2026-08-28, 조사: V1도 설정 메뉴 `MyPageSettingViewController`에서 띄움 = 동일 위치 — 0절 4) — V1 `StringLiterals.MyPage.PushNotification`에 기기 알림 유도 알럿 문구(`moveToSettingAlertTitle` "앱 알림을 켤까요?" 등)가 정의돼 있으나 **`MyPagePushNotificationViewController`는 이 문자열을 쓰지 않는다**(이 폴더 안에서 미사용). 실사용처는 설정 메뉴 목록 VC(`MyPageSettingViewController.swift:141`)로, V2 `SettingView`의 "알림 설정" 메뉴 탭 시점(#193)과 동일 위치 — 신규 배치 아님.
  - V2: 시스템 푸시 권한 확인·유도 알럿을 **`SettingView`가 "알림 설정" 메뉴 탭 순간** 처리한다(#193, `denied`면 이동 안 하고 `setAppNotification` 알럿만, `notDetermined`면 시스템 프롬프트 후 이동). `NotificationSettingView`는 자체 재확인을 하지 않는다(중복 방지). — 이 배치·계약은 `CLAUDE.md`에 명문화된 **의도된 설계**.
  - **판정 근거**: 조사로 대조 완료 — V1은 `MyPageSettingViewController.swift:141`(설정 메뉴 목록)에서 띄웠고, V2 `SettingView` "알림 설정" 메뉴 탭 시점과 같은 위치다.
  - 근거: V1 `StringLiterals+MyPage.swift:138-146`(문구만, VC 미사용) · V2 `SettingViewModel.swift:80-93`, `SettingView.swift:146-163`, `CLAUDE.md`(#193 계약)

---

## 7. 회원탈퇴 (Withdraw flow ↔ MyPageDeleteID*)

원본: `…/MyPageDeleteIDWarningViewController.swift`, `…/MyPageDeleteIDViewController.swift`, `…/MyPageSettingViewModel/MyPageDeleteIDViewModel.swift`

### 7.1 흐름·구조

- ✅ **Keep** — **2단계 흐름**: (1) 탈퇴 경고 화면(정말 탈퇴할지 + 내 서재 통계) → "확인" → (2) 사유·주의사항·동의 화면 → "탈퇴하기".
  - V2: `WithdrawConfirmView`(경고·통계) → `onConfirm` → `WithdrawReasonView`(사유·확인블록·동의). 체이닝은 `WithdrawFlowView` 컨테이너로 배선(`CLAUDE.md` 주의사항 — 이중 `navigationDestination` 함정 회피).
  - 근거: V1 `MyPageDeleteIDWarningViewController.swift:81-87`(complete→push DeleteID) · V2 `WithdrawConfirmView.swift:25-32,79-81`, `WithdrawReasonView.swift`, `CLAUDE.md`(WithdrawFlowView)

### 7.2 경고 화면 (통계)

- ✅ **Keep** — "정말 탈퇴하시겠어요?" + "남겼던 평가와 기록들이 모두 사라져요.." + 내 서재 통계 4종(관심·보는 중·봤어요·하차) 카운트.
  - V2: `WithdrawConfirmView` 문구 동일, `LoadRegisteredNovelStatsUseCase` → `RegisteredNovelStats(interest/watching/watched/quit)` 그리드. (V1은 `getUserNovelStatus(userId:)`로 카운트 로드.)
  - 근거: V1 `MyPageDeleteIDWarningViewController.swift:62-71`, `StringLiterals+MyPage.swift:80-89` · V2 `WithdrawConfirmView.swift:41-75`, `WithdrawConfirmViewModel.swift:79-83`
- ✅ **Keep** — 통계는 부가정보라 로드 실패해도 화면을 막지 않고 0으로 표시(탈퇴 액션 자체는 항상 가능).
  - 근거: V1 `MyPageDeleteIDWarningViewController.swift:66-70`(실패 시 `print`) · V2 `WithdrawConfirmViewModel.swift:78-87`

### 7.3 사유·확인·동의 화면

- ✅ **Keep** — 탈퇴 사유 5종(자주 안 씀 / 불편·장애 / 삭제할 내용 / 원하는 작품 없음 / **직접 입력**) 중 택1 + 직접 입력 시 자유 텍스트(최대 **80자**).
  - V2: `WithdrawalReasonOption` 5 case + `customReasonText`, `maxCustomReasonLength = 80`. 프리셋 선택 시 텍스트 클리어, 텍스트 입력 시 `custom` 선택으로 전환.
  - 근거: V1 `MyPageDeleteIDViewModel.swift:19,79-99,107-113`, `StringLiterals+MyPage.swift:99-111` · V2 `WithdrawalReasonOption.swift`, `WithdrawalDraft.swift:16-38`, `WithdrawReasonView.swift:110-130,168-175`
- ✅ **Keep** — "탈퇴하기 전에 확인해주세요" 3개 안내 블록(계정 복구 불가 / 게시글·댓글 자동삭제 안 됨 / 재가입 시 처음부터) + "위 주의사항을 모두 확인했고, 탈퇴에 동의합니다" 동의 체크박스.
  - V2: 문구 동일. (V1은 경고 화면이 아니라 이 화면에 3개 체크리스트 + 동의 버튼이 있음 — V2는 사유 화면에 함께 둔 구조까지 동일.)
  - 근거: V1 `StringLiterals+MyPage.swift:91-97,113-123`, `MyPageDeleteIDViewModel.swift:24,72-77` · V2 `WithdrawReasonView.swift:61-80`
- ✅ **Keep** — "탈퇴하기" 버튼은 **(사유 유효 + 동의 체크)** 를 모두 만족할 때만 활성화. 직접 입력 사유는 공백만이면 무효.
  - V2: `WithdrawalReasonDraft.isSubmittable`(사유 검증 + `policyAgreed`), 커스텀은 trim 후 비어있지 않아야.
  - 근거: V1 `MyPageDeleteIDViewModel.swift:165-176`(combineLatest: 동의 + (프리셋 or 공백 아님)) · V2 `WithdrawalDraft.swift:18-22`, `WithdrawReasonView.swift:85-89`
- ✅ **Keep** — 제출 → 서버 탈퇴 → 세션(토큰·개인정보) 정리 → 로그인 화면으로. 중복 제출 방지.
  - V2: `WithdrawUseCase`(서버 `postWithdraw` + `clearTokens`) → `shouldDismiss` → `onWithdrawSuccess`(세션 종료·전환은 App). 수단 변경: V1 `throttle(3s)` → V2 `guard !isSubmitting`. (V1은 성공 시 Amplitude `withdraw` 이벤트도 track — V2는 `logger`.)
  - 근거: V1 `MyPageDeleteIDViewModel.swift:130-163` · V2 `WithdrawReasonViewModel.swift:88-107`, `DefaultAuthRepository.swift:91-108`
- 🔧 **Improve** — **탈퇴 실패 피드백**. V1은 `onError`에서 `print`만. V2는 `presentedError` 토스트.
  - 근거: V1 `MyPageDeleteIDViewModel.swift:159-161` · V2 `WithdrawReasonViewModel.swift:104-105,112-116`
- 🔧 **Improve** — **사유 문자열 오타 정정**. V1은 "원하는 작품이 없어서" 사유의 rawValue에 **선행 공백**(`" 원하는 작품이 없어서"`)이 있어 그대로 서버에 전송된다. V2 매퍼는 공백 없는 값을 보낸다.
  - 근거: V1 `StringLiterals+MyPage.swift:103`(`case fourth = " 원하는 작품이 없어서"`) · V2 `AuthMapper.swift:32`(`"원하는 작품이 없어서"`)

---

## 부록 A. 서버 요청 파라미터 매핑 (C2 비교 재료)

### A.1 회원탈퇴 `POST /auth/withdraw`

| 항목 | V1 전송 | V2 전송 | 상태 |
|---|---|---|---|
| 경로 | `/auth/withdraw` | `/auth/withdraw` | ✅ Keep |
| body `reason` | 사유 문자열(프리셋 rawValue 또는 직접 입력 텍스트) | 동일(`AuthMapper.withdrawalReason`가 option→문자열 매핑) | ✅ Keep (오타 1건 7.3) |
| body `refreshToken` | **포함** | **미포함** | ✅ Keep 확정(2026-08-28, 사용자: 불요 — 헤더 access 토큰 인증) |
| 인증 | access 토큰 헤더(`tokenCheckURLSession`) | access 토큰 헤더(`.requireToken`) | ✅ Keep |
| 성공 후 로컬 | UserDefaults(userId·nickname·gender·accessToken·refreshToken) 제거 | `tokenStore.clearTokens()`(도메인 계약이 토큰·개인정보 정리 책임) | ✅ Keep (정리 위치 이동) |

- 사유 매핑값: `자주 사용하지 않아서` / `이용이 불편하고 장애가 많아서` / `삭제하고 싶은 내용이 있어서` / `원하는 작품이 없어서`(V1은 선행 공백) / (custom=직접 입력 텍스트).
- 근거: V1 `MyPageDeleteIDViewModel.swift:130-163`, `WSSiOS/Source/Data/DTO/AuthResult.swift:30-33`(`WithdrawRequest{reason, refreshToken}`), `WSSiOS/Network/Auth/AuthService.swift:95-113`, `WSSiOS/Resource/Constants/URLs/URLs.swift:15` · V2 `AuthMapper.swift:24-36`, `DTO/Request/WithdrawRequest.swift:9-11`, `AuthEndpoint.swift:20,46,60-61,66-72`

### A.2 로그아웃 `POST /auth/logout`

| 항목 | V1 전송 | V2 전송 | 상태 |
|---|---|---|---|
| body `refreshToken` | 포함(UserDefaults) | 포함(`tokenStore`) | ✅ Keep |
| body `deviceIdentifier` | 포함(Keychain) | 포함(`deviceIdentifierStore`) | ✅ Keep |
| 사전 가드 | refreshToken/deviceIdentifier 없으면 요청 안 함(`Observable.empty()`) | 없으면 `RepositoryError.unknown` throw | ✅ Keep |

- 근거: V1 `MyPageInfoViewModel.swift:95-118`, `AuthResult.swift:35-38` · V2 `DefaultAuthRepository.swift:66-89`

### A.3 활동 알림 설정 `GET/POST` push 설정

| 항목 | V1 | V2 | 상태 |
|---|---|---|---|
| 로드 | `GET pushNotificationSetting` → `isPushEnabled` | `LoadPushPreferenceUseCase` → `PushPreference.isEnabled` | ✅ Keep |
| 저장 | `POST pushNotificationSetting` body `{isPushEnabled}` | `UpdatePushPreferenceUseCase(PushPreference{isEnabled})` | ✅ Keep |
| 저장 반영 시점 | 서버 성공 후 반영(비낙관) | 즉시 반영(낙관) + 실패 롤백 | 🔧 Improve (6.1) |

- 근거: V1 `MyPagePushNotificationViewController.swift:90-108`, `WSSiOS/Network/Notification/NotificationService.swift:122-156` · V2 `NotificationSettingViewModel.swift:100-131`

### A.4 프로필 공개 / 성별·나이 / 차단해제

| 액션 | V1 | V2 | 상태 |
|---|---|---|---|
| 공개 설정 로드/저장 | `getUserProfileVisibility` / `patchUserProfileVisibility{isProfilePublic}` | `LoadProfileVisibilityUseCase` / `UpdateProfileVisibilityUseCase(ProfileVisibility{isPublic})` | ✅ Keep (저장 실패 처리는 4) |
| 성별/나이 저장 | `putUserInfo{gender:"M"/"F", birth:Int}` + UserDefaults 갱신 | `SaveAccountInfoDraftUseCase(AccountInfoDraft)` (서버 PUT + UserDefaults) | ✅ Keep (Gender 매핑값 동일성 확인 권장) |
| 차단 해제 | `deleteBlockUser(blockID)` | `UnblockUserUseCase(id: BlockID)` | ✅ Keep |

- 근거: V1 `MyPageProfileVisibilityViewController.swift:113-121`, `MyPageChangeUserInfoViewController.swift:78-80,158-161`, `MyPageBlockUserViewController.swift:138-142` · V2 `SettingProfilePublicViewModel.swift`, `SettingChangeGenderOrAgeViewModel.swift`, `SettingBlockUserListViewModel.swift`
