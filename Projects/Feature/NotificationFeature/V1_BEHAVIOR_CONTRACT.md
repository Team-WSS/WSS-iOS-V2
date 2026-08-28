# NotificationFeature — V1 동작 계약 (V1 Behavior Contract)

> **이 문서는 무엇인가** — 운영 중인 **V1**(`Team-WSS/WSS-iOS`, UIKit·RxSwift)의 알림 화면들이
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
- V1 경로 접두사 생략형:
  - `…/HomeNotification/` = `WSSiOS/Source/Presentation/Home/HomeNotification/`
  - `…/HomeNotificationDetail/` = `WSSiOS/Source/Presentation/Home/HomeNotificationDetail/`
  - `…/Data/` = `WSSiOS/Source/Data/`, `…/Network/` = `WSSiOS/Network/`

## 화면 매핑 (V1 → V2)

| V2 (이 모듈) | V1 원본 | 성격 차이 |
|---|---|---|
| `Sources/NotificationList/` (알림 목록) | `…/HomeNotification/` (`HomeNotificationViewController`+VM+View+Cell) | 홈 알림 벨에서 push. 커서 무한 스크롤 리스트 |
| `Sources/NotificationDetail/` (알림 상세) | `…/HomeNotificationDetail/` (`HomeNotificationDetailViewController`+VM+View+ContentView) | 목록에서 push. 제목·작성시각·본문 읽기 전용 |

- 두 화면 모두 **V1에 실재**했다(에이전트 기본 매핑의 "V1에 알림 화면 없을 수 있음"은 오류).
- Data 계약(엔드포인트·읽음 처리·페이지네이션)은 V1 `…/Data/Repository/NotificationRepository.swift`·`…/Network/Notification/NotificationService.swift`, V2 `Projects/Data/NotificationData/`에 산다.

---

## 0. 점검 대기 요약

**판정 상태(2026-08-28 갱신)** — 모든 항목에 배지가 달려 있고 본문 각 절의 확정 배지와 일치한다. **판정 대기 0건.** 배지: ✅유지 · 🔧개선/고치기/미배선(되살리기·수정은 `docs/TODO.md` 12절에 구현 대기, 미배선은 App 배선 시 해소) · 🔨회귀 수정 · 🗑삭제 · ⏳⏸보류(`docs/PENDING_DECISIONS.md`) · 🆕V2 신규.

