# OnboardingFeature — V1 동작 계약 (V1 Behavior Contract)

> **이 문서는 무엇인가** — 운영 중인 **V1**(`Team-WSS/WSS-iOS`, UIKit·RxSwift)의 로그인·온보딩 화면들이
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
| ❓ **Unknown** | 회귀일 수도, 의도일 수도 — **판정 대기** | **판정 필요** |

- ❓ 항목과 눈에 띄는 🔧/🗑는 [0 점검 대기 요약](#0-점검-대기-요약)에 모아뒀다.
- 근거는 **`repo@commit + 내부 경로`**로 남긴다(머신마다 다른 절대경로 금지). V1 스냅샷 기준 커밋: **`Team-WSS/WSS-iOS@eefcb9b2`**.
- V1 경로 접두사 생략형: `…/Onboarding/` = `WSSiOS/Source/Presentation/Onboarding/`, `…/Login/` = `WSSiOS/Source/Presentation/Login/`, `…/Base/` = `WSSiOS/Source/Presentation/Base/`.

## 화면 매핑 (V1 → V2)

| V2 (이 모듈) | V1 원본 | 성격 차이 |
|---|---|---|
| `Sources/Intro/` (인트로+소셜로그인) | `…/Login/` (`LoginViewController`+VM) | 배너 캐러셀 + 소셜 로그인. **V2는 "둘러보기(비로그인)" 제거** (1) |
| `Sources/StepFlow/` + `Nickname/`·`GenderBirthYear/`·`GenreSelection/` (닉네임→성별출생→장르) | `…/Onboarding/Onboarding/` (`OnboardingViewController`+VM, **한 화면 안 3-stage 가로 스크롤**) | V1도 한 VC의 가로 스크롤 3단계 = V2 컨테이너 슬라이드 3단계 (2) |
| `Sources/TermsAgreement/` (가입약관 시트) | `…/Base/ServiceTermAgreement/` (`ServiceTermAgreementViewController`, **VM 없음·로직 VC**) | V1은 온보딩 진입 후 조건부 present, V2는 별도 스텝 시트 (3) |
| `Sources/Complete/` (계약 완료) | `…/Onboarding/OnboardingSuccess/` (`OnboardingSuccessViewController`) | 닉네임 인사 + CTA → 홈 (4) |
| *(V2 없음)* | `…/Base/InduceLogin/` (`InduceLoginViewController`, 게스트 로그인 유도 모달) | **V2가 게스트 경로 통째 제거** (5) |

---

## 0. 점검 대기 요약

**회귀 후보 판정** — 각 항목 배지가 결과다(✅유지·🔧고치기·🗑삭제·⏳⏸보류). 배지 없는 항목은 `docs/TODO.md` 9·10절로 이관됐거나 아직 판정 대기다.

1. **약관 시트 조건부 노출** — V1은 온보딩 진입(`viewDidLoad`)에서 `getTermSetting()` 서버 조회로 **필수 약관 미동의일 때만** 약관 시트를 present한다. V2는 약관을 별도 스텝 시트로 두는데, **"이미 동의한 유저면 건너뛴다"는 게이팅이 Feature에 없다**(순서·조건은 App 배선 몫). 기존 유저 재진입 시 약관을 또 보이는지 확인 필요. → [3.1](#31-노출-조건)
   - **⏳ App 배선 대기(2026-08-28): 순서·게이팅은 App 몫.** V2는 약관을 온보딩 스텝 시트로 두고, "이미 동의한 유저 스킵" 게이팅은 App 부트스트랩이 조립(로그인 필수 앱 전제와 동일 결). 회귀 아님.
2. **Apple 로그인 V1.4.0 동기화** — V1은 `needsAppleSyncV140`(accessToken 캐시 있고 미동기화)면 일반 로그인 대신 `syncAppleLoginState`(재인증 동기화)를 탄다. V2엔 대응이 전혀 없다. **특정 릴리즈(v1.4.0) 마이그레이션 워크어라운드**라 신규 클라이언트 V2엔 불필요해 보이나 명문 근거는 못 찾음. → [1.4](#14-apple-로그인)
   - **🗑 확정(2026-08-28): 의도된 제거(마이그레이션 잔재).** v1.4.0 특정 릴리즈 전용 재인증 동기화 — 신규 클라이언트 V2엔 불필요. 되살리지 않음.
3. **v1.4.0 재로그인 확인 액션시트** — V1 로그인 화면은 `didEnterLoginV140` 플래그가 없고 이미 로그인된 상태면 "로그인 확인이 필요합니다" 액션시트를 띄운다(업데이트 후 1회). V2엔 없다. 위와 같은 마이그레이션 성격. → [1.5](#15-v140-마이그레이션-워크어라운드)
   - **🗑 확정(2026-08-28): 의도된 제거(마이그레이션 잔재).** #2와 동일 — v1.4.0 업데이트 후 1회 재로그인 유도, V2엔 불필요.
4. **로그인 성공 시 FCM 토큰 발급** — V1 `loginSuccess`는 토큰 저장 직후 `NotificationHelper.fetchFCMToken()`을 부른다. V2 인트로 흐름엔 안 보인다(푸시 권한은 "Home 진입 시점 별도"라고 문서화 — FCM 등록 시점이 어디로 옮겨졌는지 확인). → [1.6](#16-로그인-성공-라우팅)
   - **✅ 확정(2026-08-28, 조사): 인프라 존재·App 배선 대기(삭제 아님).** FCM 등록이 V1의 인라인 로그인 부수효과 → V2는 `NotificationDomain.RegisterDeviceTokenUseCase`(+`DefaultPushRepository`·엔드포인트 `/users/fcm-token`)로 분리됨. **호출부는 아직 미배선**(Feature·App grep 0) = App 부트스트랩 몫.
5. **온보딩 진입 분석 이벤트** — V1은 "둘러보기" 탭 시 `AmplitudeManager.track(...nonLogin)`을 남긴다. V2는 Amplitude 의존이 없고(외부 의존성 없음 원칙) 게스트 경로 자체가 없어 이벤트도 사라졌다. 분석 계측을 어디서 이어받는지 별개 확인. → [1.2](#12-둘러보기비로그인)
   - **➡️ 확정(2026-08-28): Amplitude 횡단 재도입으로 흡수.** 화면별 계약이 아니라 앱 전반 애널리틱스 부재 사안 → `docs/TODO.md` 9(Amplitude 횡단 재도입, 별도 이슈 승격)로 이관.

**🔧 눈에 띄는 개선 (근거 확인)**

6. **"건너뛰기"의 장르 처리가 바뀜** — V1 장르 단계의 "건너뛰기"는 **현재 선택된 장르를 그대로** 등록에 실어 보낸다(complete와 사실상 동일 경로). V2는 **선택을 무시하고 항상 빈 장르로** 등록한다(문서화된 설계). → [2.4](#24-장르-선택)
7. **프로필 등록 실패 표현** — V1은 `postUserProfile` 실패 시 **전면 네트워크 에러 뷰**를 띄우고, 그 뷰의 새로고침 버튼이 **토큰을 지우고 로그인 화면으로 튕긴다**. V2는 등록 실패를 **토스트**로 처리하고 버튼 재탭으로 재시도(문서화된 에러 표현 계약). → [2.5](#25-온보딩-완료-처리)
8. **진행바 구동 방식** — V1은 스크롤 오프셋에 연속적으로 물린 진행바, V2는 단계(step)에 물린 이산 진행바(스크롤 연동 진행바가 "어색하다"는 사용자 피드백으로 컨테이너 구조로 재작업). → [2.6](#26-단계-네비게이션진행바)

**🗑 눈에 띄는 삭제 (의도 확인)**

9. **"둘러보기(비로그인)" 게스트 진입** 통째 제거 — 로그인 화면 skip 버튼·게스트 홈 진입 + **로그인 유도 모달(InduceLogin)** 전부. (V2 `CLAUDE.md`에 "비로그인 경로 없음"으로 명문화 = 의도.) → [1.2](#12-둘러보기비로그인), [5](#5-로그인-유도-모달-induceloginv2-없음)
10. **카카오톡 앱 전환 우선 분기** — V1은 카카오톡 설치 시 앱 전환 로그인(`loginWithKakaoTalk`), 아니면 웹. V2는 **항상 웹**(`ASWebAuthenticationSession`, 문서화된 결정). → [1.3](#13-카카오-로그인)

(나머지는 대부분 ✅ Keep 또는 문서화된 🔧 Improve.)

---

## 1. 인트로 · 소셜 로그인 (Login → Intro)

원본: `…/Login/LoginViewModel/LoginViewModel.swift`, `.../LoginViewController/LoginViewController.swift`
V2: `Sources/Intro/OnboardingIntroView.swift`, `.../OnboardingIntroViewModel.swift`

### 1.1 배너 캐러셀

- ✅ **Keep** — 무한 순환 배너: **6장**(진짜 4장 `4,1,2,3` 양 끝에 반대편 복제 `4`·`1`를 붙임)으로 끝에서 반대편 실제 페이지로 되감아 순환처럼 보이게 하고, **2초마다 자동 전환**한다.
  - V2: 수단 변경(UIKit `UICollectionView` 무한스크롤 → SwiftUI `TabView` + 패딩 인덱스). 6-tag 복제 구조·2초 주기·도트 0~3 노출이 동일.
  - 근거: V1 `LoginViewModel.swift:23-29`,`75-96`,`173-183` · `LoginViewController.swift:157-214` · V2 `OnboardingIntroView.swift:110-121`,`197-206`,`37-43`
- ✅ **Keep** — 사용자가 직접 스와이프하면 자동 전환 주기가 **처음부터 다시** 시작된다(드래그 시작 시 자동스크롤 일시정지, 끝나면 재개).
  - V2: `scheduleAutoAdvance()`가 수동 스와이프 `onChange`에서 재호출돼 같은 효과(일시정지/재개 대신 "주기 리셋").
  - 근거: V1 `LoginViewController.swift:217-224`,`LoginViewModel.swift:173-183` · V2 `OnboardingIntroView.swift:66-74`,`195-206`

### 1.2 "둘러보기"(비로그인)

- 🗑 **Delete** — V1 로그인 화면엔 **skip 버튼**이 있어 탭하면 로그인 없이(토큰 없이) 홈으로 진입한다(게스트). `AmplitudeManager.track(nonLogin)`도 남긴다.
  - V2: **제거**. `LoginButtonType`에서 skip이 없고 소셜 버튼(카카오/애플)만 남는다. (`CLAUDE.md:11`에 "비로그인(게스트) 진입 경로는 없다 — 제품 결정으로 제거, 되살리지 말 것"으로 명문화 = 의도.)
  - 근거: V1 `LoginViewModel.swift:104-108`(skip→nonLogin track+navigateToHome), `LoginButtonType.swift:10-11` · V2 `OnboardingIntroView.swift:151-175`, `CLAUDE.md`(비로그인 경로 없음)
- ❓ **Unknown** — 온보딩/로그인 **분석 계측**(Amplitude). V1은 최소한 "둘러보기"에 `nonLogin` 이벤트를 심는다. V2는 Amplitude 의존이 없고(외부 의존성 없음 원칙) 게스트 경로도 없어 해당 이벤트가 사라졌다 — 다른 계측 수단으로 이어받는지, 온보딩 계측을 아예 미루는지는 별개 확인.
  - 근거: V1 `LoginViewModel.swift:106`(`AmplitudeManager.shared.track`) · V2 (Amplitude 미존재)

### 1.3 카카오 로그인

- ✅ **Keep** (관찰 동작) — 카카오 버튼 → 카카오 인증 → 서버 로그인. 성공 시 토큰 저장 후 라우팅(1.6).
  - V2: `UserApi.shared.loginWithKakaoAccount` → `SocialLoginUseCase(.kakao(accessToken:))`. 카카오 콜백 스레드를 명시적으로 메인으로 넘겨 `@MainActor handle` 호출.
  - 근거: V1 `LoginViewModel.swift:223-263`(`loginWithKakao`) · V2 `OnboardingIntroView.swift:230-241`
- 🗑 **Delete** — **카카오톡 앱 전환 우선 분기**. V1은 `UserApi.isKakaoTalkLoginAvailable()`이면 `loginWithKakaoTalk`(설치된 카카오톡 앱으로 전환), 아니면 `loginWithKakaoAccount`(웹).
  - V2: **항상 웹**(`loginWithKakaoAccount`, `ASWebAuthenticationSession`). (`CLAUDE.md:63`에 "웹 기반, KakaoTalk 앱 전환 아님 — 시뮬레이터에서도 동작"으로 명문화 = 의도.) 관찰 차이: 카카오톡 설치 유저의 로그인 경로가 앱 전환 → 웹 로그인으로 바뀐다.
  - 근거: V1 `LoginViewModel.swift:223-247`(KakaoTalk 분기) · V2 `OnboardingIntroView.swift:230-241`, `CLAUDE.md`(웹 기반 결정)

### 1.4 Apple 로그인

- ✅ **Keep** — 애플 버튼 → `ASAuthorizationController`로 `authorizationCode`+`idToken` 획득 → 서버 로그인.
  - V2: 시스템 `SignInWithAppleButton` 대신 **커스텀 원형 버튼 + `AppleSignInHandler`**가 `ASAuthorizationController`를 직접 구동(카카오와 같은 모양으로 맞추기 위함, 문서화). credential 파싱 후 `SocialLoginUseCase(.apple(...))`.
  - 근거: V1 `LoginViewModel.swift:207-213`,`266-285`(delegate) · V2 `OnboardingIntroView.swift:212-241`,`259-290`
- ❓ **Unknown** — **v1.4.0 애플 동기화 마이그레이션**. V1은 `needsAppleSyncV140`(accessToken이 캐시에 있고 아직 동기화 안 한 유저)면 일반 애플 로그인 대신 `syncAppleLoginState(authorizationCode:idToken:)`를 호출하고 완료 시 `appleReauthDoneV140` 플래그를 세운다.
  - V2: **대응 없음.** 특정 릴리즈 전환용 워크어라운드라 신규 클라이언트엔 불필요해 보이나, "삭제가 의도"라는 명문 근거는 못 찾음(누락된 유지일 가능성은 낮음).
  - 근거: V1 `LoginViewModel.swift:41-48`,`131-158`,`215-219` · `LoginViewController.swift:125-130`
  - **판정 포인트**: v1.4.0 마이그레이션 대상 유저가 V2로 넘어올 경로가 없다면 삭제가 자연스럽다(확인 필요).

### 1.5 v140 마이그레이션 워크어라운드

- ❓ **Unknown** — V1 로그인 화면은 `viewDidAppear`에서 `handleLoginCheckV140()`을 돌려, **이미 로그인된 상태 + `didEnterLoginV140` 미설정**이면 "로그인 확인이 필요합니다 / 앱 업데이트 이후 로그인 상태를 다시 확인하고 있습니다" 액션시트를 띄운다(업데이트 후 1회성).
  - V2: **대응 없음.** 1.4와 같은 v1.4.0 전환 워크어라운드 성격.
  - 근거: V1 `LoginViewController.swift:54-59`,`179-201`,`132-137` · V2 (대응 없음)

### 1.6 로그인 성공 라우팅

- ✅ **Keep** — 로그인 성공 시 **가입 완료 여부로 분기**한다: 기가입(`isRegister`) → 홈, 미가입 → 온보딩.
  - V2: `SocialLoginUseCase`가 `NeedOnboarding`을 반환 → `false`(기존 유저)면 완료 콜백(홈 진입은 App), `true`(신규)면 다음 단계. 의미가 `isRegister`의 반대(need onboarding)로 뒤집혔을 뿐 관찰 동작 동일.
  - 근거: V1 `LoginViewModel.swift:185-198`(`loginSuccess`) · `LoginViewController.swift:107-123` · V2 `OnboardingIntroViewModel.swift:100-109`, `OnboardingIntroView.swift:75-79`
- ✅ **Keep** — 토큰 영속화(accessToken·refreshToken·isRegister). V1은 VM이 직접 `UserDefaults`에 쓴다.
  - V2: **저장 책임이 Data/UseCase 레이어로** 내려감(Feature는 `NeedOnboarding`만 받음). 관찰 동작(로그인 후 세션 유지) 동일.
  - 근거: V1 `LoginViewModel.swift:186-191` · V2 `OnboardingIntroViewModel.swift:102`(UseCase 경유), `AuthDomain`
- ❓ **Unknown** — **FCM 토큰 발급**. V1 `loginSuccess`는 토큰 저장 직후 `NotificationHelper.shared.fetchFCMToken()`을 호출한다. V2 인트로 흐름엔 안 보인다.
  - V2: 푸시 권한 요청은 "Home 진입 시점 별도"라 문서화(`CLAUDE.md:64`) — FCM **등록** 시점이 어디로 이동했는지 확인 필요.
  - 근거: V1 `LoginViewModel.swift:192`(`fetchFCMToken`) · V2 `CLAUDE.md`(푸시 권한은 모듈 범위 밖)

### 1.7 로그인 재진입 가드

- ✅ **Keep** — 소셜 로그인 버튼 **더블탭/연타 방어**. V1은 모든 로그인 버튼(카카오/애플/skip)을 하나의 Observable로 합쳐 `.debounce(300ms)`로 제어한다.
  - V2: 수단 변경 — `state.isLoggingIn`로 `.disabled` + VM `loginTask == nil` 재진입 가드(디바운스 대신 "이미 로그인 Task가 떠 있으면 무시"). 관찰 동작(연타해도 한 번만 인증) 동일.
  - 근거: V1 `LoginViewModel.swift:101-116`(debounce) · V2 `OnboardingIntroViewModel.swift:80-87`, `OnboardingIntroView.swift:100`

---

## 2. 온보딩 스텝 플로우 (닉네임 → 성별/출생 → 장르)

원본: `…/Onboarding/Onboarding/OnboardingViewModel/OnboardingViewModel.swift`, `.../OnboardingViewController/OnboardingViewController.swift`
V2: `Sources/StepFlow/`(컨테이너) + `Nickname/`·`GenderBirthYear/`·`GenreSelection/`

> V1은 **한 VC 안 가로 스크롤**로 3단계를 담고 `stageIndex`(0/1/2)로 진행한다. V2도 **한 컨테이너**(`OnboardingStepFlowView`)가 세 단계 View를 `HStack`에 나란히 두고 `offset`으로 민다 — 구조 성격이 일치한다(둘 다 화면 전환이 아니라 컨테이너 내부 이동).

### 2.1 닉네임 — 형식 검증

- ✅ **Keep** — 실시간 형식 검증 상태 기계: 빈 값=미시작 / 공백 포함=`.whiteSpaceIncluded` / 패턴 위반=`.invalidCharacterOrLimitExceeded` / 통과=중복확인 필요(`unknown`/`needDuplicatedCheck`). 패턴 `^[a-zA-Z0-9가-힣]{2,10}$` **문자 그대로 동일**.
  - V2: 검증 로직이 **`ProfileDomain.NicknameDraft`(순수 계산 프로퍼티 `validationState`)로 이동** — 같은 패턴·같은 사유 enum(`whiteSpaceIncluded`/`invalidCharacterOrLimitExceeded`/`duplicated`/`notChanged`). V1은 텍스트 입력에 `.throttle(300ms)`를 걸었고 V2는 `setText`마다 동기 계산(관찰 동작 = 실시간 피드백 동일).
  - 근거: V1 `OnboardingViewModel.swift:19`,`129-134`,`293-313` · V2 `NicknameDraft.swift:27,30-57`, `NicknameViewModel.swift:74-75`
- ✅ **Keep** — 입력 **최대 10자** 제한.
  - V2: V1은 `UITextFieldDelegate.shouldChangeCharacters`로 10자에서 컷, V2는 `NicknameDraft.setText`가 `prefix(maxLength=10)`로 clamp. (⚠️ Feature `CLAUDE.md`의 "글자수 제한 TextField는 로컬 @State 2단계" 함정 참고 — 컴포넌트 `WSSNicknameField`가 흡수.)
  - 근거: V1 `OnboardingViewController.swift:283-289` · V2 `NicknameDraft.swift:26,89-95`
- ✅ **Keep** — 텍스트필드 내부 지우기(X) 버튼 → 텍스트 비우고 검증 상태 초기화.
  - V2: `WSSNicknameField`의 지우기 아이콘 → `.updateText("")` → `NicknameDraft`가 `.notStarted`로.
  - 근거: V1 `OnboardingViewModel.swift:151-156` · V2 `CLAUDE.md`(WSSNicknameField 트레일링 아이콘), `NicknameDraft.swift:30-33`

### 2.2 닉네임 — 중복확인 · 진행

- ✅ **Keep** — 중복확인은 **수동 탭 1회성**(자동 아님). 형식 통과(`unknown`/`needDuplicatedCheck`) 상태에서만 확인 버튼이 활성화되고, 텍스트가 바뀌면 확인 상태가 리셋돼 재확인을 요구한다.
  - V2: `checkDuplication`이 `validationState == .needDuplicatedCheck`에서만 서버 호출, `setText`가 `duplicationCheckState`를 `.notYet`으로 되돌림(도메인 정책). V1은 확인 탭에 `.debounce(300ms)`를 걸었으나 V2엔 없음(수동 1회라 불필요).
  - 근거: V1 `OnboardingViewModel.swift:136-141`,`158-164`,`315-345` · V2 `NicknameViewModel.swift:92-97`, `NicknameDraft.swift:44-48,89-95`
- ✅ **Keep** — "다음으로" 버튼은 **`available`(중복확인까지 통과)일 때만** 활성화되고, 닉네임을 **서버에 저장하지 않고 값만** 다음 단계로 넘긴다(최종 등록은 마지막 단계에서 한 번에).
  - V2: `proceed()`가 `validationState == .available` 가드, `confirmedNickname`에 값만 실어 컨테이너로 올림. V1도 이 단계에선 중복확인 GET만 하고 프로필 POST는 안 한다(끝에서 `postUserProfile`).
  - 근거: V1 `OnboardingViewModel.swift:139`,`231-242`(next→stage+1),`361-387`(끝에서 POST) · V2 `NicknameViewModel.swift:101-104`, `OnboardingStepFlowViewModel.swift:51-53`
- 🔧 **Improve** — **서버 에러 코드 → 사유 매핑 단순화**. V1은 중복확인 실패 응답의 코드를 파싱해 `USER-003`→공백, `USER-014`→"현재 사용 중"(notChanged), 그 외→형식오류로 나눴다.
  - V2: 서버 중복확인은 **가용/중복(Bool)만** 반환하고, 공백·형식 오류는 **로컬 검증(`NicknameDraft`)이 이미** 잡는다 → 서버가 사유를 세분화할 필요가 없어짐. `notChanged`는 온보딩(초기 닉네임 `""`)에선 발생하지 않는 사유라 사실상 무의미.
  - 근거: V1 `OnboardingViewModel.swift:326-343`,`347-359` · V2 `NicknameViewModel.swift:110-119`, `NicknameDraft.swift:30-51`, `ProfileDomain/CLAUDE.md`(validateNickname → Bool)
- 🔧 **Improve** (문구 조정) — **캡션 문구**가 온보딩 톤으로 갈렸다. V1 문구는 "사용 가능한 닉네임이에요"/"한글, 영문, 숫자 2~10자까지 입력 가능해요"/"공백은 포함될 수 없어요 "/"이미 사용 중인 닉네임이에요"/"현재 사용 중인 닉네임이에요".
  - V2: 검증 구조·조건은 같고 **한글 카피는 이 화면 워딩으로 별도 조정**(문서화 — `MyPageEditView`와 1:1 동기화 불필요).
  - 근거: V1 `NicknameAvailablity.swift:16-25,54-65` · V2 `CLAUDE.md`(닉네임 캡션 문구 갈림)

### 2.3 성별 / 출생년도

- ✅ **Keep** — 성별 칩 2개 선택 + 출생년도는 **피커 시트**에서 고른다. 피커는 값이 없으면 **시작 위치만 2000년**을 보여줄 뿐 미선택으로 취급하고, 시트에서 "완료"를 눌러야 값이 채워진다.
  - V2: `GenderBirthYearViewModel`(순수 입력 VM). V1은 출생년도를 `NotificationCenter("Birth")`로 받아오고 별점 피커는 `BirthPickerViewController(birth: value ?? 2000)`, V2는 `WSSBirthYearWheel` + 직접 바인딩(수단 변경).
  - 근거: V1 `OnboardingViewModel.swift:173,185-189` · `OnboardingViewController.swift:125-136,228-231` · V2 `GenderBirthYearViewModel.swift:22-31,58-60`, `CLAUDE.md`(피커 시작 2000, 미선택)
- ✅ **Keep** — "다음으로"는 **성별·출생년도 둘 다 선택**해야 활성화된다.
  - V2: `proceed()`가 `gender != nil && birthYear != nil` 가드(버튼도 같은 조건으로 비활성).
  - 근거: V1 `OnboardingViewModel.swift:175-183` · V2 `GenderBirthYearViewModel.swift:74-77`
  - ⚠️ V1 참고: 이 단계 next 활성 플래그는 **한번 true가 되면 다시 false로 안 내려간다**(`combineLatest`가 true만 accept). 선택 해제가 UI에 없어 실무상 드러나지 않는 잔버그. V2는 파생 조건으로 매번 재계산해 이 잔버그가 없다.
- ✅ **Keep** — 이 단계엔 **뒤로가기가 있다**(닉네임·약관과 달리). V1은 stage>0에서 back 버튼 노출, V2도 성별출생 단계에 뒤로가기 노출(닉네임 오탈자 수정 목적, 문서화).
  - 근거: V1 `OnboardingViewController.swift:276-280` · V2 `CLAUDE.md`(성별출생 뒤로가기 있음), `OnboardingStepFlowViewModel.swift:67-76`

### 2.4 장르 선택

- ✅ **Keep** — **다중 선택**(토글) + "완료"는 **하나 이상 선택했을 때만** 활성화.
  - V2: `Set<NovelGenre>` 토글, `complete()`가 `!isEmpty` 가드. V1은 `[NovelGenre]` 배열 토글, next 활성 = `!selectedGenres.isEmpty`.
  - 근거: V1 `OnboardingViewModel.swift:192-203` · V2 `GenreSelectionViewModel.swift:94-106`
- 🔧 **Improve** — **"건너뛰기"의 장르 처리**. V1의 skip 버튼은 `endOnboarding`으로 직행하고, 그 뒤 `postUserProfile`이 **현재 `selectedGenres.value`를 그대로** 실어 보낸다 → 사용자가 장르를 몇 개 고른 뒤 "건너뛰기"를 누르면 **고른 장르가 등록된다**(complete와 사실상 같은 결과).
  - V2: "건너뛰기"는 **선택을 무시하고 항상 빈 장르로 등록**한다(`register(genres: [])`). "선택하다 만 상태를 애매하게 반영하지 않기 위한 설계"로 문서화.
  - 근거: V1 `OnboardingViewModel.swift:205-211`(skip→endOnboarding),`372`(POST에 `selectedGenres.value`) · V2 `GenreSelectionViewModel.swift:109-112`, `CLAUDE.md`(건너뛰기 = 빈 장르)
- ✅ **Keep** — 장르 그리드가 곧 **온보딩 완료 트리거**다. "완료"/"건너뛰기" 둘 다 프로필 등록을 부르고 성공 시 완료로 넘어간다.
  - V2: `.complete`/`.skip` 둘 다 `RegisterProfileUseCase` 호출 → `isCompleted` → 컨테이너가 완료 화면으로. V1도 두 경로 모두 `endOnboarding → postUserProfile → moveToOnboardingSuccessViewController`.
  - 근거: V1 `OnboardingViewModel.swift:205-256`,`361-387` · V2 `GenreSelectionViewModel.swift:103-139`, `CLAUDE.md`(등록 성공 시 완료 화면 교체)

### 2.5 온보딩 완료 처리 (프로필 등록)

- ✅ **Keep** — 마지막에 **닉네임+성별+출생+선호장르를 한 번에** 서버에 등록한다.
  - V2: `ProfileRegistration(nickname:gender:birthYear:genrePreferences:)` → `RegisterProfileUseCase.execute`. V1은 `onboardingRepository.postUserProfile(...)`(`POST` 프로필). 요청 필드 동일(부록 A).
  - 근거: V1 `OnboardingViewModel.swift:361-387`, `OnboardingRepository.swift:38-46` · V2 `GenreSelectionViewModel.swift:123-139`
- ✅ **Keep** — 등록 **성공 시 로컬 프로필 저장**(성별·닉네임·가입완료 플래그) 후 완료 화면으로.
  - V2: `isRegister`/`userGender`/`userNickname` 영속화가 **Data 레이어로 이동**(UseCase가 담당). Feature는 `isCompleted`만.
  - 근거: V1 `OnboardingViewModel.swift:374-381`(UserDefaults 3종) · V2 `GenreSelectionViewModel.swift:134-135`, `ProfileDomain/CLAUDE.md`(로컬 저장은 Data)
- 🔧 **Improve** — **등록 실패 표현**. V1은 `postUserProfile` 실패 시 **전면 네트워크 에러 뷰**를 띄우고, 그 뷰의 새로고침 버튼(`networkErrorRefreshButtonDidTap`)은 **accessToken·refreshToken을 지우고 로그인 화면으로 루트 교체**한다(꽤 파괴적인 복구).
  - V2: 등록 실패는 **토스트**(`.unknownError`)로 알리고 버튼 재탭으로 재시도, 인증 만료만 `onAuthenticationRequired` 라우팅으로 분리(Feature `CLAUDE.md`의 "로드 실패 표현 계약" = 사용자 액션 실패는 토스트). 재로그인 튕김 없음.
  - 근거: V1 `OnboardingViewModel.swift:258-266,382-385` · V2 `GenreSelectionViewModel.swift:144-155`, `Feature/CLAUDE.md`(에러 표현·인증 만료 계약)
- ✅ **Keep** (구조적으로 자동 충족) — 등록 직전 **성별·출생 누락 가드**. V1은 `postUserProfile` 진입에서 gender/birth가 nil이면 `print` 후 조용히 return(no-op).
  - V2: 값들이 이전 단계에서 확정돼 `GenreSelectionViewModel` init에 **non-optional로** 주입되므로 nil 상태 자체가 컴파일 단계에서 불가능 → 가드가 필요 없다.
  - 근거: V1 `OnboardingViewModel.swift:361-366` · V2 `GenreSelectionViewModel.swift:51-73`(non-optional 주입)

### 2.6 단계 네비게이션 · 진행바

- ✅ **Keep** — **뒤로가기는 1단계(닉네임)에서 숨김, "건너뛰기"는 마지막 단계(장르)에서만** 노출.
  - V2: 컨테이너 헤더가 step==nickname에서 뒤로가기 숨김, genreSelection에서만 "건너뛰기" 표시. V1은 `setNavigationBar(stage:)`가 stage0에서 back 숨김·stage2에서만 skip 표시.
  - 근거: V1 `OnboardingViewController.swift:276-280` · V2 `OnboardingStepFlowView.swift:104-139`
- ✅ **Keep** — 뒤로가기·다음은 **화면 이탈이 아니라 컨테이너 내부 단계 이동**이고, 뒤로 갔다 와도 **입력값이 보존**된다.
  - V2: 세 단계 View를 `HStack`에 동시 생성해 `offset`으로 밀고(`.clipped()`), 닉네임/성별출생 VM을 **컨테이너가 소유·재사용**(뒤로 가도 값 유지). V1도 한 스크롤뷰 안이라 stage를 오가도 각 stage view의 입력이 남는다.
  - 근거: V1 `OnboardingViewController.swift:260-274`(가로 스크롤 이동) · V2 `OnboardingStepFlowView.swift:152-183`, `CLAUDE.md`(단계 재사용·슬라이드)
- 🔧 **Improve** — **진행바 구동 방식**. V1은 스크롤 오프셋에 **연속적으로** 물린 진행바(`progressOffset = screenWidth - (offset.x + screenWidth)/3`).
  - V2: 단계(step)에 물린 **이산** 진행바(`OnboardingStepProgressBar`). "스크롤 연동 진행바 애니메이션이 어색하다"는 사용자 피드백으로 컨테이너 구조로 재작업(문서화).
  - 근거: V1 `OnboardingViewModel.swift:244-250`, `OnboardingViewController.swift:170-174` · V2 `Sources/Component/OnboardingStepProgressBar.swift`, `CLAUDE.md`(컨테이너 재작업 이유)
- ✅ **Keep** — 단계 이동 **더블탭/연타 가드**. V1은 next/back/skip에 각각 `.throttle(1s)`.
  - V2: 진행 신호는 `nil→값` 전이 소진 패턴(중복 확정 무시) + 마지막 단계는 `isSubmitting` 동안 뒤로가기/건너뛰기 `.disabled`(진행 중 서버 호출과 겹침 방지, 문서화). 수단 변경.
  - 근거: V1 `OnboardingViewModel.swift:205-206,220-221,231-232` · V2 `OnboardingStepFlowView.swift:124,139`, `CLAUDE.md`(consumeConfirmation·isSubmitting 가드)
- ✅ **Keep** (수단 변경) — 배경 탭 시 키보드 내림. V1은 `touchesBegan`에서 `endEditing(true)` + 단계 이동 시 `view.endEditing(true)`.
  - V2: SwiftUI 기본 처리(단계 슬라이드 시 포커스 이탈). 관찰 동작(키보드 정리) 유지.
  - 근거: V1 `OnboardingViewController.swift:57-59,178,185` · V2 (SwiftUI)

---

## 3. 가입약관 동의 시트 (ServiceTermAgreement → TermsAgreement)

원본: `…/Base/ServiceTermAgreement/ServiceTermAgreementViewController.swift`(**VM 없음, 로직이 VC에**), `.../ServiceTerm.swift`
V2: `Sources/TermsAgreement/TermsAgreementView.swift`, `.../TermsAgreementViewModel.swift`

### 3.1 노출 조건

- ❓ **Unknown (헤드라인)** — V1은 온보딩 진입(`viewDidLoad`)에서 `userRepository.getTermSetting()`을 조회해 **`!isAllRequiredTermsAgreed`일 때만** 약관 시트를 present한다(이미 동의한 유저면 안 띄움).
  - V2: 약관을 **별도 온보딩 스텝 시트**로 두는데, "이미 동의했으면 건너뛴다"는 게이팅이 **Feature에 없다**(순서·조건부 노출은 App 배선 몫으로 보임). `TermsAgreementViewModel.load()`는 항상 초안을 로드해 현재 동의 상태를 그려줄 뿐, 스텝 자체를 건너뛰진 않는다.
  - 근거: V1 `OnboardingViewModel.swift:389-401`(getTermSetting), `OnboardingViewController.swift:205-209` · V2 `TermsAgreementViewModel.swift:104-108,130-142`
  - **판정 포인트**: 기가입/약관동의 완료 유저가 온보딩을 다시 밟을 때 약관을 또 보이는지(회귀) / 항상 보이는 게 의도인지(App이 게이팅).
- 🔧 **Improve** — **필수 단계 강제(닫기 금지)**. V1은 약관 화면을 `presentModalViewController`로 띄워 **스와이프/바깥 탭으로 닫힐 수 있었다**(기본 modal). 닫아도 강제 재노출 로직이 없다.
  - V2: `.interactiveDismissDisabled()`로 스와이프/바깥 탭 닫기를 막는다(필수 단계, 사용자 확정·문서화). 그래버도 숨김.
  - 근거: V1 `OnboardingViewController.swift:205-209`(present) · V2 `CLAUDE.md`(interactiveDismissDisabled 필수)

### 3.2 동의 토글

- ✅ **Keep** — **"전체 동의" 행은 토글형**: 전부(필수+선택) 이미 동의면 탭 시 전부 해제, 아니면 전부 동의.
  - V2: `toggleAgreeAll()` 동일 로직. V1은 `agreedTerms.count == allCases.count`로 판단.
  - 근거: V1 `ServiceTermAgreementViewController.swift:53-59` · V2 `TermsAgreementViewModel.swift:110-118`
- ✅ **Keep** — 개별 약관 토글(체크/해제).
  - V2: `.toggleAgreement(type)`.
  - 근거: V1 `ServiceTermAgreementViewController.swift:61-77` · V2 `TermsAgreementViewModel.swift:89-90`
- ✅ **Keep** — "다음으로" 활성화 조건 = **필수 항목만 전부 동의**(마케팅=선택은 무관).
  - V2: `TermsAgreementDraft.isSubmittable`(필수만) 그대로. V1은 `requiredTermsAllAgreed` 계산.
  - 근거: V1 `ServiceTermAgreementViewController.swift:113-114` · V2 `CLAUDE.md`(isSubmittable), `TermsAgreementView`
- ✅ **Keep** — 필수/선택 구분: **서비스 이용약관·개인정보 = 필수, 마케팅 = 선택**.
  - V2: `TermsType`(SettingDomain) 동일 구분.
  - 근거: V1 `ServiceTerm.swift:28-37` · V2 `CLAUDE.md`(필수 항목), `SettingDomain.TermsType`

### 3.3 상세 약관 링크 · 저장

- ✅ **Keep** — 밑줄 텍스트(서비스 이용약관·개인정보) 탭 → **외부 브라우저로 상세 약관 URL** 열기. 마케팅(선택)은 상세 URL이 없어 탭 대상 아님.
  - V2: `TermsType.detailURL`(View 로컬)이 `BaseDomain.AppURL.serviceAgreement`/`.privacyPolicy`(노션)로 `openURL`. V1은 `ServiceTerm.connectedURLString`의 노션 링크.
  - 근거: V1 `ServiceTermAgreementViewController.swift:79-89`, `ServiceTerm.swift:50-59` · V2 `CLAUDE.md`(밑줄 텍스트 openURL)
- ✅ **Keep** — 저장은 **"다음으로" 탭 시 1회**(개별 토글은 로컬만, 서버 호출 없음). V1은 `patchTermSetting`으로 3개 Bool을 한 번에 PATCH.
  - V2: `saveUseCase.execute(draft:)` 1회(입력 폼 패턴, `NovelReview` 정본). 성공 시 다음 단계 신호(`shouldProceed`).
  - 근거: V1 `ServiceTermAgreementViewController.swift:91-98,128-145` · V2 `TermsAgreementViewModel.swift:121-124,144-154`
- 🔧 **Improve** — **로드/저장 실패 분화**. V1 약관 화면은 **초안 로드가 없다**(agreedTerms를 빈 `[]`로 시작), 저장 실패도 `print`만 하고 조용히 삼킨다(사용자에게 표현 없음).
  - V2: 초안을 서버에서 로드(`LoadTermsAgreementDraftUseCase`)하고 **로드 실패 = 전면 `NetworkErrorView`+재시도**, 저장 실패 = 토스트로 분화(NovelReview 정본 계승). 인증 만료는 로그인 라우팅.
  - 근거: V1 `ServiceTermAgreementViewController.swift:20`(빈 시작),`136-143`(실패 print) · V2 `TermsAgreementViewModel.swift:130-171`, `CLAUDE.md`(로드 실패 전면 뷰)

---

## 4. 계약 완료 (OnboardingSuccess → Complete)

원본: `…/Onboarding/OnboardingSuccess/OnboardingSuccessViewController/OnboardingSuccessViewController.swift`
V2: `Sources/Complete/OnboardingCompleteView.swift`

- ✅ **Keep** — **닉네임 인사 + CTA 버튼 → 홈 진입**. 등록 성공 직후 곧장 홈으로 튀지 않고 이 완료 화면을 한 번 보여주고, CTA를 눌러야 홈으로.
  - V2: `OnboardingCompleteView`(순수 표시 — VM·UseCase 없음, 닉네임 문자열 + `onStart` 콜백만). 컨테이너가 `isRegistrationCompleted` 플래그로 body를 이 화면으로 교체하고, CTA(`웹소소 시작하기`)가 `onCompleted` 발화(홈 진입은 App). V1은 `completeButton` → `setRootToWSSTabBarController`(직접 홈 루트 교체).
  - 근거: V1 `OnboardingSuccessViewController.swift:57-78` · V2 `OnboardingCompleteView.swift:20-64`, `OnboardingStepFlowView.swift:81-82`, `CLAUDE.md`(완료 화면 교체)
- ✅ **Keep** — 완료 화면은 네비바/진행바 없음(전체 화면).
  - V2: 슬라이드 단계에 안 넣고 body 최상위 교체(진행바·뒤로가기 없음, Figma에도 없음).
  - 근거: V1 `OnboardingSuccessViewController.swift:49-53`(navbar hidden) · V2 `CLAUDE.md`(완료 화면 진행바·뒤로가기 없음)

---

## 5. 로그인 유도 모달 (InduceLogin — V2 없음)

원본: `…/Base/InduceLogin/InduceLoginViewController.swift`, `.../InduceLoginView.swift`

- 🗑 **Delete** — V1엔 **게스트(비로그인) 사용자에게 로그인을 유도하는 모달**이 있었다: "로그인하고 모든 기능을 자유롭게 사용하세요!" + "로그인 하러가기"(→ 로그인 화면 루트 교체) + "닫기"(dismiss). 게스트가 로그인 필요 기능을 만졌을 때 뜬다.
  - V2: **대응 화면 없음.** 게스트 진입 경로 자체를 제거했으므로(1.2, `CLAUDE.md:11`) 유도 모달도 존재 이유가 없다 = 의도된 삭제.
  - 근거: V1 `InduceLoginViewController.swift:45-60`, `InduceLoginView.swift:66-92`, `StringLiterals+Home.swift:29-31` · V2 (게스트 경로 제거)

---

## 부록 A. 서버 요청 파라미터 매핑 (C2 비교 재료)

### 프로필 등록 `postUserProfile` → `POST /users/profile`

| 필드 | V1 전송 | V2 전송 | 상태 |
|---|---|---|---|
| `nickname` | `String` (중복확인 통과값) | `ProfileRegistration.nickname` | ✅ Keep |
| `gender` | `OnboardingGender.rawValue` (`"M"`/`"F"`) | `Gender` (rawValue 매핑은 Data) | ✅ Keep (값 동일성 확인 권장) |
| `birth` | `Int` (출생년도) | `BirthYear.value` | ✅ Keep |
| `genrePreferences` | `[NovelGenre].map { $0.rawValue }` | `[NovelGenre]` (영문 토큰 매핑 Data) | ✅ Keep |

- 근거: V1 `OnboardingRepository.swift:38-46`, `OnboardingService.swift:46-66`(`URLs.Onboarding.postProfile`) · V2 `GenreSelectionViewModel.swift:126-131`, `ProfileData`(매핑)

### 닉네임 중복확인 `getNicknameisValid` → `GET /nicknames`(쿼리 `nickname`)

| 항목 | V1 | V2 | 상태 |
|---|---|---|---|
| 요청 | `GET` + `nickname` 쿼리 + accessToken 헤더 | 동일(ProfileData) | ✅ Keep |
| 응답 해석 | `OnboardingResponse.isValid`(true=사용가능) | `NicknameValidationResponse.isValid` → `Bool` | ✅ Keep |
| 실패 사유 세분 | 서버 코드 `USER-003`/`USER-014` 파싱 | 로컬 검증이 흡수, 서버는 가용/중복만 | 🔧 Improve (2.2) |

- 근거: V1 `OnboardingService.swift:20-44` · V2 `ProfileDomain/CLAUDE.md`(validateNickname→Bool), `ProfileData`

### 약관 설정 `patchTermSetting` → 약관 동의 PATCH

| 필드 | V1 | V2 | 상태 |
|---|---|---|---|
| serviceAgreed | `Bool` (필수) | `TermsAgreementDraft`(SettingDomain) | ✅ Keep |
| privacyAgreed | `Bool` (필수) | 동일 | ✅ Keep |
| marketingAgreed | `Bool` (선택) | 동일 | ✅ Keep |
| 저장 시점 | "다음으로" 탭 1회 | `saveUseCase.execute` 1회 | ✅ Keep |

- 근거: V1 `ServiceTermAgreementViewController.swift:128-145`, `UserRepository/UserInfoRepository.swift`(patchTermSetting) · V2 `TermsAgreementViewModel.swift:144-154`, `SettingDomain`
</content>
</invoke>
