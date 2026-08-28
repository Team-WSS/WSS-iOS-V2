<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# HomeFeature

앱의 홈(탭) 화면 — 오늘의 발견 / 추천글(지금 뜨는 글) / 선호 장르 작품을 한 화면에 모아 보여준다.
(`RecommendationDomain`엔 관심 피드도 있지만 **홈엔 그 섹션이 없다** — 아래 주의사항 참고.)

- 식별자: `ModuleType.feature(.home)` / 의존: `BaseDomain`, **`RecommendationDomain`**(홈의 Domain 코드가
  별도 `HomeDomain`이 아니라 여기 있음 — `LoadHomeDataUseCase`·`HomeData`·`TodayDiscovery`·`TrendingFeed`·
  `PreferenceGenreNovelState`), **`NotificationDomain`**(알림 벨 배지), `DesignSystem`, `WSSComponent`, `Logger`,
  `PushAuthorization`(#193 — 알림 벨 탭 시 시스템 권한 확인용)
- 진입점: `HomeFeatureFactory.makeView(loadHomeDataUseCase:loadUnreadNotificationStatusUseCase:
  pushAuthorizationChecker:logger:onNovelSelected:onFeedSelected:onSearchTapped:onDetailSearchTapped:
  onNotificationTapped:onPreferenceGenreSettingTapped:onAuthenticationRequired:)` —
  **탭 콘텐츠만** 반환(탭바·화면 전환은 App 몫)

## 핵심 시나리오

- **로드**: `onAppear`마다 `.load` → `LoadHomeDataUseCase`(추천 3종)와 `LoadUnreadNotificationStatusUseCase`
  (알림 배지)를 **`async let`으로 동시에** 부른다. 하나라도 실패하면 홈 전체가 실패다.
  추천 3종도 UseCase 안에서 동시 호출이라, 홈 진입 시 **총 4건이 한꺼번에 나간다**(순차로 펴지 말 것 →
  [RecommendationDomain](../../Domain/RecommendationDomain/CLAUDE.md)에 퇴행 이력과 컴파일 함정이 있다).
- **섹션 4개**: 검색바·상세검색 배너 / 오늘의 발견(가로 캐러셀) / {닉네임}님을 위한 추천글(2개씩 3페이지) /
  이 웹소설은 어때요?(2열 그리드, 선호장르 미설정이면 설정 유도 CTA).
- 선택 결과는 전부 콜백으로 상위에 위임한다 — 이 화면은 스스로 화면을 전환하지 않는다.
- **홈 진입마다 시스템 푸시 권한을 확인, notDetermined면 그 자리에서 시스템 프롬프트(#193)**:
  `onAppear`의 `.load`와 별도로 `.checkPushAuthorizationOnEntry`를 함께 보낸다. 회원가입 직후 첫 홈
  진입이 유저가 이 앱에서 처음 겪는 알림 권한 결정 시점이 되게 하려는 의도 — **온보딩 별도 단계로
  권한을 요청할 필요가 없다.** `authorized`/`denied`면 진입 시점엔 아무 것도 안 한다(denied 유도
  알럿은 아래 벨 탭 때만 — 진입만으로 매번 알럿을 띄우면 홈에 올 때마다 거슬린다).
- **알림 벨 탭 → 이동 신호만 올린다(#193, App으로 이관)**: `notificationBellTapped()`는
  `shouldNavigateToNotifications`만 세워 `onNotificationTapped()`를 바로 발화시킨다 — 권한 확인·denied
  유도 알럿은 더 이상 이 화면(HomeFeature) 책임이 아니다. **알럿은 이동한 뒤의 알림 목록 화면 쪽에서
  App(`HomeRootView`)이 직접 판단·표시한다** — `showWSSAlert`가 `.overlay` 기반이라 push 전환과
  **동시에** 띄우면(구 설계) 그 전환에 밀려 사라지기 때문(`SettingFeature`의 알림 설정 메뉴가 이 함정을
  반대 방향으로 피한 선례 — 그쪽은 먼저 알럿을 보여주고 `denied`면 아예 이동시키지 않는다). Home은
  "결국 이동은 항상 일어난다"는 설계라 그 회피가 안 통해, **알럿을 이동 목적지(App이 소유한
  `NavigationStack`) 쪽으로 옮기는 쪽을 택했다**(2026-08, 실사용 중 알럿이 홈에서만 뜨고 이동이 안
  되는 것처럼 보인다는 리포트로 발견). `notDetermined`는 여전히 `checkPushAuthorizationOnEntry`(아래)가
  홈 진입 시점에 처리하므로 벨 탭 시점엔 신경 쓰지 않는다. 서버 저장값(설정 화면의 `isNotificationOn`)과는
  무관한 iOS 자체 권한이라, 이 화면의 알림 배지(`hasUnreadNotifications`)와도 별개다.
  ⚠️ **위 진입 시점 체크 덕분에, 이 벨 탭 시점엔 이미 `authorized`/`denied`로 확정돼 있는 게 보통이다**
  — `notDetermined` 분기는 진입 체크가 아직 안 끝난 채 유저가 아주 빠르게 벨을 누르는 등의 방어적
  경로로만 남는다. 같은 이유로 `SettingFeature`의 알림 설정 화면도 진입 시 `notDetermined`를 만날 일이
  거의 없다 — 이미 홈에서 authorized/denied로 정리된 뒤이기 때문.

## 화면 동작 계약 (#179)

정적 디자인으로는 안 잡혀 **확인받아 확정한 것**만 적는다(정본·컨벤션으로 정해지는 건 제외).

- **시안 2장은 별개 화면이 아니라 한 화면의 상태 변이**다 — "이 웹소설은 어때요?" 섹션만 그리드 ↔
  선호장르 설정 유도 CTA로 갈리고 나머지 노드는 동일하다.
- **헤더(로고+알림 벨)만 고정**이고 검색바부터 스크롤한다(구 WSSiOS `HomeView`가 `headerView`를
  scrollView 밖에 두고 `scrollView.top == headerView.bottom`으로 붙인 구조 그대로).
- **로딩·전면 실패는 헤더만 남기고 그 아래를 통째로 대체**한다(검색바·배너도 함께 사라진다).
  고정 영역과 스크롤 영역의 경계와 일치시킨 것 — `LibraryFeature`가 헤더만 남기는 것과 같은 규칙.
  - ⚠️ **실패는 "갱신(탭 복귀) 실패"에도 적용된다** — 보고 있던 홈이 실패 뷰로 대체된다.
    로딩은 콘텐츠 우선(`isInitialLoading`)이라 **두 분기의 기준이 일부러 다르다**(#179에서 확인).
    실패는 사용자가 알고 재시도할 수 있어야 해서 첫 로드와 같게 다룬다 — "로딩과 맞춰야 일관된다"며
    콘텐츠 우선으로 바꾸지 말 것.
- **섹션이 0건이면 제목까지 통째로 숨긴다**(빈 문구 ❌). 추천 콘텐츠라 "없음"을 굳이 말할 이유가 없다.
  구 WSSiOS도 섹션별 `isHidden`으로 처리했다. 단 선호장르 **미설정**은 빈 상태가 아니라 설정 유도
  CTA(시안 있음)라서 이 규칙과 별개다.
- **발견 카드의 키워드 칩은 표시 전용**(노드명이 `tagLink`지만 탭하지 않는다) — 카드 전체 탭이 작품
  상세로 가므로 칩이 따로 탭되면 경합한다.
- ⚠️ **발견 카드에 `♥ 좋아요 · ★ 별점`은 없는 것이 정본이다.** `/novels/popular` 응답은 **로그인·비로그인
  모두** 11개 키뿐이고 `interestCount`·`novelRating`이 없다(#179 실측). 시안 3장 중 2장에 그려져 있으나
  한 장은 `hidden="true"`이고, 모양이 아래 그리드 셀(거긴 `/novels/taste`가 실제로 내려줌)과 동일해
  **복사 잔재로 확인**했다. **시안에 있다는 이유로 되살리지 말 것.**
- **오늘의 발견 카드 탭 → 작품 상세**(유저 한마디 카드도 마찬가지, 유저 프로필로 가지 않는다).

### 실서버가 주는 개수 (시안과 일치 — #179 실측)

| 섹션 | 개수 | 시안 |
|---|---|---|
| 오늘의 발견 | 3건 | 가로 캐러셀 |
| 추천글(지금 뜨는 글) | 6건 | 2개씩 3페이지 + 인디케이터 3 |
| 선호 장르 작품 | 10건 | 2열 × 5행 |

셋 다 **고정 개수라 페이지네이션이 없다.**

## 주의사항 (작업 중 발견 시 누적)

- 홈 Domain을 찾을 때 `HomeDomain`을 만들지 말 것 — 정본은 `RecommendationDomain/Sources/`다
  (`LibraryFeature`↔`NovelDomain`과 같은 형태의 이름 불일치).
- **홈은 앱에서 손꼽히는 "동시 요청 4건" 지점**이다 → access token이 만료된 채 진입하면 **401도 4건이 동시에**
  난다. 이걸 안전하게 만드는 건 `Networking`의 재발급 직렬화(`SessionRefreshCoordinator`)다 — 그게 없으면
  재발급이 4번 나가 refresh token 회전 때문에 3건이 실패하고 로그아웃된다(#184).
- ⚠️ **`.load`에 "최초 1회" 가드를 넣지 말 것** — 홈은 밖(피드 작성·선호장르 설정·알림 확인)에서 바뀐 값을
  다시 비춰야 해서 **탭 복귀마다 갱신**하기로 정했다(구 WSSiOS도 `viewWillAppear`마다 전체를 다시 불렀다).
  중복 요청은 `loadTask` 가드가 막는다. `LibraryFeature`의 `hasLoaded` 패턴을 그대로 옮겨오지 말 것.
- ⚠️ **홈은 탭 콘텐츠라 VM이 앱 세션 내내 산다** → `requiresAuthentication`을 View가 소비한 뒤
  `.consumeAuthenticationRequired`로 되돌려야 2회차 인증 만료가 삼켜지지 않는다(`LibraryFeature`와 같은 이유).
  그 대가로 콜백이 여러 번 발화할 수 있으니 **`onAuthenticationRequired`는 idempotent해야 한다.**
  **`shouldNavigateToNotifications`(#193, 알림 벨 탭 후 이동 신호)도 같은 이유로 같은 패턴**이다 —
  `.consumeNotificationNavigation`으로 소비하지 않으면 두 번째 벨 탭에서 신호가 다시 안 올라 이동이
  안 된다.
- **`.checkPushAuthorizationOnEntry`도 `.load`처럼 1회 가드가 없다** — 탭 복귀마다 다시 불린다.
  의도적이다: `authorized`/`denied`로 이미 확정된 뒤엔 매번 조회만 하고 아무 것도 안 하니(로컬 시스템
  호출이라 비용도 없음) 가드를 넣을 이유가 없고, 혹시 이 체크가 실행되기 전에 화면이 사라진
  극단적 케이스에서도 다음 재진입이 자연히 다시 시도한다.
- `state.preferenceGenreNovelState`는 **옵셔널**이다 — nil(아직 로드 전)과 `.noGenreSettings`(미설정)를
  섞으면 로딩 중에 "선호장르 설정하기" CTA가 번쩍인다.
- ⚠️ **View는 `state.isLoading`이 아니라 `viewModel.isInitialLoading`을 본다.** 위 두 계약("탭 복귀마다
  갱신" + "로딩은 헤더 아래를 전면 대체")을 각각 읽으면 안 보이지만, 둘이 만나면 **홈에 돌아올 때마다
  이미 그린 화면이 로딩 뷰로 갈아치워진다** — `ScrollView` 정체성까지 바뀌어 스크롤 위치와 추천글
  페이지가 초기화된다. 그래서 전면 로딩은 **보여줄 게 아직 없을 때만**(`isLoading && !hasContent`) 띄운다.
  `isLoading`을 직접 보도록 되돌리지 말 것(#179 리뷰에서 잡힘, NovelDetail도 같은 이유로 데이터 우선 분기).

#### UI 구현에서 실제로 걸린 것들 (#179 시뮬레이터 실측)

- ⚠️ **오늘의 발견 표지의 장르 뱃지는 `icGenreBackground`(흰 코너 삼각형) 위에 `iconImage`(방패)를 얹는
  조합**이다 — 추천글 목록이 쓰는 `markImage`(GenreMark)를 여기 쓰면 큰 삼각형이 표지를 덮는다.
  NovelDetail 표지 뱃지와 같은 구성이고(배경 71 / 아이콘 32 / 인셋 4·5), 여기선 시안 프레임이 56이라
  **같은 비율로 축소**했다(배경 56 / 아이콘 25 / 인셋 3·4).
- ⚠️ **오늘의 발견 카드 배경은 "표지를 흐리게 깔고 `imgNovelBg`를 덮는" 2층**이다
  (구 WSSiOS `HomeTodayPopularCollectionViewCell`의 `backgroundNovelImageView` + `gradation` 정본).
  - ⚠️ **구 WSSiOS의 `imgTodayPopularBackground`를 가져오지 말 것 — V2엔 일부러 안 넣었다.**
    홈/오늘의 인기 전용처럼 보이지만 **알파 255의 불투명** 이미지라 표지를 통째로 가려 배경이 카드마다
    똑같은 그라데이션이 된다(#179에서 실제로 그렇게 만들었다가, 표지가 다른 두 카드의 배경이 픽셀 단위로
    동일함을 실측하고 되돌렸다). **구 WSSiOS에서도 어디에도 안 쓰이는 잔재**다. 필요한 건 알파 217~255의
    **`imgNovelBg`**(292×432, 시안 노드 크기와 일치).
  - ⚠️ **표지는 상단 기준으로 자른다**(`frame(..., alignment: .top)` + `clipped()`) — 시안도 표지를
    `292×433.29`로 `top: 1`에 놓아 아래를 잘랐고, 구 레포도 `alignment = .top`이다. 기본 가운데
    정렬이면 표지의 인상(제목·인물)이 위아래로 잘려 사라진다.
  - 블러는 **코드로 건다**(구 레포도 `asBlurredBannerImage` = `CIGaussianBlur` radius 8 + `CIAffineClamp`).
    ⚠️ 시안의 `backdrop-blur: 6px`(CSS)를 그대로 옮기지 말 것 — SwiftUI `blur`와 단위가 다르다.
    `opaque: true`가 구 레포의 `CIAffineClamp` 역할(없으면 가장자리가 투명하게 번진다).
    ⚠️ 구 레포의 8은 **원본 이미지 픽셀**에 건 값이라 표지 해상도에 따라 세기가 달라진다 — SwiftUI는
    렌더 크기(pt)에 걸리므로 **같은 숫자라도 같은 세기가 아니다.**
- **"이 웹소설은 어때요?" 그리드의 셀 자체는 이 모듈에 없다 — 공용 `WSSNovelGridCell`(WSSComponent)이다.**
  이 화면은 열 개수·간격·좌우 여백만 정하고, 표지 비율·정보 스택 고정 높이(72)·아이콘 색 같은
  셀 내부 함정은 그 컴포넌트 문서가 정본이다. **셀 모양을 고치려고 이 파일을 뒤지지 말 것.**
- ⚠️ **시안의 텍스트 프레임 폭을 그대로 옮기지 말 것** — Figma에서 고정 폭으로 보이는 건 **샘플 문구가
  마침 그 폭을 꽉 채운 결과**인 경우가 많다. 실데이터에서 짧은 값이 오면 빈 자리가 남아 레이아웃이 어긋난다.
  이 화면에서 세 번 걸렸다:
  - **발견 카드의 작가 이름**에 폭 72(시안 프레임)를 줬더니 짧은 작가명일 때 `· 완결작`이 저 멀리
    떨어졌다 → 폭 제한을 빼고 **연재상태를 `fixedSize` + `layoutPriority(1)`로 지킨 뒤 이름만 말줄임**.
  - **그리드 제목**도 시안 폭(140)을 `maxWidth`로 줬었으나, 셀 폭(163)보다 좁아 **표지와 글씨의 오른쪽
    끝이 어긋났다** → 셀 폭을 그대로 쓰도록 폭 제한을 걷어냈다(공용 컴포넌트로 뺄 때 확정).
    폭 제한 없이도 `fixedSize(horizontal: false, vertical: true)`만 있으면 셀 폭에서 두 줄로 꺾인다.
  - **추천글 행의 제목·본문**에 폭 195(시안 프레임)를 줬더니, 그 195는 사실 **375pt 기기의 계산 결과**
    (335 - 28*2 - 64 - 20)라 넓은 기기에서 남는 폭이 텍스트 오른쪽 빈 자리로 남았다. 카드 폭은
    `containerRelativeFrame`으로 기기를 따라가는데 텍스트만 안 따라가니 **행 안의 HStack이 가운데로 몰려
    좌우 여백 28까지 함께 어긋난다**(402pt에서 약 12pt씩). → `frame(maxWidth: .infinity, alignment: .leading)`
    로 남는 폭을 텍스트가 전부 먹게 두면 **표지와의 간격은 그 뒤의 `Spacer().frame(width: 20)`으로
    폭과 무관하게 고정**된다(간격은 stack spacing이 아니라 빈 뷰로 — Feature 레이어 공통 규칙).
- ⚠️ **`maxWidth`는 "상한"이 아니라 "제안된 폭까지 늘어나라"다** — 폭 상한을 걸려고 뷰 자신에
  `.frame(maxWidth:)`를 붙이면, 부모가 더 넓은 폭을 제안하는 순간(카드 292 등) 그 값까지 **부푼다**.
  발견 카드의 키워드 칩이 실제로 그랬다: 글자 길이와 무관하게 전부 폭 120짜리 캡슐이 됐다.
  - **hug시켜야 하는 요소(칩·뱃지)의 상한은 그 요소가 아니라 컨테이너에 건다** — 컨테이너에 걸면
    자식은 폭 *제안*만 받고 제 이상적 크기를 쓰며, 넘칠 때만 `lineLimit(1)`+`truncationMode(.tail)`로
    잘린다(긴 키워드가 120에서 멈추고 표지를 침범하지 않음을 실측).
  - 반대로 **셀 폭을 꽉 채워야 하는 요소(그리드 제목 — 지금은 `WSSNovelGridCell` 안)는 그 확장이 오히려
    필요**해 뷰에 직접 건다. 같은 `maxWidth`라도 붙이는 위치로 의도가 갈리니 위 "시안 텍스트 프레임 폭"
    항목과 함께 볼 것.
- **추천글 페이지 사이에 여백(20)을 넣어야 한 장만 보인다** — 카드가 좌우 여백을 뺀 폭을 꽉 채우므로
  간격이 0이면 다음 페이지가 그 여백만큼 삐져나온다.
  - ⚠️ **카드 폭에 시안 값(375 기준 335)을 상수로 박지 말 것** — 375pt 기기에서만 맞고 393·430pt에서는
    남는 폭만큼(18~55pt) 다음 페이지가 옆에 딸려 보여 "한 장만 보인다" 계약이 깨진다(#179 리뷰에서 잡힘).
    `containerRelativeFrame(.horizontal)`은 **`contentMargins`를 뺀 실제 콘텐츠 폭**을 주므로
    좌우 여백 20이 살아 있는 채로 기기 폭을 따라간다(402pt 시뮬레이터에서 실측 — 스냅도 정상).
- **검색바·배너의 좌우 여백은 20이 아니라 13**이다(아래 추천 섹션들과 다름 — 시안 그대로).
- ⚠️ **Demo/Preview mock은 "옵셔널이니 nil"로 채우지 말고 서버 계약을 지킬 것** — 유저 한마디 카드의
  `Author.profileImage`를 nil로 뒀더니 회색 네모만 그려져 "캐릭터가 왜 안 보이냐"가 됐는데,
  `RecommendationMapper`는 닉네임·아바타 중 **한쪽만 오면 매핑을 실패**시키므로 실서버에선 나올 수 없는
  조합이었다. mock이 실서버에 없는 상태를 그리면 없는 버그를 쫓게 된다.
- **Demo 실서버 모드는 닉네임을 직접 심어야 한다**(`UserDefaultsStorage().set(.nickname, ...)`) —
  실제 앱은 로그인·프로필 조회가 채우지만 Demo는 그 경로를 안 거쳐 제목이 폴백("추천글")으로 나온다.
  ⚠️ 그리고 **`TEST_API_KEY`는 빌드 시점에 앱에 박히므로**, 토큰을 갱신했으면 **재빌드해야** 실서버가 산다.
