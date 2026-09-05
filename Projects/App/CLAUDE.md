# App 레이어

앱 진입점. **의존성 주입(DI)과 전역 흐름 조립**을 담당한다. 비즈니스 로직은 두지 않는다.

- 디렉토리: `Projects/App/`
- 비동기/상태: SwiftUI App lifecycle

## 구성

```
Sources/
├── WSSIOSV2App.swift        # @main. 폰트 등록·KakaoSDK 초기화 등 앱 시작 시 1회 처리 + onOpenURL
│                             # (카카오 로그인 콜백은 SDK로, websoso:// 딥링크는 pendingDeepLink로, #228).
├── ContentView.swift        # 앱 루트. AppDependencies를 만들어 플로우들에 내려주고,
│                             # Route(.splash/.onboarding/.main)로 전환한다(#236 — 초기 route는 .splash,
│                             # 부트스트랩 결과(BootstrapOutcome)가 forceUpdate 알럿/온보딩/홈+약관시트를 가른다).
│                             # 세션이 끝나는 모든 경로(resetToOnboarding)는 AppDependencies를 재조립한다.
│                             # 딥링크 Binding은 MainTabView로만 내려간다(스플래시·온보딩 중엔 그대로 대기).
├── DI/
│   └── AppDependencies.swift  # 유일한 조립 지점 — NetworkingClient·TokenStore·Repository 조립.
├── Onboarding/
│   └── OnboardingRootView.swift  # 온보딩 플로우 배선(OnboardingFactory 호출 + 화면 전환).
│                                  # 끝나면(기존 유저 로그인 / 온보딩 완료) onFinished()만 부른다 —
│                                  # 어디로 갈지는 정하지 않고 ContentView에 위임.
├── Main/
│   └── MainTabView.swift     # 온보딩 이후 루트 — 홈/피드/서재/My 4탭 TabView. 탭 아이콘은
│                              # DesignSystem의 Icons/Tabbar 에셋(icNavigateHome 등). 딥링크는
│                              # **선택된 탭 Root에만** 건네고 소비되면 nil로 되돌린다(아래 주의사항).
├── Home/    └── HomeRootView.swift      # "홈" 탭. HomeFactory 조립 + 작품 상세·피드 상세·일반 검색·
│                                          # 작가 이름 검색·작품 평가·피드 작성·유저 프로필·그 전체 피드
│                                          # 목록·마이페이지 편집·상세탐색 필터/결과(#201 홈 배너 →
│                                          # #236부터 검색 "더보기"로 4탭 공용이 되어 필터 조립·키워드 탭
│                                          # 콘텐츠(KeywordTabContentBuilder)를 SearchAssembly.
│                                          # makeDetailSearchFilterView로 승격)까지(NovelDetailAssembly/
│                                          # NovelReviewAssembly/FeedFeatureFactory/UserPageAssembly/
│                                          # LibraryFactory.makeUserLibraryView(타유저 서재)/SearchAssembly/
│                                          # MypageFactory) 실제 push.
├── Feed/    └── FeedRootView.swift      # "피드" 탭. FeedFeatureFactory.makeSosoFeedView 조립 + 피드 상세·
│                                          # 작품 상세·작품 평가·피드 작성·타유저 프로필·그 전체 피드 목록·
│                                          # 그 프로필의 타유저 서재·작가 이름 검색(makeFeedDetailView/
│                                          # NovelDetailAssembly/NovelReviewAssembly/makeCreateFeedView/
│                                          # UserPageAssembly/LibraryFactory.makeUserLibraryView/
│                                          # SearchAssembly)까지 push.
├── Library/ └── LibraryRootView.swift   # "서재" 탭. LibraryFactory.makeMyLibraryView 조립 + 작품 상세·
│                                          # 작품 평가·피드 작성·유저 프로필·그 타유저 서재(makeUserLibraryView,
│                                          # #197)·전체 피드 목록·일반 검색·
│                                          # 알림 설정+완결/휴재복귀 알림 목록(NovelDetailAssembly/
│                                          # NovelReviewAssembly/FeedFeatureFactory/UserPageAssembly/
│                                          # SearchAssembly/SettingFeatureFactory의 makeNotificationSettingView·
│                                          # makeCompletionNotificationListView·makeHiatusReturnNotificationListView,
│                                          # #201)까지 push.
├── Mypage/  └── MypageRootView.swift    # "My" 탭. UserPageFeature의 MypageFactory.makeView 조립 +
│                                          # 프로필 편집·설정 전체 트리(makeEditView/SettingFeatureFactory의
│                                          # 8개 화면 — 계정정보·성별나이변경·차단유저목록·회원탈퇴·
│                                          # 프로필공개설정·알림설정·완결/휴재복귀 알림목록, #201)·
│                                          # 컬렉션 목록/생성/수정/상세/작품 추가/서재에서 추가
│                                          # (CollectionFeatureFactory, #201 — 컬렉션 미리보기 개별
│                                          # 항목 탭도 그 컬렉션 상세로 직행)·타유저 전체 피드 목록·
│                                          # 그 타유저 서재(makeUserLibraryView, #197)까지 push. **내**
│                                          # 서재 블록 탭은 push가 아니라 MainTabView 탭 전환으로 위임
│                                          # (모듈명과 Factory 이름이 다르니 혼동 주의) — 타유저 프로필
│                                          # 안의 서재 블록(push)과는 별개.
├── Novel/   ├── NovelDetailAssembly.swift  # 작품 상세 조립 공용 헬퍼 — 홈/피드/서재 3탭이 공유(아래).
│            └── NovelReviewAssembly.swift  # 작품 평가 조립 공용 헬퍼 — 작품 상세 평가 상태바 탭에서
│                                             # 3탭이 공유(#197).
├── Search/  └── SearchAssembly.swift       # 일반 검색 조립 공용 헬퍼 — 홈/피드/서재 3탭이 공유(아래).
├── UserPage/└── UserPageAssembly.swift     # 타유저 프로필(makeView) + 그 "활동기록 더보기"(makeFeedListView,
│                                             # #201) 조립 공용 헬퍼 — 홈/피드/서재/My 4탭 전부가 공유.
└── Collection/
    ├── CollectionEditAssembly.swift    # 컬렉션 수정 트리(수정→작품 추가→서재에서 추가) 조립 공용 헬퍼 —
    │                                     # 딥링크(#228)로 어느 탭에서든 내 컬렉션이 열려 4탭 전부 사용.
    │                                     # pop 핸들러·pendingCollectionNovelSelection은 각 Root 소유.
    ├── CollectionDetailAssembly.swift  # 컬렉션 상세 조립 공용 헬퍼 — 마이페이지 "내 컬렉션" 목록뿐
    │                                     # 아니라 4탭의 타유저 프로필 컬렉션 미리보기도 공유(#201 후속).
    │                                     # onEditTapped 기본값은 no-op — 타유저 컬렉션은 항상
    │                                     # isMine==false라 수정 버튼이 안 뜬다.
    └── CollectionListAssembly.swift    # 컬렉션 목록 조립 공용 헬퍼 — isOwnCollections 기본값 false
                                          # (타유저 프로필 "컬렉션" 헤더 탭). 마이페이지의 "내 컬렉션"
                                          # 목록만 true로 명시 호출.
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
- **작품 상세·작품 평가·일반 검색·타유저 프로필 조립은 `NovelDetailAssembly`/`NovelReviewAssembly`/
  `SearchAssembly`/`UserPageAssembly`(전부 `@MainActor enum`)로 공용화돼 있다**(#196~#197, 2번째
  이상의 탭이 같은 목적지를 필요로 한 시점에 뽑는 패턴) — 각 탭 Root는 자기
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

- **재발급(/reissue) 전용 URLSession엔 요청 타임아웃 10초가 걸려 있다**(#236, `AppDependencies`의
  `refresherClient`) — 재발급 대기(`SessionRefreshCoordinator`)가 취소에 반응하지 않아 스플래시 게이트
  예산(4초)이 뚫리는 구멍(`SplashDomain/CLAUDE.md`)을 App 조립에서 60초→10초로 좁힌 것. Core는 그대로다
  — 이 세션을 기본(60초)으로 "정리"하면 만료 토큰 + 무응답 망에서 스플래시가 최대 1분 잠기는 회귀가 된다.
- ⚠️ **CreateFeed에 새 UseCase를 주입하려면 조립 지점이 5곳이다** — 작성 경로는 각 탭 Root의 `createFeedView(connectedNovel:)` 헬퍼 **4곳**(`FeedRootView`·`HomeRootView`·`LibraryRootView`·`MypageRootView`, 동일 코드 복제)에서 `FeedFeatureFactory.makeCreateFeedView`를 직접 호출하고, 수정 경로는 `FeedDetailAssembly.makeEditFeedView` **1곳**이다(NovelReview는 `NovelReviewAssembly` 1곳으로 공용화된 것과 대비 — 작성 헬퍼는 아직 공용 Assembly로 안 뽑힘). #221 앱 리뷰 UseCase 주입 때 이 5곳 + NovelReviewAssembly를 모두 손댔다. 순수 로컬(UserDefaults) repo(온보딩·앱리뷰)는 `AppDependencies`에 `let ...Repository` 선언 + init 끝에서 `Default...Repository(appStorage: UserDefaultsStorage())`로 조립(네트워크 client 불필요)한 뒤, 각 조립 지점이 `Default...UseCase(repository: dependencies.xxxRepository)`로 감싸 주입한다.
- ⚠️ **push할 화면에 "진입 파라미터"를 넘길 땐 별도 `@State` 스크래치 변수에 먼저 써두고 그 값을
  읽어 destination view를 만들지 말 것 — `NavigationPath`의 `Destination` payload로 직접 실어
  보내야 한다.** `scratchState = value; path.append(Destination.xxx)`처럼 같은 액션 안에서 `@State`
  갱신과 push를 연달아 해도, `.navigationDestination(for:)`가 새 destination view를 만드는 시점에
  그 `@State` 갱신이 **아직 반영되지 않은 이전 값**을 읽어버리는 레이스가 있다(`CollectionFeature`의
  "작품 추가"→"서재에서 추가" 흐름에서 실측 — `MypageRootView`가 스크래치 `@State`로 초기 선택 목록을
  넘기다가, 검색에서 고른 작품이 서재 화면 진입 시 통째로 사라지는 버그로 실제 재현됐다. 자세한 재현·
  디버그 로그는 `CollectionFeature/CLAUDE.md` 참고). **원인이 되는 타입이 아직 Hashable이 아니라서
  어쩔 수 없이 스크래치 `@State`로 우회하는 것이라면, 먼저 그 타입을 Hashable로 만들 수 있는지부터
  검토할 것** — 캐스케이드가 없으면(다른 비Hashable 타입을 필드로 안 담고 있으면) 거의 항상 가능하고,
  Destination payload로 직접 넘기면 이 레이스가 구조적으로 사라진다. 반대로 **화면이 App에 결과를
  돌려주는 "확정 값"**(`pendingNovelSelection` 같은 `Binding<T?>` + `.onChange` 채널)은 이미 mount된
  화면이 관찰하는 구조라 이 레이스 대상이 아니다 — 레이스는 오직 "아직 mount 안 된 destination이
  방금 쓴 `@State`를 못 읽는" 진입(entry) 방향에서만 난다.
- ⚠️ **`Support/Info.plist`는 Tuist `.extendingDefault(with:)`가 아니라 `.file(path:)`로 직접 지정**돼 있어
  (Feature Demo 앱들과 달리 `ModuleInfoPlist` 헬퍼를 안 씀), Xcode가 표준으로 자동 채워주는
  `CFBundleIdentifier`/`CFBundleExecutable`이 **없으면 시뮬레이터 설치 자체가 실패**한다
  (`Missing bundle ID` → `missing or invalid CFBundleExecutable`, #196에서 실측). 이 plist에 새 키를
  추가할 땐 표준 키가 여전히 살아있는지 함께 확인할 것 — 지우면 조용히 안 죽고 빌드는 되는데 설치가 깨진다.
  - ⚠️ **`CFBundleShortVersionString`/`CFBundleVersion`도 같은 이유로 여기 직접 적혀 있다**(값은
    `Project.swift` App 타깃 settings의 `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION`, #228 — `Config/*.xcconfig`는
    gitignore된 비밀값 파일이라 거기 두면 다른 머신엔 안 간다). 이 둘이 없어도 빌드·설치는
    되지만 **카카오 SDK가 `CFBundleShortVersionString`을 `kakaolink://send`의 필수 파라미터 `appver`로 보내고
    nil이면 파라미터를 통째로 빼버려**(`ShareApi`의 `.filterNil()`) 카카오톡이 "전달하려는 메시지의 필수 정보에
    오류가 있습니다 [(Core parameter(s) missing)]"로 카드를 거부한다(실기기 실측, 2026-08-29). Demo 앱들은
    Tuist 기본 plist(`.extendingDefault`)라 1.0/1이 자동으로 들어가 같은 문제가 안 보인다 — **App에서만 나는
    차이**이니 카카오 공유가 Demo에선 되고 App에서만 안 되면 이 키부터 볼 것.
- **Apple 로그인 버튼은 시뮬레이터에 Apple ID가 로그인돼 있으면 시스템 계정 선택/Face ID 시트로,
  없으면 설정 앱의 "Apple 계정" 화면으로 튄다**(둘 다 정상 — `OnboardingFeature/CLAUDE.md` 참고).
  Kakao 로그인은 `kauth.kakao.com` `ASWebAuthenticationSession` 동의 시트가 뜨는 게 정상(실측,
  시뮬레이터에서도 동작) — 취소하면 `.loginFailed` → "알 수 없는 에러가 발생했어요" 토스트로 낙착.
- **온보딩 완료(`OnboardingRootView.handleOnboardingCompleted`)·기존 유저 로그인 둘 다 `onFinished()`
  하나로 수렴**해 `ContentView`가 `route = .main`으로 전환한다 — 신규/기존 유저를 구분해 다른 곳으로
  보낼 이유가 아직 없어서 일부러 하나로 합쳤다. 나중에 갈림이 필요해지면(예: 신규 유저만 튜토리얼)
  `onFinished`를 매개변수 있는 콜백으로 바꿀 것.
- **각 탭 Root의 화면 전환 콜백 중 상당수는 이미 실제 push로 뚫려 있다**(작품 상세·피드 상세·일반
  검색·프로필 편집·설정·타유저 프로필·알림 설정·알림 목록/상세·상세탐색 필터/결과 — 필터/결과는
  #236부터 4탭 전부, 검색 화면의 장르·키워드 "더보기" 헤더 포함) — 남는 placeholder가 생기면 그
  모듈을 붙일 때 해당 콜백 하나만 실제 화면 전환으로 바꾸면 된다(전부 한 번에 바꿀 필요 없음). **`SosoFeedView`의 피드
  셀은 연결 작품 배너(`onNovelTapped`)·작성자 프로필(`onUserProfileTapped`)까지 전부 실제 push다**
  (#196) — `FeedRootView`가 전자는 같은 `Destination.novel`로, 후자는 `Destination.userPage` →
  `UserPageAssembly`로 연결한다.
  - ⚠️ **`NovelID`와 `FeedID`는 둘 다 `IDWrapper<Int>` 타입 별칭이라 실제로는 같은 타입이다** —
    `NavigationPath`에 그냥 섞어 넣거나 `.navigationDestination(for: NovelID.self)` +
    `.navigationDestination(for: FeedID.self)`를 따로 등록하면 타입이 겹쳐 의도대로 라우팅되지 않는다.
    `HomeRootView.Destination` 같은 래퍼 enum으로 명시적으로 태깅해서 push할 것 — 다른 탭 Root에
    같은 방식의 push 네비게이션을 추가할 때도 이 함정을 반복하지 말 것.
  - **탭에서 push된 화면은 탭바를 가린다**(사용자 확정) — 단 `.toolbar(.hidden, for: .tabBar)`를
    `.navigationDestination` 클로저(= pop 시 파괴되는 destination 뷰) 안에 붙이면, root 복귀 때 탭바가
    **뒤늦게** 붙으며 홈이 "탭바 없이" 먼저 그려졌다 콘텐츠가 튀는 게 실측됐다(#244, iOS 26 Liquid Glass에서
    더 심함). 그래서 각 탭 Root는 **`NavigationStack { … }` 호출부**에 `.hidesTabBar(when: !path.isEmpty)`
    (공용 헬퍼 `Sources/Main/TabBarVisibility.swift`)로 건다 — 파괴되지 않는 컨테이너에서 `path.isEmpty`로
    가시성 **값만** 바꾸므로 탭바 복원이 pop과 동기화된다. 다른 탭 Root에 push 네비게이션을 추가할 때
    이 자리도 같이 만들 것(❌ destination 클로저 안에 다시 붙이지 말 것 — 지연이 재발한다). 자세한 사유는
    헬퍼 파일 상단 주석 참조.
  - **같은 화면이라도 "흔한 진입 경로"와 "흔치 않은 부가 정보를 들고 들어오는 경로"는 옵셔널 파라미터
    하나로 합치지 말고 별도 `Destination` case로 분리한다**(사용자 확정, #197 — 예:
    `createFeed`(연필 아이콘, 파라미터 없음) vs `createFeedFromNovel(ConnectedNovel)`(작품 상세 "나도
    한마디")). `case createFeed(ConnectedNovel?)` 하나로 합쳤다면 그 값이 필요 없는 나머지 모든
    진입점(연필 아이콘 등)도 매번 `nil`을 끼워 넣어야 해서, 정작 그 파라미터를 쓰는 곳은 한 곳뿐인데
    나머지 다수가 그 존재를 알아야 하는 부담이 생긴다. 목적지 View/헬퍼 함수(`createFeedView(connectedNovel:)`)는
    공유하되, `Destination` case만 나눠서 각 진입점이 자기와 무관한 파라미터를 모르게 한다 — 그 탭에
    "흔한" 진입점 자체가 없으면(Home/Library의 피드 작성처럼) 옵셔널 없이 `case createFeedFromNovel(ConnectedNovel)`
    하나만 두면 된다.
- ⚠️ **push 전환과 동시에 뜨는 `.overlay` 기반 알럿(`showWSSAlert`)은 push에 밀려 사라진다** —
  이동 신호를 받는 Feature 화면(예: 홈)에 알럿을 붙이면, 그 화면이 push로 덮이는 순간 알럿도 같이
  사라져버린다(`HomeFeature`의 알림 벨 탭에서 실측 — denied 알럿이 보였다 안 보였다 하는 게 아니라,
  이동이 실제로 안 되는 것처럼 보였다). **알럿은 이동 "목적지" 쪽(App이 소유한 `NavigationStack` 또는
  그 목적지 자체)에 붙여야 push가 끝난 뒤에도 살아남는다** — `HomeRootView`의 `isPushAuthorizationAlertPresented`가
  선례(탭 → push 시작과 동시에 App이 직접 권한을 재확인해 목적지 화면 위에 알럿을 띄움, Feature
  쪽에서는 이동 신호만 올리도록 단순화). `SettingFeature`의 알림 설정 메뉴는 반대로 "먼저 알럿 →
  denied면 아예 이동 안 함" 패턴으로 같은 함정을 피한다(`HomeFeature/CLAUDE.md` 참고) — 이동이 항상
  일어나야 하는 화면이면 전자, 조건부로 막아도 되는 화면이면 후자를 쓸 것.
- ⚠️ **My(`MypageRootView`)는 세션을 끝내는 콜백이 둘이다(#228부터).** `onSessionEnded`는 설정 화면의
  회원탈퇴/로그아웃 **성공**(`SettingFactory`의 `onWithdrawSuccess`/`onLogoutSuccess`) — 사용자가 세션을 끝낸
  것. `onAuthenticationRequired`는 그 탭 위에 push된 화면(컬렉션 상세·작품 상세 등)의 401 — 다른 탭과 같은
  계약. 둘 다 결과는 온보딩 복귀지만 `MainTabView`가 후자에만 딥링크 복원을 거는 차이가 있어(아래 딥링크
  항목) 예전처럼 하나로 합치지 말 것. **`MypageFactory.makeView`도 #244부터 `onAuthenticationRequired`를 받는다**
  (마이페이지 콘텐츠 로드 401이 조용히 빈 상태로 남지 않고 이 콜백으로 로그인 유도) — `MypageRootView`가 그 탭의
  `onAuthenticationRequired`를 그대로 넘긴다. 단 `.makeEditView`(프로필 편집)는 아직 안 받고, 타유저 프로필
  (`UserPageView`)·활동 피드(`UserFeedListView`)도 미배선이다(`docs/TODO.md`의 "UserPage 계열 인증 만료 로그인
  라우팅 배관"). **Home·Feed·서재 세 탭도 401 경로만 있다**(Feed는 탭 콘텐츠 자체(`makeSosoFeedView`)는 못 받지만,
  거기서 push하는 작품 상세(`NovelDetailAssembly`)·**피드 상세(`FeedDetailAssembly`, #244부터)**는 받아서
  전달한다 — `FeedRootView` 참고).
- **`onAuthenticationRequired`(→ `ContentView.resetToOnboarding`)는 온보딩 라우팅 + `AppDependencies`
  재조립까지 하고, 토큰 삭제는 하지 않는다**(#236) — 401을 받은 시점에 이미 서버가 세션을 무효화한
  상태라 재로그인하면 새 토큰으로 덮어써진다. 재조립을 하는 이유는 **이전 세션에서 채워졌을 수 있는
  `HomePrefetchStore` 슬롯을 인스턴스째 버리기 위함**(#225 리뷰의 좁은 레이스 — 유효 토큰으로 채워진
  뒤 소비 전에 세션이 바뀌는 경우). 어느 탭에서 발생했든(`MainTabView`가 4탭의 `onAuthenticationRequired`를
  같은 클로저 `restoreDeepLinkAndRequireAuthentication`으로 받음) idempotent해야 한다는 계약은 그대로
  유지 — 재조립은 `route != .onboarding` 가드로 1회만 된다.
- ⚠️ **`DesignSystem` 에셋을 탭바 아이콘처럼 이름 문자열로 참조하면(`Label(_:image:)`) 완전히 새로
  설치한 상태에서 아이콘이 조용히 안 보인다** — 그 이미지는 App이 아니라 `DesignSystem.framework`
  자체의 리소스 번들에 있는데, `Label(_:image:)`/`Image(_:)`(이름 문자열 버전)는 기본적으로
  `Bundle.main`만 뒤진다. 기존 앱이 남아있는 상태로 재설치하면 우연히 그전 바이너리가 남아 있어
  증상이 안 보일 수 있다(실측 — 처음엔 이 캐시 때문에 못 잡았다) → **아이콘류는 항상
  `WSSImage.icXxx.swiftUIImage`(제네레이터가 `Bundle.module`로 만든 `Image`)로 참조할 것**,
  이름 문자열 기반 API는 쓰지 않는다. 검증할 땐 `xcrun simctl uninstall`로 완전히 지운 뒤 재설치해서
  볼 것 — 증분 재설치는 이 종류의 버그를 가린다.
- **탭바 색은 두 곳으로 갈라져 있다(#221 실측으로 재정리) — 아이콘=`MainTabView`, 글씨=`WSSIOSV2App`.**
  ⚠️ **iOS 26 새(Liquid Glass) 탭바는 `UITabBarAppearance`의 비선택(`normal`) 채널을 통째로 무시한다** —
  `normal.iconColor`/`normal.titleTextAttributes`/`unselectedItemTintColor`에 빨강을 넣어도 비선택 탭이
  계속 기본 label색(검정)으로 그려졌다(iPhone 17 Pro / iOS 26.5 실측, **선택 채널만 먹음**). 그래서:
  - **아이콘 색은 `MainTabView.tabLabel`이 `isSelected`로 갈라 색을 구운 `.alwaysOriginal` 이미지
    (`icon.image.withTintColor(_:renderingMode:.alwaysOriginal)`)를 직접 그린다** — `.alwaysOriginal`이라
    탭바가 재틴트를 못 해 우리가 칠한 색(선택 wssBlack / 비선택 wssGray200)이 그대로 남는다. **더 이상
    `.renderingMode(.template)` + 어피어런스 `iconColor` 틴트에 의존하지 않는다**(그 방식은 iOS 26 비선택에서
    깨졌다). 이 baked 방식은 iOS 버전 무관하게 동작한다.
  - **글씨(제목) 색은 `WSSIOSV2App.configureTabBarAppearance()`가 어피어런스 `titleTextAttributes`로
    정한다** — 선택 wssBlack은 iOS 26·18 모두 먹지만, **비선택 글씨는 iOS 26에선 검정으로 남는다**(위
    `normal` 무시 때문, 플랫폼 제약). iOS 18 이하에선 `normal`이 정상 동작해 아이콘·글씨 모두 gray200.
  - **비선택 글씨까지 gray200으로 맞추는 유일한 방법은 `UIDesignRequiresCompatibility`(Info.plist)로 앱
    전체를 iOS 18 외형으로 되돌리는 것**인데(실측으로 아이콘+글씨 둘 다 해결 확인), 탭바만이 아니라 앱
    전역(네비바·시트 등)에 영향이라 채택하지 않았다(사용자 확정 — 아이콘 구분만으로 충분). Liquid Glass를
    정식 도입하기로 하면 그때 이 플래그/전략을 다시 볼 것.
  - 어피어런스의 `iconColor`/레거시 `tintColor`·`unselectedItemTintColor`는 코드에 남아 있으나, 아이콘은
    baked 이미지에 밀려 iOS 18 이하 폴백 의미뿐이다(색이 같아 충돌 없음). 이 계열 문제가 재발하면 먼저
    "iOS 26 탭바가 비선택 채널을 죽였다"는 위 사실부터 떠올릴 것.
- ⚠️ **로그인 안 된 상태(유효 토큰 없음)로 `MainTabView`를 열면 몇 초 안에 온보딩으로 튕겨 돌아간다**
  (#196 실측) — SwiftUI `TabView`는 현재 보고 있는 탭뿐 아니라 **4탭을 전부 즉시 로드**해서, 홈을 보는
  중에도 백그라운드에서 서재(`LoadMyLibraryUseCase`)가 같이 호출된다. 서버가 미인증 요청에 404
  `USER-006`으로 응답하면 `NetworkingClient`가 이를 "재인증 필요"로 해석해 토큰을 지우고
  `.authenticationRequired`를 던지고, `LibraryRootView.onAuthenticationRequired` → `MainTabView` →
  `ContentView`가 그대로 받아 온보딩으로 전체를 되돌린다. **#236부터 콜드 스타트에선 이 증상이
  사라졌다** — 스플래시 세션 게이트가 토큰 없으면 `.intro`로 보내 `MainTabView` 자체가 안 뜬다.
  이 바운스 경로는 "쓰던 중 세션이 죽는" 경우의 안전망으로만 남는다. **홈은 원래 비로그인도 봐야
  하는 화면이라 이 정책이 맞지 않다** — 비로그인 브라우징을 지원하려면 탭을 lazy 로드하거나(진짜
  선택했을 때만 그 탭의 API 호출) 홈만 인증 실패를 무시하도록 정책을 분리해야 한다(여전히 미지원).
- **서재의 "웹소설 찾기"(빈 상태 CTA, `onSearchTapped`)와 우상단 등록 버튼(`onRegisterTapped`)은
  둘 다 같은 `SearchAssembly`(일반 검색)로 push된다**(사용자 확정, #196) — 서재엔 전용 "작품 등록"
  화면이 없고, 검색해서 찾은 작품을 작품 상세에서 등록하는 흐름이다. 나중에 전용 등록 화면이 생기면
  `onRegisterTapped` 쪽만 그 화면으로 바꾸면 된다(`onSearchTapped`와 분리해서 갈 이유가 생기면).
- **딥링크(`websoso://…`, #228)는 `WSSIOSV2App.onOpenURL` → `pendingDeepLink`(@State) →
  `ContentView`(Binding) → `MainTabView` → **지금 선택된 탭 Root**의 `path.append` 순으로 흐른다**
  (사용자 확정 — 앱을 쓰던 중이면 보던 화면 위에 바로 push, 콜드 스타트면 기본 탭인 홈 위). 파싱은
  `BaseDomain.DeepLink(url:)`이 하고(형식은 그 파일이 정본), 형식에 안 맞는 URL은 조용히 버린다.
  - ⚠️ **`TabView`는 4탭 Root를 전부 동시에 mount하므로 딥링크 값을 4탭에 다 주면 4번 push된다** —
    `MainTabView.deepLink(for:)`가 `selectedTab`과 같은 탭에만 값을 주고 나머지는 nil. 각 Root는
    `.onChange(of: deepLink, initial: true)`로 받아 push한 뒤 `onDeepLinkConsumed()`로 nil로 되돌린다
    (`initial: true`라 Root가 mount되기 전에 도착한 링크 — 콜드 스타트, 온보딩 중 수신 — 도 잡는다).
  - **이미 온보딩(로그아웃) 화면일 때 링크를 열면 `ContentView`가 `.main`으로 바뀔 때까지 `pendingDeepLink`에
    남아 있다가 로그인 뒤 이어서 처리된다** — 서버는 공개 컬렉션의 비로그인 조회를 허용하지만, 앱 게이트가
    `MainTabView`를 온보딩으로 되돌리므로(위 "로그인 안 된 상태로 `MainTabView`를 열면" 항목) 그 전에
    push해봐야 소용없다.
    - ⚠️ **토큰 없는 콜드 스타트는 위 대기가 안 걸린다** — `route`가 `.main`으로 시작해 홈 Root가 링크를 즉시
      소비·push하고, 몇 초 뒤 401 바운스가 `MainTabView`째 파괴해 링크가 통째로 사라졌다(카드 수신자의 주
      시나리오 — 앱 꺼진 상태에서 "앱에서 보기", #228 리뷰에서 발견). 그래서 `MainTabView`가 소비한 링크를
      `deliveredDeepLink`에 들고 있다가 **4탭의 401 경로(`restoreDeepLinkAndRequireAuthentication`)에서
      `pendingDeepLink`로 되살린다** — 로그인 뒤 새 `MainTabView`가 다시 소비한다.
      - 복원 창은 **딥링크 화면이 스택에 남아 있는 동안만**이다 — 각 Root가 push 시 `deepLinkDestinationDepth`
        (= 그때의 `path.count`)를 기억하고 `path.count`가 그 아래로 내려가면 `onDeepLinkDestinationDismissed`로
        알려 `MainTabView`가 지운다. 안 지우면 한참 뒤 무관한 401에도 옛 컬렉션이 재로그인 후 다시 뜬다(2라운드 리뷰).
        슬롯은 탭별 하나(`(tab, link)`)라 **같은 탭에 링크 A 화면을 둔 채 링크 B가 또 도착해 위에 쌓이면 A는 추적에서
        빠진다**(B를 pop하면 슬롯이 비어 A 화면의 401은 복원 안 됨) — 극단 케이스라 감수(리뷰에서 인지, 3라운드).
      - ⚠️ **My 탭은 콜백이 둘이다** — `onSessionEnded`(설정 로그아웃·탈퇴 성공 = 사용자가 세션을 끝냄, 복원 ❌)와
        `onAuthenticationRequired`(그 탭 위 push 화면의 401, 복원 ⭕). 예전엔 하나로 합쳐져 있었는데 My 탭에서
        딥링크 화면이 401을 만나면 복원이 안 됐다. 결과(온보딩 복귀)가 같다고 다시 합치지 말 것.
      - 세션 복원(#236, 스플래시 세션 게이트)이 들어와 콜드 스타트 401 자체는 사라졌지만 — 토큰 없는
        콜드 스타트는 이제 `.intro`로 시작해 `pendingDeepLink`가 로그인까지 대기한다 — 이 복원 로직은
        "보던 중 만료" 바운스에 여전히 필요하니 지우지 말 것.
  - `onOpenURL`은 **`DeepLink(url:)`를 먼저** 보고, nil이면 카카오 로그인 콜백(`kakao{APP_KEY}://oauth…`)인지
    `AuthApi.isKakaoTalkLoginUrl`로 물어 SDK에 넘긴다 — 카카오 콜백은 host가 `oauth`라 `DeepLink`가 nil을
    돌려주니 순서를 뒤집어도 동작은 같지만, `isKakaoTalkLoginUrl`은 앱 키 미설정 시 `try!`로 죽는 SDK 경로라
    순수 파서를 앞에 둔다.
  - **카카오톡 공유 카드(메시지 자체)를 탭해도 같은 경로다**(#241부터 — 콘솔 커스텀 템플릿엔 별도
    "앱에서 보기" 버튼 컴포넌트가 없다, `CollectionFeature/CLAUDE.md` 공유 항목 참고) — 카카오톡이 앱을
    `kakao{APP_KEY}://kakaolink?collectionId={id}`로 열면 `DeepLink(url:)`이 `kakaolink` host를
    `.collectionDetail`로 풀어 위와 똑같이 push된다. App은
    스킴을 따로 분기하지 않는다. 카드 전송 쪽 전제(`LSApplicationQueriesSchemes`의 `kakaolink`, 카카오 콘솔
    iOS 플랫폼의 Bundle ID·App Store ID)는 `CollectionFeature/CLAUDE.md` 공유 항목 참고 — 시뮬레이터엔
    카카오톡이 없어 수신 경로는 `xcrun simctl openurl <udid> "kakao<APP_KEY>://kakaolink?collectionId=4"`로만
    흉내낼 수 있다.
  - **시뮬레이터 실측은 `xcrun simctl openurl <udid> "websoso://collections/4"`** — 시스템이 "'Websoso'에서
    열겠습니까?" 확인 다이얼로그를 먼저 띄우므로(커스텀 스킴 정책) `snapshot_ui`로 "열기"를 탭해야 앱에
    URL이 전달된다. 전달 여부는 시뮬레이터 로그 `Opening URL (websoso://…) with kr.websoso.app.WSS-iOS`
    로 확인(`xcrun simctl spawn <udid> log show --last 1m --predicate 'eventMessage CONTAINS "websoso://"'`).
  - **딥링크로 열린 컬렉션이 "내" 컬렉션일 수 있으므로 4탭 전부 컬렉션 수정 트리를 갖는다** — 처음엔
    `MypageRootView`에만 있었고 홈/피드/서재의 `CollectionDetailAssembly.onEditTapped`는 no-op 기본값이라
    (그 세 탭은 타유저 컬렉션만 열려 `isMine == false`가 보장됐었다) 딥링크 도입 직후 "수정" 메뉴가 죽은
    버튼이 됐다(사용자 확정으로 배선 선택, 2026-08-29). 조립은 `CollectionEditAssembly`로 뽑았고, 각 Root는
    `Destination` 3케이스 + `pendingCollectionNovelSelection` + pop 핸들러(1단계/2단계)만 갖는다. **링크만으론
    소유자를 알 수 없어 탭을 미리 고를 수 없다** — 그래서 "My 탭으로 보내기"가 아니라 4탭 배선이다.
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
- **크로스스크린 완료 피드백은 통합 채널(`Sources/Main/CrossScreenFeedback.swift`)로 띄운다**(#236 —
  #221의 blockUser 4벌 복붙을 흡수하며 `feedEdited`("작성 완료!")·`novelReviewed`("평가 완료!")를 복원).
  발화 화면(UserPage 차단·CreateFeed 제출·NovelReview 저장)은 pop 직전 완료 콜백(`onUserBlocked`/
  `onSubmitted`/`onSaved`)만 올리고, 각 탭 Root가 `CrossScreenFeedbackState` 하나를 들고
  `crossScreenFeedback.present(...)` + 자기 `NavigationStack` **컨테이너**의 `.showCrossScreenFeedbackToast`로
  띄운다 — pop 후 최상단이 된 **직전 뷰** 위에 뜬다(진입 경로에 따라 소소피드/피드상세/작품상세 등).
  V1은 전역 `NotificationCenter` 배관을 피드 탭 하나만 캐치했지만 V2는 발화한 그 탭에서 뜬다(더 정확).
  새 완료 피드백이 필요하면 `CrossScreenFeedback`에 케이스를 더하고 seam 콜백을 그 자리에서 present로
  연결할 것 — Root마다 별도 `@State` 쌍을 새로 만들지 말 것(#221의 4벌 복붙이 그 함정이었다).
  ⚠️ **콜백은 저장/차단 "성공" 경로에서만 발화해야 한다** — 취소로 닫힐 때도 부르면 완료 안 한 일이
  완료로 안내된다(NovelReview는 `didSaveReview`, CreateFeed는 `.submitted`로 성공을 가른다).
- **피드 작성 완료 → 피드 탭 목록 재로드는 `AppDependencies.feedListInvalidation`(`Sources/Main/FeedListInvalidation.swift`,
  `@Observable` 단조 증가 카운터)이 맡는다**(2026-09-03, V1 `feedEdited` 알림 parity). 피드 탭 목록은 재진입에
  목록을 다시 받지 않아(스크롤 보존 — `FeedFeature/CLAUDE.md` 화면 동작 계약) **새 글은 이 신호로만 들어온다**:
  4탭 Root의 작성 `createFeedView` 헬퍼 `onSubmitted`가 `crossScreenFeedback.present(.feedEdited)` 뒤에
  `dependencies.feedListInvalidation.markFeedCreated()`를 부르고, `FeedRootView`가 `feedCreatedVersion`을
  `makeSosoFeedView(feedCreatedVersion:)`로 넘긴다. `@Observable` 값을 body에서 읽으므로 다른 탭에서 작성해도
  `FeedRootView`가 재평가돼(TabView가 4탭을 계속 mount) 피드 탭에 오기 전에 이미 재로드된다. `CrossScreenFeedback`
  (그 탭에서 한 번 보여주는 토스트)과 역할이 다르니 합치지 말 것. ⚠️ **수정(`makeEditFeedView`)의 `onSubmitted`에는
  붙이지 말 것** — 수정은 목록이 다녀온 셀을 상세로 동기화하고, 여기서 재로드하면 수정 후 복귀마다 스크롤이 튄다.
  새 작성 진입점(탭 Root)을 추가하면 `markFeedCreated()`도 같이 붙여야 한다 — 빠뜨리면 그 경로로 쓴 글이 피드
  탭에 당겨서 새로고침 전까지 안 보인다.
- **⚠️ 앱 아이콘·버전 정보는 시뮬레이터 빌드만으론 검증되지 않는다 — 실제 아카이브(`archive-debug`/
  `archive-release` 스킬)를 처음 돌려봐야 드러난다(2026-08-29 실측).** 이 프로젝트가 발견 당시 처음
  겪은 순서 그대로 기록:
  1. `Projects/App/Project.swift`의 App 타깃에 `resources:`가 없으면 `Resources/Assets.xcassets`
     (앱 아이콘 포함)가 빌드에 아예 안 들어간다 — 시뮬레이터는 아이콘 없이도 통과해 안 드러나고,
     App Store Connect 업로드 검증(`altool`)에서야 "Missing required icon file"로 처음 걸린다.
  2. **Debug/Release가 서로 다른 앱 아이콘을 쓴다**(홈 화면에서 운영 앱과 구분용, 사용자 확정) —
     `Resources/Assets.xcassets/AppIcon.appiconset`(Release, V1과 동일 아이콘)와
     `AppIcon-Debug.appiconset`(Debug, 별도 이미지) 두 세트를 두고, `Project.swift`의 Debug/Release
     `Configuration.settings`에서 `ASSETCATALOG_COMPILER_APPICON_NAME`을 각각 다르게 지정한다.
     둘 다 Xcode 최신 방식(단일 1024×1024 PNG, `idiom: universal`)만 쓴다 — 사이즈별 개별 PNG 불필요.
  3. **`TARGETED_DEVICE_FAMILY = "1"`(iPhone 전용)를 App 타깃 설정에 명시해야 한다** — V1(운영 앱)도
     동일(`project.pbxproj`에서 확인). 없으면 App Store Connect가 iPad용 아이콘·방향 키까지 요구해서
     실패한다(iPad 지원 자체가 없는 앱인데 검증만 걸리는 상황).
  4. `Support/Info.plist`에 `CFBundlePackageType`(`APPL`)·`UISupportedInterfaceOrientations`
     (`UIInterfaceOrientationPortrait`만, 세로 고정)가 없으면 각각 별도 업로드 실패 사유가 된다 —
     V1은 `GENERATE_INFOPLIST_FILE = YES` + `INFOPLIST_KEY_*` 빌드 설정으로 이 키들을 자동 주입받는
     구조라 V1 Info.plist엔 이 키들이 안 보인다(V2와 전략이 다름, 헷갈리지 말 것) — V2는 `Support/Info.plist`가
     리터럴 `.file(path:)`라 이 키들을 **직접** 파일에 적어야 한다.
  5. **`agvtool`(fastlane `increment_build_number`) 기반 빌드 번호 자동 증가가 동작하려면 Apple
     Generic Versioning이 필요하다** — `Project.swift`의 App 타깃 전용 `appBaseSettings`에
     `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION`/`VERSIONING_SYSTEM: "apple-generic"`를 두고,
     `Support/Info.plist`의 `CFBundleShortVersionString`/`CFBundleVersion`이 각각
     `$(MARKETING_VERSION)`/`$(CURRENT_PROJECT_VERSION)`을 참조하게 한다(`env.baseSetting`은 전
     모듈 공유라 여기 안 넣고 App 타깃 전용 딕셔너리로 분리).
     ⚠️ **`agvtool`은 아카이브를 돌릴 때마다 `Support/Info.plist`의 `CFBundleVersion`에 플레이스홀더
     대신 실제 빌드 번호를 리터럴로 직접 써넣는다** — 로컬에서 `archive-debug`/`archive-release`를
     돌린 뒤 `git status`로 이 파일이 바뀌어 있으면, 커밋 전에 `$(CURRENT_PROJECT_VERSION)`으로
     되돌려놓을 것(안 그러면 다음 빌드 번호 계산과 어긋나는 값이 레포에 고정 커밋된다).
  6. `fastlane/Fastfile`에서 `increment_build_number`에 `xcodeproj:` 경로를 상대경로로 주면
     (`"../Projects/App/WSS-iOS.xcodeproj"`) `match` 실행 이후 어떤 이유로 작업 디렉토리가 달라져
     "Could not find Xcode project"로 실패할 수 있었다(정확한 원인 미확인) — `File.expand_path(...,
     __dir__)`로 절대경로를 계산해 cwd에 안 흔들리게 고정했다(`Fastfile` 상단 `XCODEPROJ_PATH` 상수).
