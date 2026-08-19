# App 레이어

앱 진입점. **의존성 주입(DI)과 전역 흐름 조립**을 담당한다. 비즈니스 로직은 두지 않는다.

- 디렉토리: `Projects/App/`
- 비동기/상태: SwiftUI App lifecycle

## 구성

```
Sources/
├── WSSIOSV2App.swift        # @main. 폰트 등록·KakaoSDK 초기화 등 앱 시작 시 1회 처리.
├── ContentView.swift        # 앱 루트. AppDependencies를 한 번 만들어 두 플로우에 내려주고,
│                             # Route(.onboarding/.main)로 전환한다(로그인 상태 분기는 여기).
├── DI/
│   └── AppDependencies.swift  # 유일한 조립 지점 — NetworkingClient·TokenStore·Repository 조립.
├── Onboarding/
│   └── OnboardingRootView.swift  # 온보딩 플로우 배선(OnboardingFactory 호출 + 화면 전환).
│                                  # 끝나면(기존 유저 로그인 / 온보딩 완료) onFinished()만 부른다 —
│                                  # 어디로 갈지는 정하지 않고 ContentView에 위임.
├── Main/
│   └── MainTabView.swift     # 온보딩 이후 루트 — 홈/피드/서재/My 4탭 TabView. 탭 아이콘은
│                              # DesignSystem의 Icons/Tabbar 에셋(icNavigateHome 등).
├── Home/    └── HomeRootView.swift      # "홈" 탭. HomeFactory 조립 + 작품 상세·피드 상세·일반 검색·
│                                          # 마이페이지 편집(NovelDetailAssembly/FeedFeatureFactory/
│                                          # SearchAssembly/MypageFactory)까지 실제 push.
├── Feed/    └── FeedRootView.swift      # "피드" 탭. FeedFeatureFactory.makeSosoFeedView 조립 + 피드 상세·
│                                          # 작품 상세·피드 작성·타유저 프로필·그 프로필의 타유저 서재
│                                          # (makeFeedDetailView/NovelDetailAssembly/makeCreateFeedView/
│                                          # UserPageAssembly/LibraryFactory.makeUserLibraryView)까지 push.
├── Library/ └── LibraryRootView.swift   # "서재" 탭. LibraryFactory.makeMyLibraryView 조립 + 작품 상세·
│                                          # 일반 검색·알림 설정(NovelDetailAssembly/SearchAssembly/
│                                          # SettingFactory.makeNotificationSettingView)까지 push.
├── Mypage/  └── MypageRootView.swift    # "My" 탭. UserPageFeature의 MypageFactory.makeView 조립 +
│                                          # 프로필 편집·설정(makeEditView/SettingFactory.makeView)까지
│                                          # push, 서재 블록 탭은 push가 아니라 MainTabView 탭 전환으로
│                                          # 위임(모듈명과 Factory 이름이 다르니 혼동 주의).
├── Novel/   └── NovelDetailAssembly.swift  # 작품 상세 조립 공용 헬퍼 — 홈/피드/서재 3탭이 공유(아래).
├── Search/  └── SearchAssembly.swift       # 일반 검색 조립 공용 헬퍼 — 홈/서재가 공유(아래).
└── UserPage/└── UserPageAssembly.swift     # 타유저 프로필 조립 공용 헬퍼 — 지금은 피드 탭만 소비.
```