1. **재진입 시 서버 재동기화 상실** — V1 목록/상세는 **`viewWillAppear`마다 전체를 처음부터 재조회**한다(로딩뷰 포함). V2는 `hasLoaded` 1회 가드로 **성공 후 재조회하지 않는다**. 낙관 읽음 반영이 "방금 탭한 알림 읽음 표시"는 대체하지만, **상세/피드에서 목록으로 복귀하는 사이 서버에서 바뀐 것**(새로 온 알림·다른 기기 읽음)은 반영되지 않는다. push 화면이라 홈 벨로 새로 진입할 땐 매번 fresh VM이라 무해하나, 복귀 창은 미반영. → [1.1](#11-진입생명주기)
   - **🔧 확정(2026-08-28, 사용자): 재진입 재조회 복원.** push 복귀 시에도 서버 재조회하기로 결정(횡단 — 타유저 프로필·작품상세와 함께). C1 범위 밖 구현이라 `docs/TODO.md` 9. 스크롤·낙관 반영 보존은 화면별 조정.
2. **상세 본문 링크 자동 감지 상실** — V1 상세 본문은 `UITextView` + `dataDetectorTypes = .link`라 **본문 안 URL이 탭 가능한 링크**로 뜬다. V2는 순수 `Text(detail.body)`라 평문 URL이 자동 링크되지 않는다(SwiftUI `Text`는 마크다운 링크만 렌더). 공지·이벤트 알림 본문에 링크가 실리면 차이가 드러난다. 없앤 근거를 못 찾음. → [2.3](#23-콘텐츠-표현)
   - **🔧 확정(2026-08-28, 사용자): 되살린다(자동 링크).** `AttributedString` 링크 감지로 복원. 선행 확인: 서버 알림 본문에 실제 링크가 실리는지. `docs/TODO.md` 9.

**🔧 눈에 띄는 의도적 변경 (근거 확인)**

3. 🔧 **Improve 확정** (2026-08-28, 사용자: read 실패해도 피드는 열려야 함) — **비공지 미읽음 탭의 네비게이션이 read 완료에 종속(V1) → 독립(V2)**. V1은 미읽음 피드 알림을 탭하면 **read POST가 성공해야(`onCompleted`) 피드 상세로 push**한다 — read가 네트워크 실패로 끝나면 **피드가 아예 안 열린다**. V2는 read를 fire-and-forget으로 보내고 화면 전환은 즉시 한다. → [1.3](#13-셀-탭--읽음-처리--딥링크-핵심)
4. ⏸ **보류** (2026-08-28, 사용자: 그런 알림이 실존하는지·목적지(공지 상세?)가 의문 — [`PENDING_DECISIONS.md`](../../../docs/PENDING_DECISIONS.md) 8) — **feedId 없는 비공지 알림**: V1은 `feedId ?? -1`로 **피드 -1(존재하지 않는 피드)로 push**한다(깨진 화면). V2는 `.unknown`으로 **전환하지 않는다**. → [1.3](#13-셀-탭--읽음-처리--딥링크-핵심) · 부록
5. 🔧 **Improve(신규) 확정** (2026-08-28, 사용자) — **작품 딥링크(`.novelDetail`) 신규** — V1엔 `novelId` 개념 자체가 없다(DTO에 필드 없음, 라우팅은 공지/피드 2갈래뿐). V2는 완결·휴재 복귀 알림을 작품 상세로 보낸다(#181). → [1.3](#13-셀-탭--읽음-처리--딥링크-핵심) · 부록

**🔧 V1엔 없던 방어를 V2가 신설 (묶음)**

6. 🔧 **Improve(신설 묶음)** — V1 목록/상세엔 **빈 상태·에러 표현·인증 만료 라우팅이 전혀 없었다**(목록 에러는 `print`만, 상세 에러는 무처리). V2가 전면 실패 뷰+재시도·더보기 토스트·빈 뷰·로그인 라우팅을 신설. → [1.5](#15-빈-화면), [1.6](#16-에러토스트), [2.2](#22-로딩에러)

---

## 1. 알림 목록 (NotificationList)

원본: `…/HomeNotification/HomeNotificationViewModel/HomeNotificationViewModel.swift`, `.../HomeNotificationViewController/HomeNotificationViewController.swift`, `.../HomeNotificationView/…`

### 1.1 진입·생명주기

- 🔧 **복원 확정→TODO** (push 재진입 재조회 복원 — 12절) — V1은 **`viewWillAppear`마다** `isLoadable=false`·`isFetching=false`·`lastNotificationId=0`으로 리셋하고 로딩뷰를 세운 뒤 **첫 페이지부터 전체 재조회**한다. 최초 1회 가드 없음.
  - **V2: `hasLoaded` 1회 가드 — 성공 시에만 소진하고 재진입해도 재조회하지 않는다.** push 화면이라 홈 벨 재진입 시엔 새 VM으로 fresh하지만, 상세/피드에서 이 목록으로 복귀할 땐 재조회가 없다. V2 CLAUDE.md에 "목록 로드: 진입 1회(hasLoaded 가드, 성공 시만 소진)"로 명문화.
  - **관찰 동작 차이 3가지**: (i) 복귀 시 로딩 스피너가 뜨지 않는다(V2 개선), (ii) 방금 탭한 알림 읽음 표시는 **낙관 반영**으로 유지(V1은 재조회로 반영 — [1.3](#13-셀-탭--읽음-처리--딥링크-핵심)), (iii) 그 사이 서버에서 바뀐 것은 반영 안 됨(V1은 반영).
  - 근거: V1 `HomeNotificationViewController.swift:41-50`, `HomeNotificationViewModel.swift:55-76` · V2 `NotificationListViewModel.swift:120-123`(hasLoaded 가드), `CLAUDE.md`(진입 1회), `NotificationListView.swift:68`(onAppear→.load)
  - **판정 근거**: 되살리기로 확정(횡단 push 재진입 재조회 결정). 낙관 반영은 유지하되 복귀 시 서버 재동기화를 더한다. (참고: 알림 목록은 **탭 콘텐츠가 아니라 push 화면**이라 Feature CLAUDE.md의 "탭 복귀마다 갱신" 계약 대상이 아니었다 — 그래서 별도 결정이 필요했다.)

### 1.2 목록 로드·페이지네이션

- ✅ **Keep** — 커서 무한 스크롤: 커서는 **마지막으로 받은 알림의 `notificationId`**(초기 V1 `0`/V2 `nil`), 종료 판단은 서버 응답의 `isLoadable`. 페이지 크기 **20**(양쪽 동일).
  - V2: 구현 수단 변경 — V1 RxSwift `flatMapLatest` + `isFetching` 가드 → V2 구조적 동시성(`loadTask == nil` 가드 + 커서 `lastNotificationID`). 관찰 동작(다음 페이지 append·종료 판정)은 같다.
  - 근거: V1 `HomeNotificationViewModel.swift:20-22`,`98-121`, `…/Data/Repository/NotificationRepository.swift:67`(size 20) · V2 `NotificationListViewModel.swift:66-73`,`132-139`,`208-228`
- ✅ **Keep** — 무한 스크롤 발화 조건.
  - V2: 수단 변경 — V1은 스크롤 오프셋 임계값(`contentOffset.y + bounds.height + 1.0 >= contentSize.height`, `distinctUntilChanged`), V2는 마지막 셀 `onAppear`.
  - 근거: V1 `HomeNotificationViewController.swift:75-84`,`131-139` · V2 `NotificationListView.swift:225-229`
- ✅ **Keep** — 진행 중 중복 요청 가드(V1 `isFetching`, V2 `loadTask == nil`).
  - 근거: V1 `HomeNotificationViewModel.swift:99-104` · V2 `NotificationListViewModel.swift:133-138`

### 1.3 셀 탭 — 읽음 처리 + 딥링크 (핵심)

V1은 셀 탭을 `isNotice` → `isRead` 3분기로 라우팅한다. **딥링크 목적지는 공지 상세 / 피드 상세 2종뿐**이고, 낙관 읽음 반영은 하지 않는다(읽음은 재진입 재조회로만 반영). → 근거: V1 `HomeNotificationViewModel.swift:78-96`

- ✅ **Keep** — **공지 알림(`isNotice=true`) → 알림 상세로 push, read POST는 보내지 않는다**(서버가 `GET /notifications/{id}` 조회로 읽음 처리까지 겸함).
  - V2: `.notificationDetail` → `onNotificationSelected`, read 생략. 동일한 이유를 코드 주석·`NotificationData/CLAUDE.md`(실서버 실측)로 남김.
  - 근거: V1 `HomeNotificationViewModel.swift:84-85` · V2 `NotificationListViewModel.swift:146-150`, `NotificationData/CLAUDE.md`(GET 상세가 읽음 처리 겸함)
- ✅ **Keep** — **피드 알림(`isNotice=false`) → 피드 상세로 push**.
  - V2: 매퍼가 `feedId`를 `.feedDetail`로 옮기고 `onFeedSelected` 발화.
  - 근거: V1 `HomeNotificationViewModel.swift:86-93` · V2 `NotificationMapper.swift:32-33`, `NotificationListView.swift:216-217`
- 🔧 **Improve 확정** (2026-08-28, 사용자) — **작품 딥링크(`.novelDetail`) 신규**. V1엔 `novelId`가 DTO에도 없고(공지/피드 2갈래) 작품 상세로 가는 경로가 없다. V2는 응답 `novelId`(작품 알림, `isNotice: false`)를 `.novelDetail`로 매핑해 작품 상세로 보낸다(#181에서 연결).
  - ⚠️ V2 CLAUDE.md·NotificationDomain CLAUDE.md에 **매퍼 우선순위(`isNotice → feedId → novelId → unknown`)가 "작품 알림은 `isNotice: false`로 온다"는 서버 스펙에 기댄다**는 함정과, **실서버에서 값이 채워진 샘플을 아직 못 봤다**는 미검증이 명시돼 있다.
  - 근거: V1 (해당 없음 — `…/Data/DTO/Notification.swift:16-25`에 novelId 필드 없음) · V2 `NotificationResponse.swift:22`, `NotificationMapper.swift:34-37`, `CLAUDE.md`(작품 알림), `NotificationDomain/CLAUDE.md`(매퍼 우선순위 함정)
- ⏸ **보류** (2026-08-28, 사용자: 실존 여부·목적지 의문 — [`PENDING_DECISIONS.md`](../../../docs/PENDING_DECISIONS.md) 8) — **feedId 없는 비공지 알림 처리**. V1은 무조건 `pushToFeedDetailViewController.accept(notification.feedId ?? -1)` — feedId가 nil이면 **피드 `-1`(존재하지 않는 피드)로 push**한다(깨진 상세). V2는 매퍼가 `.unknown`으로 떨어뜨려 **화면 전환을 하지 않는다**(읽음 처리만 한다).
  - 근거: V1 `HomeNotificationViewModel.swift:87`,`91`(`feedId ?? -1`) · V2 `NotificationMapper.swift:38-39`, `NotificationListView.swift:220-221`
- 🔧 **Improve** — **낙관 읽음 반영**. V1은 탭 시 목록 셀을 즉시 읽음으로 바꾸지 않는다(읽음 배경색은 read POST 성공 후 **재진입 재조회**로만 반영). V2는 탭 즉시 `applyReadState`로 셀을 읽음으로 교체하고, 실패해도 롤백하지 않는다.
  - **관찰 결과("돌아오면 읽음")는 결국 같지만, V2는 즉각적이고 read POST 실패와 무관하게 읽음 표시가 남는다**(재진입 시 서버 값으로 재동기화). V2 CLAUDE.md에 "실패해도 롤백하지 않는다"로 명문화.
  - 근거: V1 (낙관 반영 코드 없음 — 재조회 의존, `HomeNotificationViewModel.swift:55-76`) · V2 `NotificationListViewModel.swift:143-179`, `CLAUDE.md`(읽음 실패 시 롤백 안 함)
- 🔧 **Improve 확정** (2026-08-28, 사용자) — **비공지 미읽음 탭의 네비게이션이 read 완료에 종속(V1) → 독립(V2)**. V1은 미읽음(`isNotice=false && !isRead`) 피드 알림에서 `postNotificationRead(...).subscribe(onCompleted: { push feed })` — **read POST가 성공해야 피드로 push**한다. read가 네트워크 실패로 끝나면 `onCompleted`가 오지 않아 **피드가 아예 안 열린다**. V2는 read를 fire-and-forget(`Task`)으로 보내고 화면 전환은 즉시 한다.
  - 근거: V1 `HomeNotificationViewModel.swift:88-94` · V2 `NotificationListViewModel.swift:143-163`(read와 전환 분리), `NotificationListView.swift:211-223`
- ✅ **Keep** (경미 차이) — **read POST 전송 대상**. V1은 **비공지 & 미읽음**일 때만 POST(이미 읽음이면 스킵). V2는 상세 딥링크가 아닌 전 케이스(feed/novel/unknown)에서 POST하되 `markedAsReadIDs`로 셀당 1회로 가드 — 이미 읽은 피드 알림도 첫 탭 시 POST가 한 번 더 나갈 수 있으나 **서버가 idempotent라 무해**. 관찰 동작(읽음 처리 결과)은 같다.
  - 근거: V1 `HomeNotificationViewModel.swift:86-94` · V2 `NotificationListViewModel.swift:159-163`

### 1.4 셀 표현 (관찰 동작만)

- ✅ **Keep** — **읽음/미읽음을 셀 배경색으로 구분**: 읽음 `wssWhite`, 미읽음 `wssPrimary20`. 뱃지·점 없음.
  - 근거: V1 `HomeNotificationTableViewCell.swift:117` · V2 `NotificationListView.swift:162`, `CLAUDE.md`(배경색 구분)
- ✅ **Keep** — 제목 **1줄 말줄임**(title2), 날짜(body5·gray200).
  - 근거: V1 `HomeNotificationTableViewCell.swift:101-115` · V2 `NotificationListView.swift:139-154`
- 🔧 **Improve** — **본문 말줄임 줄 수 1줄 → 2줄**. V1 본문 라벨은 `numberOfLines = 1`. V2는 `lineLimit(2)`(시안 근거: 본문 최대 34 = 2줄).
  - 근거: V1 `HomeNotificationTableViewCell.swift:107-111`(body 1줄) · V2 `NotificationListView.swift:147-149`, `CLAUDE.md`(본문 최대 2줄)
- ✅ **Keep** (표현 수단 변경) — 아이콘은 **서버 이미지**. V1은 36 이미지뷰(radius 12, `scaleAspectFill`, `imgLoadingThumbnail` placeholder)에 서버 이미지를 그대로 채운다. V2는 **36 배경 캡슐(radius 12, wssPrimary20) + 27 이미지**로 바꿨다 — V2 CLAUDE.md에 "서버가 배경 없는 글리프만 준다(실서버 실측)"는 근거가 있다. 아이콘 출처(서버)와 표시 자체는 유지.
  - 근거: V1 `HomeNotificationTableViewCell.swift:47-52`,`98-99` · V2 `NotificationListView.swift:169-185`, `CLAUDE.md`(아이콘 캡슐)

### 1.5 빈 화면

- 🔧 **Improve** — **빈 상태 신설**. V1엔 빈 상태 처리가 **없다**(알림이 0건이면 빈 테이블만 남는다 — 전용 빈 뷰 없음). V2는 `WSSEmptyView(type: .notification)`("아직 도착한 알림이 없어요", CTA 없음)를 그린다(#181에서 확정).
  - 근거: V1 (빈 뷰 없음 — `HomeNotificationView.swift`에 테이블·로딩뷰만) · V2 `NotificationListView.swift:84-86`, `CLAUDE.md`(빈 상태 CTA 없음)

### 1.6 에러·토스트

- 🔧 **Improve** — **목록 로드 실패 표현 신설**. V1은 목록 로드 에러를 `print("Error fetching notifications: …")` + 로딩뷰 숨김만 한다 — **전면 뷰·토스트·재시도 어느 것도 없다**(첫 페이지·더보기 구분도 없음). V2는 **첫 페이지 실패 → `NetworkErrorView`+재시도**(네비바만 남김), **더보기 실패 → 토스트**로 분화.
  - 근거: V1 `HomeNotificationViewModel.swift:72-75` · V2 `NotificationListViewModel.swift:229-241`, `NotificationListView.swift:80-83`, `CLAUDE.md`(에러 분화)
- 🔧 **Improve** — **인증 만료 → 로그인 라우팅 신설**. V1 목록 VM엔 화면 단위 인증 만료 분기가 없다(토큰 재발급은 `tokenCheckURLSession` 네트워크 계층이 담당). V2는 `authenticationRequired`를 걸러 `onAuthenticationRequired`로 라우팅(Feature 공통 계약, 실패 플래그보다 먼저 `return`).
  - 근거: V1 `…/Network/Notification/NotificationService.swift:43`(tokenCheckURLSession), `HomeNotificationViewModel.swift:72-75`(catch=print) · V2 `NotificationListViewModel.swift:232`,`266-272`, `Feature/CLAUDE.md`(인증 만료 처리 계약)

### 1.7 로딩 처리

- ✅ **Keep** (재진입 로딩은 1.1과 연동) — 첫 페이지 로드 시 전체 로딩뷰를 세운다. 더보기(다음 페이지)는 로딩뷰를 세우지 않는다.
  - V2: 첫 로드 `isLoading`(`LoadingView`), 더보기는 하단 `ProgressView`. **차이는 재진입**: V1은 매 `viewWillAppear`마다 로딩뷰를 다시 세우지만(전체 재로드), V2는 1회 로드라 복귀 시 로딩뷰가 없다(1.1의 🔧 참고).
  - 근거: V1 `HomeNotificationViewModel.swift:60`,`71`, `HomeNotificationView.swift:72-76` · V2 `NotificationListViewModel.swift:26-27`, `NotificationListView.swift:80-81`,`112-116`

### 1.8 뒤로가기·네비게이션

- ✅ **Keep** — 커스텀 네비바(중앙 "알림" 타이틀 + 뒤로가기 `icNavigateLeft` 검정) + 스와이프 뒤로가기.
  - V2: `WSSNavigationBar(title: "알림")` + `enableSwipeBack()`. V1의 `setWSSNavigationBar` + `swipeBackGesture()`와 같은 구성.
  - 근거: V1 `HomeNotificationViewController.swift:44-47`, `HomeNotificationView.swift:37-39` · V2 `NotificationListView.swift:62-78`
- ✅ **Keep** (수단 변경) — 뒤로가기 **중복 pop 방지**. V1은 back 버튼에 `throttle(.seconds(3), latest: false)`을 걸어 연타를 막는다. V2는 명시 throttle 없이 `NavigationStack`의 `dismiss()`가 중복을 흡수한다(서재 셀 선택 더블탭 가드와 같은 사안 — NavigationStack이 처리).
  - 근거: V1 `HomeNotificationViewController.swift:123-128` · V2 `NotificationListView.swift:78`(dismiss)

---

## 2. 알림 상세 (NotificationDetail)

원본: `…/HomeNotificationDetail/HomeNotificationDetailViewModel/HomeNotificationDetailViewModel.swift`, `.../HomeNotificationDetailViewController/…`, `.../HomeNotificationDetailView/…AssistantView/HomeNotificationDetailContentView.swift`

### 2.1 진입·생명주기·읽음 처리

- 🔧 **복원 확정→TODO** (push 재진입 재조회 복원 — 12절) — V1 상세는 `viewWillAppear`마다 `GET /notifications/{id}`를 재발화한다(`flatMapLatest`, 1회 가드 없음). V2는 `hasLoaded` 1회 가드. 상세는 leaf 화면이라 재진입이 드물어 영향은 목록보다 작다.
  - 근거: V1 `HomeNotificationDetailViewModel.swift:44-51`, `HomeNotificationDetailViewController.swift:41-48` · V2 `NotificationDetailViewModel.swift:91-94`
- ✅ **Keep** — **상세 조회가 서버측 읽음 처리를 겸한다**(`GET /notifications/{id}`). 그래서 상세로 오는 알림엔 별도 read POST를 보내지 않는다(양쪽 동일 — [1.3](#13-셀-탭--읽음-처리--딥링크-핵심)).
  - 근거: V1 `…/Network/Notification/NotificationService.swift:51-66`(상세 GET, 별도 read 없음) · V2 `NotificationData/CLAUDE.md`(GET 상세가 읽음 처리 겸함 — 실서버 실측)

### 2.2 로딩·에러

- 🔧 **Improve** — **상세 로딩 표시 신설**. V1 상세 화면엔 로딩뷰가 없다(상세 View에 `loadingView` 자체가 없음 — GET 완료까지 빈 화면). V2는 `isLoading` → `LoadingView`.
  - 근거: V1 `HomeNotificationDetailView.swift`(로딩뷰 없음) · V2 `NotificationDetailViewModel.swift:26-27`, `NotificationDetailView.swift:64-65`
- 🔧 **Improve** — **상세 에러 처리 신설**. V1 상세는 에러 처리가 **전혀 없다** — `subscribe(with:onNext:)`에 `onError`가 없어 GET 실패 시 아무 표시 없이 **빈 화면이 영구 유지**된다. V2는 `loadFailed` → `NetworkErrorView`+재시도, 인증 만료 → 로그인 라우팅.
  - 근거: V1 `HomeNotificationDetailViewModel.swift:44-51`(onError 없음) · V2 `NotificationDetailViewModel.swift:124-131`,`140-144`, `NotificationDetailView.swift:66-67`

### 2.3 콘텐츠 표현

- ✅ **Keep** — 상세 레이아웃: 제목(headline1, 다중 줄, `hangulWordPriority`) → 작성시각(body5·gray200) → 구분선(gray50, 1pt, 좌우 여백 없이 풀폭) → 본문(body2·black). 순서·폰트·색·구분선 풀폭이 동일.
  - 근거: V1 `HomeNotificationDetailContentView.swift:65-99` · V2 `NotificationDetailView.swift:84-118`
- 🔧 **복원 확정→TODO** (자동 링크 복원 — 12절) — **본문 링크 자동 감지 상실**. V1 본문은 `UITextView` + `dataDetectorTypes = .link`(`isEditable=false`, `isScrollEnabled=false`)라 **본문 안 URL이 탭 가능한 링크**로 렌더된다. V2는 순수 `Text(detail.body)`라 평문 URL이 자동 링크되지 않는다(SwiftUI `Text`는 `AttributedString`/마크다운 링크만 인식). 공지·이벤트 알림 본문에 링크가 실리면 차이가 드러난다.
  - 근거: V1 `HomeNotificationDetailContentView.swift:50-55`(dataDetectorTypes = .link) · V2 `NotificationDetailView.swift:110-113`(plain Text)
  - **판정 근거**: 되살리기로 확정(누락된 유지). 선행 확인: 서버 알림 본문에 실제 링크가 실리는지.

### 2.4 뒤로가기·네비게이션

- ✅ **Keep** — 커스텀 네비바(중앙 "알림" 타이틀 + 뒤로가기) + back 중복 pop 방지. V1은 back 버튼 `throttle(.seconds(3))`, V2는 `NavigationStack` `dismiss()`가 흡수(1.8과 동일).
  - 근거: V1 `HomeNotificationDetailViewController.swift:44-45`,`77-82` · V2 `NotificationDetailView.swift:50-62`

---

## 부록 A. 서버 요청·라우팅 매핑 (C2 비교 재료)

### A.1 엔드포인트 (전부 동일 경로 — ✅ Keep)

| 용도 | V1 경로 | V2 경로 | 상태 |
|---|---|---|---|
| 목록 조회 | `GET /notifications` `?lastNotificationId&size` | `GET /notifications` (`NotificationQuery{lastNotificationId,size}`) | ✅ Keep |
| 상세 조회 (읽음 처리 겸함) | `GET /notifications/{id}` | `GET /notifications/{id}` | ✅ Keep |
| 읽음 처리 | `POST /notifications/{id}/read` | `POST /notifications/{id}/read` | ✅ Keep |
| 미읽음 상태 | `GET /notifications/unread` | `GET /notifications/unread` | ✅ Keep (홈 벨용 — 이 화면 아님) |

- size는 V1 Repository 상수 `20`, V2 Feature 상수 `pageSize = 20` — 동일.
- 근거: V1 `…/Resource/Constants/URLs/URLs.swift:176-184`, `…/Network/Notification/NotificationService.swift:28-49` · V2 `NotificationEndpoint.swift:32-40`, `NotificationQuery.swift:13-16`, `NotificationListViewModel.swift:73`

### A.2 응답 → 화면 라우팅 (셀 탭 목적지)

| 응답 조건 | V1 라우팅 | V2 라우팅 | 상태 |
|---|---|---|---|
| `isNotice == true` | 알림 상세 push | `.notificationDetail` | ✅ Keep |
| `isNotice == false`, `feedId` 有 | 피드 상세 push | `.feedDetail` | ✅ Keep |
| `isNotice == false`, `novelId` 有 | (개념 없음) | `.novelDetail` | 🔧 신규 (#181) |
| `isNotice == false`, feedId·novelId 無 | 피드 `-1` push(깨짐) | `.unknown` (전환 없음) | 🔧 Improve |

- V1 라우팅은 `isNotice` → `isRead`로 갈리고 목적지는 공지/피드 2종. V2는 매퍼가 `isNotice → feedId → novelId → unknown` 우선순위로 `NotificationDeeplink`를 만든다.
- 근거: V1 `HomeNotificationViewModel.swift:78-96` · V2 `NotificationMapper.swift:29-40`, `NotificationDeeplink.swift:11-18`

### A.3 읽음(read POST) 전송 조건

| 케이스 | V1 | V2 |
|---|---|---|
| 공지 → 상세 | 안 보냄 (서버 GET이 처리) | 안 보냄 (서버 GET이 처리) — ✅ 동일 |
| 비공지 · 이미 읽음 | 안 보냄 | 보냄(첫 탭 1회, 무해) |
| 비공지 · 미읽음 | **read 성공 후** 피드 push | read fire-and-forget + 즉시 전환 |

- 근거: V1 `HomeNotificationViewModel.swift:84-94` · V2 `NotificationListViewModel.swift:143-163`