4탭 콘텐츠 자체(각 Factory의 메인 화면)는 전부 실제 UseCase로 조립돼 있다. 그 안에서 열리는 2차
화면은 **홈·피드·서재·My가 상당수 실제로 뚫려 있고**(작품 상세·피드 상세·일반 검색·프로필 편집·
알림 설정), 나머지는 대상 Feature 모듈이 App에 아직 안 붙어 있어 로그만 남기는 placeholder
콜백이다 — 대상 모듈을 붙일 때 그 콜백 하나만 바꾸면 된다.
- ⚠️ **`FeedRootView.onUserProfileTapped`는 push 직전 `currentUserID`(로컬 캐시)와 대상 `userID`를
  한 번 더 비교해 같으면 무시한다**(#196) — `TotalFeed.isMyFeed` 기반으로 Feature(`SosoFeedView`)가
  이미 내 프로필 탭 자체를 막아두지만(`isProfileTappable`), "내 프로필이 타유저 프로필 화면으로
  넘어간다"는 증상이 실제로 보고돼(소소피드 탭처럼 `isMyFeed`가 서버 응답에 의존하는 목록에서
  그 값이 어긋날 여지가 있음) **라우팅이 실제로 일어나는 지점(App)에도 같은 가드를 이중으로
  걸었다** — Feature/서버 쪽 판단과 무관하게 여기서 한 번 더 막아야 확실하다. `currentUserID`는
  `FeedDetailAssembly.currentUserID`와 같은 출처(`UserDefaultsStorage().get(.userID)`, 로그인 직후
  캐시)를 쓴다. 다른 탭에 유저 프로필 진입을 추가할 때도 이 가드를 같이 걸 것.
- ⚠️ **탭 Root의 `NavigationPath`(`path`)와 그 아래 Feature가 로컬 `@State` + `.navigationDestination(item:)`로 직접 push한 화면을 섞으면, 그 로컬 화면이 스택에서 사라진다.** `SearchAssembly`의 상세탐색 결과 화면(`makeDetailSearchResultView`)이 실제로 이 버그였다(#196) — 자세한 증상·원인·고친 방법은 `SearchFeature/CLAUDE.md`의 동일 항목 참고. 교훈: **App이 소유한 `path` 아래에서 "또 다른(특히 다른 모듈) 화면으로 더 나아가야 하는" 중간 화면은, 그 화면 자신의 push까지도 처음부터 App의 `path`를 타야 한다** — Assembly 패턴을 늘릴 때(새 공용 헬퍼를 뽑을 때) 그 화면이 "막다른 끝"인지 "또 뻗어나가는 중간 지점"인지 먼저 판단할 것.
- **작품 상세·일반 검색·타유저 프로필 조립은 `NovelDetailAssembly`/`SearchAssembly`/`UserPageAssembly`
  (전부 `@MainActor enum`)로 공용화돼 있다**(#196, 3번째 탭이 같은 목적지를 필요로 한 시점에 뽑는
  패턴 — `UserPageAssembly`는 아직 소비자가 피드 탭 하나뿐이지만 같은 이유로 미리 뽑아둠) — 각 탭 Root는 자기
  `Destination` enum에 맞는 push 클로저(`onNovelTapped`/`onFeedTapped`/`onNovelSelected`)와
  `onAuthenticationRequired`만 넘기면 된다. **새 탭 Root가 작품 상세나 일반 검색을 push해야 하면
  이 공용 헬퍼부터 재사용할 것** — `NovelDetailFactory.makeView`/`SearchFactory.makeView`를 직접
  다시 호출해 복제하지 말 것. 반대로 `onFeedTapped`처럼 그 탭에 대응 `Destination` case가 없으면
  placeholder 로그로 넘기면 된다(`LibraryRootView`가 실제로 그렇게 함 — 서재는 피드 상세로 갈
  이유가 없어서).
- ⚠️ **`ContentView.body`에 `.preferredColorScheme(.light)`를 걸어 앱 전체를 라이트모드로 고정한다**
  (사용자 확정, #197) — `DesignSystem`의 색상 에셋(`WSSColor.wssWhite` 등)이 전부 다크 배리언트 없는
  고정값이라, 시스템이 다크모드면 화면마다 명시적으로 `.background(...)`를 안 건 자리(대부분의
  화면)만 시스템 기본 배경(검정)으로 비쳐 보인다(설정 화면에서 실측). 화면마다 배경색을 개별로
  추가하는 대신, 애초에 다크모드로 진입 자체를 막는 쪽을 택했다 — 새 화면을 추가해도 이 문제가
  재발하지 않는다. `DesignSystem`이 나중에 실제로 다크모드를 지원하게 되면 이 줄부터 지울 것.
- **원칙: 화면 간 연결 조립은 무조건 App이 한다**(사용자 확정, #196) — Feature 안에 "다른 화면으로
  이동하는 로직"(다른 Feature의 View를 직접 구성해 push/present)이 있으면 안 된다. Feature는 콜백
  (`onNovelSelected`, `onEditProfileTapped` 등)만 밖으로 노출하고, 실제로 그 콜백을 받아 화면을
  조립하는 건 전부 App의 각 탭 Root가 한다(`MypageView`→`MyPageEditView` 전환을 이 원칙에 맞춰
  App으로 옮긴 사례 참고, `UserPageFeature/CLAUDE.md`).
  - **예외**: 다른 화면으로의 "이동"이 아니라 **그 화면 자신의 로컬 상태(draft)를 채우는 값
    선택기**(피커류 시트 — 예: 마이페이지 편집의 캐릭터 선택 시트)는 Feature 안에 남겨도 된다.
    App으로 올리면 결과를 다시 그 화면 내부로 넣어주는 `Binding` 왕복이 필요해져 오히려 더
    꼬이기 때문(사용자 확정) — "화면"인지 "이 화면의 로컬 모달"인지로 구분해서 판단할 것.

## 책임

- 앱 진입점(`@main`), 전역 환경 구성.
- 각 레이어 조립 — Data 구현체와 Domain 프로토콜이 만나는 **유일한 지점**.
- 화면 전환·딥링크 등 전역 흐름 조정.

## 의존 규칙

- ✅ Feature, Domain, Data(Factory), Core, UI — 조립을 위해 거의 모든 레이어를 알 수 있다.
- App은 의존성 그래프의 최상위이므로 누구도 App을 import 하지 않는다.

## 조립 패턴 (`AppDependencies`, #196에서 확정)

```swift
let repository = XxxDataFactory.makeXxxRepository(client:...)  // Data 구현체
let useCase    = DefaultXxxUseCase(repository: repository)     // Domain 프로토콜에 주입
let view       = XxxFactory.makeView(someUseCase: useCase)     // Feature에 전달
```

- **DI는 클래스(`AppDependencies`) 하나로 모은다**, View 안에서 낱개로 조립하지 않는다. 루트 View가
  `@State private var dependencies = AppDependencies()`로 한 번만 만들어 들고, 화면 전환마다 그 안의
  Repository로 UseCase를 즉석 생성해 Factory에 넘긴다(UseCase 자체는 가벼운 struct/class라 매번
  새로 만들어도 무방 — Repository/NetworkingClient/TokenStore만 공유되면 된다).
- **`NetworkingClient`는 2개**(무한 재귀 방지, `AuthData/CLAUDE.md` 경고 그대로 적용):
  - `refresherClient` — `authSessionRefresher`를 물리지 않은 client. `AuthDataFactory.makeSessionRefresher`
    전용으로만 쓴다.
  - `client` — 위에서 만든 refresher를 `authSessionRefresher:`로 물린 메인 client. 실제 API 호출은
    전부 이걸로 나간다.
  - 둘 다 같은 `DefaultTokenStore()`(Keychain)를 공유해야 갱신된 토큰이 바로 반영된다.
- 로그인 성공 시 토큰 저장은 **Data 레이어(`DefaultAuthRepository.login`)가 이미 처리**한다 — App은
  `TokenStore`를 만들어 Repository에 주입하기만 하면 된다(App이 직접 Keychain을 만지지 않음).
- **키워드는 `AppDependencies.init()` 마지막에 `Task { await keywordRepository.syncKeywords() }`로
  앱 실행(프로세스 시작)마다 1회 동기화한다**(#196) — 여러 도메인(서재 필터·프로필 취향·검색 등)이
  키워드를 **로컬 파일 캐시**(`KeywordCache`)에서만 읽는 구조라(`BaseData/CLAUDE.md`), 이 동기화가
  한 번도 안 불리면 그 화면들이 전부 빈 목록으로 보인다. `syncKeywords()`는 내부에서 실패를 전부
  삼키고 로깅만 하는 계약(throws 없음)이라 App도 결과를 기다리거나 에러 처리를 하지 않는다 —
  `dependencies` 조립과 동시에 백그라운드로 쏘고 화면 진입은 막지 않는 fire-and-forget.

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ **`Support/Info.plist`는 Tuist `.extendingDefault(with:)`가 아니라 `.file(path:)`로 직접 지정**돼 있어
  (Feature Demo 앱들과 달리 `ModuleInfoPlist` 헬퍼를 안 씀), Xcode가 표준으로 자동 채워주는
  `CFBundleIdentifier`/`CFBundleExecutable`이 **없으면 시뮬레이터 설치 자체가 실패**한다
  (`Missing bundle ID` → `missing or invalid CFBundleExecutable`, #196에서 실측). 이 plist에 새 키를
  추가할 땐 표준 키가 여전히 살아있는지 함께 확인할 것 — 지우면 조용히 안 죽고 빌드는 되는데 설치가 깨진다.
- **Apple 로그인 버튼은 시뮬레이터에 Apple ID가 로그인돼 있으면 시스템 계정 선택/Face ID 시트로,
  없으면 설정 앱의 "Apple 계정" 화면으로 튄다**(둘 다 정상 — `OnboardingFeature/CLAUDE.md` 참고).
  Kakao 로그인은 `kauth.kakao.com` `ASWebAuthenticationSession` 동의 시트가 뜨는 게 정상(실측,
  시뮬레이터에서도 동작) — 취소하면 `.loginFailed` → "알 수 없는 에러가 발생했어요" 토스트로 낙착.
- **온보딩 완료(`OnboardingRootView.handleOnboardingCompleted`)·기존 유저 로그인 둘 다 `onFinished()`
  하나로 수렴**해 `ContentView`가 `route = .main`으로 전환한다 — 신규/기존 유저를 구분해 다른 곳으로
  보낼 이유가 아직 없어서 일부러 하나로 합쳤다. 나중에 갈림이 필요해지면(예: 신규 유저만 튜토리얼)
  `onFinished`를 매개변수 있는 콜백으로 바꿀 것.
- **각 탭 Root의 화면 전환 콜백 중 상당수는 이미 실제 push로 뚫려 있다**(작품 상세·피드 상세·일반
  검색·프로필 편집·설정·타유저 프로필·알림 설정) — 남은 건 대상 Feature 모듈이 App에 아직 안 붙어
  있어 로그만 남기는 placeholder다(예: `HomeRootView`의 상세탐색·알림 목록). 그 모듈을 붙일 때 해당
  콜백 하나만 실제 화면 전환으로 바꾸면 된다(전부 한 번에 바꿀 필요 없음). **`SosoFeedView`의 피드
  셀은 연결 작품 배너(`onNovelTapped`)·작성자 프로필(`onUserProfileTapped`)까지 전부 실제 push다**
  (#196) — `FeedRootView`가 전자는 같은 `Destination.novel`로, 후자는 `Destination.userPage` →
  `UserPageAssembly`로 연결한다.
  - ⚠️ **`NovelID`와 `FeedID`는 둘 다 `IDWrapper<Int>` 타입 별칭이라 실제로는 같은 타입이다** —
    `NavigationPath`에 그냥 섞어 넣거나 `.navigationDestination(for: NovelID.self)` +
    `.navigationDestination(for: FeedID.self)`를 따로 등록하면 타입이 겹쳐 의도대로 라우팅되지 않는다.
    `HomeRootView.Destination` 같은 래퍼 enum으로 명시적으로 태깅해서 push할 것 — 다른 탭 Root에
    같은 방식의 push 네비게이션을 추가할 때도 이 함정을 반복하지 말 것.
  - **탭에서 push된 화면은 탭바를 가린다**(`.toolbar(.hidden, for: .tabBar)`, 사용자 확정) — `.navigationDestination(for:)`
    클로저 안, `switch` 결과를 감싸는 자리 한 곳에 걸어둬서 `Destination` case가 늘어나도 매번 개별
    목적지 뷰에 반복해서 붙일 필요가 없다. 다른 탭 Root에 push 네비게이션을 추가할 때 이 자리도 같이 만들 것.
- ⚠️ **My(`MypageRootView`)는 `onAuthenticationRequired`를 받지만, 다른 탭과 발화 경로가 다르다.**
  `MypageFactory.makeView`/`.makeEditView` 자체는 여전히 그 콜백을 모른다 — 즉 마이페이지 로드(프로필·
  장르·서재 통계) 401은 여전히 조용히 빈 상태로 남는다(App 쪽에서 고칠 수 있는 게 아니라
  `UserPageFeature` 쪽에 콜백이 먼저 추가돼야 함, Feature/CLAUDE.md "인증 만료 처리 계약" 참고). 다만
  `MainTabView`는 `MypageRootView`에도 이 콜백을 내려주는데, **용도는 401이 아니라 설정 화면의
  회원탈퇴/로그아웃 성공**이다 — `MypageRootView`가 push하는 `SettingFactory.makeView`의
  `onWithdrawSuccess`/`onLogoutSuccess`를 그대로 이 콜백에 물려, 세션을 끝내는 두 이벤트가 다른 탭의
  401 만료와 같은 경로(온보딩으로 라우팅)를 타게 한다. **Home·Feed·서재 세 탭은 여전히 401 경로로만
  쓴다**(Feed는 탭 콘텐츠 자체(`makeSosoFeedView`)는 못 받지만, 거기서 push하는 작품 상세
  (`NovelDetailAssembly`)는 받아서 전달한다 — `FeedRootView` 참고).
- **`onAuthenticationRequired`는 메인→온보딩으로 라우팅을 되돌리는 것까지만 하고, 로그아웃 처리
  (토큰 삭제 등)는 하지 않는다** — 401을 받은 시점에 이미 서버가 세션을 무효화한 상태라 재로그인하면
  새 토큰으로 덮어써진다. 별도 로그아웃 로직이 필요해지면 `AuthRepository.logout()`을 여기서 호출할지
  검토할 것. 어느 탭에서 발생했든(`MainTabView`가 Home/Feed/Library 세 곳의 콜백을 같은 클로저로 받음)
  idempotent해야 한다는 계약은 그대로 유지.
- ⚠️ **`DesignSystem` 에셋을 탭바 아이콘처럼 이름 문자열로 참조하면(`Label(_:image:)`) 완전히 새로
  설치한 상태에서 아이콘이 조용히 안 보인다** — 그 이미지는 App이 아니라 `DesignSystem.framework`
  자체의 리소스 번들에 있는데, `Label(_:image:)`/`Image(_:)`(이름 문자열 버전)는 기본적으로
  `Bundle.main`만 뒤진다. 기존 앱이 남아있는 상태로 재설치하면 우연히 그전 바이너리가 남아 있어
  증상이 안 보일 수 있다(실측 — 처음엔 이 캐시 때문에 못 잡았다) → **아이콘류는 항상
  `WSSImage.icXxx.swiftUIImage`(제네레이터가 `Bundle.module`로 만든 `Image`)로 참조할 것**,
  이름 문자열 기반 API는 쓰지 않는다. 검증할 땐 `xcrun simctl uninstall`로 완전히 지운 뒤 재설치해서
  볼 것 — 증분 재설치는 이 종류의 버그를 가린다.
- **탭바 선택/비선택 색(아이콘+글씨, wssBlack/wssGray200)은 `WSSIOSV2App.configureTabBarAppearance()`
  (`UITabBar.appearance()`)에서 앱 시작 시 1회 설정한다** — SwiftUI `TabView`가 iOS 17 기준 비선택
  색을 지정하는 공개 API를 안 줘서 UIKit 어피어런스 프록시가 유일한 방법이다. `MainTabView`의 아이콘은
  `.renderingMode(.template)`을 걸어야 이 `iconColor` 틴트가 실제로 적용된다(에셋 자체의
  `template-rendering-intent`가 "original"이라 안 걸면 원색 그대로 나간다) — 이 둘은 짝이라 하나만
  고치면 깨진다.
  - ⚠️ **`UITabBarAppearance`의 `iconColor`/`titleTextAttributes`만으론 비선택 탭이 계속 기본색(검정)으로
    남는 경우가 실측됐다** — 원인 미상(iOS 버전별 편차로 추정). 더 오래된 레거시 프로퍼티
    `UITabBar.appearance().tintColor`/`.unselectedItemTintColor`를 같이 걸어야 비선택 색이 안정적으로
    적용된다. 이 계열 문제가 재발하면 새 API보다 이 레거시 프로퍼티부터 의심할 것.
- ⚠️ **로그인 안 된 상태(유효 토큰 없음)로 `MainTabView`를 열면 몇 초 안에 온보딩으로 튕겨 돌아간다**
  (#196 실측) — SwiftUI `TabView`는 현재 보고 있는 탭뿐 아니라 **4탭을 전부 즉시 로드**해서, 홈을 보는
  중에도 백그라운드에서 서재(`LoadMyLibraryUseCase`)가 같이 호출된다. 서버가 미인증 요청에 404
  `USER-006`으로 응답하면 `NetworkingClient`가 이를 "재인증 필요"로 해석해 토큰을 지우고
  `.authenticationRequired`를 던지고, `LibraryRootView.onAuthenticationRequired` → `MainTabView` →
  `ContentView`가 그대로 받아 `route = .onboarding`으로 전체를 되돌린다. **홈은 원래 비로그인도 봐야
  하는 화면이라 이 정책이 맞지 않다** — 지금은 실제 로그인 세션으로 테스트하면 안 겪지만, 비로그인
  브라우징을 지원하려면 탭을 lazy 로드하거나(진짜 선택했을 때만 그 탭의 API 호출) 홈만 인증 실패를
  무시하도록 정책을 분리해야 한다. 아직 미해결 — 다음에 이 증상(탭바가 보이자마자 사라짐)을 다시 보면
  먼저 이 문서부터 볼 것.
- **서재의 "웹소설 찾기"(빈 상태 CTA, `onSearchTapped`)와 우상단 등록 버튼(`onRegisterTapped`)은
  둘 다 같은 `SearchAssembly`(일반 검색)로 push된다**(사용자 확정, #196) — 서재엔 전용 "작품 등록"
  화면이 없고, 검색해서 찾은 작품을 작품 상세에서 등록하는 흐름이다. 나중에 전용 등록 화면이 생기면
  `onRegisterTapped` 쪽만 그 화면으로 바꾸면 된다(`onSearchTapped`와 분리해서 갈 이유가 생기면).
- **"다른 탭으로 전환"은 push가 아니라 `MainTabView`의 `TabView(selection:)`을 바꾸는 별개 경로다**
  (마이페이지 서재 블록 탭 → 서재 탭, #196) — `MainTabView`가 `private enum Tab`과
  `@State private var selectedTab`을 갖고 각 탭 콘텐츠에 `.tag(Tab.xxx)`를 건 뒤, 필요한 탭 Root에
  `onLibraryTapped: { selectedTab = .library }` 같은 콜백을 내려준다. **push용 `Destination` enum과
  헷갈리지 말 것** — push는 그 탭의 `NavigationPath`에 화면을 쌓지만, 탭 전환은 다른 탭을 화면 맨
  앞으로 가져올 뿐 각 탭이 쌓아둔 스택은 그대로 보존된다(서재 탭이 이미 뭔가 push된 상태였다면 그
  화면이 그대로 다시 보인다). 다른 탭에도 같은 종류의 "탭 전환" 요구가 생기면 이 패턴(탭 Root가
  `onXxxTabTapped` 콜백을 받고, `MainTabView`가 `selectedTab`을 바꾸는 클로저를 내려줌)을 재사용할 것.
- **서재의 "알림 관리"는 설정 목록 전체가 아니라 `SettingFactory.makeNotificationSettingView`로
  바로 진입한다**(사용자 확정, #196) — 서재 맥락에서 필요한 건 알림 설정뿐이라 `SettingFactory.makeView`
  (설정 메인 목록)를 거치지 않고 그 하위 화면으로 직행한다. `AppDependencies.pushSettingRepository`
  (`NotificationDataFactory.makePushSettingRepository`)가 이 화면 전용으로 새로 추가됐다.
