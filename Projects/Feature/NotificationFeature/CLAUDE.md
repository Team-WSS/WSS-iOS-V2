<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# NotificationFeature

알림 목록·알림 상세 화면. 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.feature(.notification)` / 의존: `BaseDomain`, `NotificationDomain`, `DesignSystem`, `WSSComponent`, `Logger`
- 진입점(둘 다 `NotificationFactory` — 대등한 화면이라 양쪽 다 `makeXxxView`):
  - `makeNotificationListView(loadPagedNotificationsUseCase:markNotificationAsReadUseCase:logger:onNotificationSelected:onFeedSelected:onNovelSelected:onAuthenticationRequired:)` — 홈 알림 벨에서 **push**
  - `makeNotificationDetailView(notificationID:loadNotificationDetailUseCase:logger:onAuthenticationRequired:)` — 목록에서 **push**
- **모듈 안에 `navigationDestination`은 없다** — 목록 → 상세 전환도 콜백으로 올리고 배선은 호출자(App/Demo)가 한다.

## 핵심 시나리오

- **목록 로드**: 진입 1회(`hasLoaded` 가드, 성공 시만 소진) → 커서 무한 스크롤. 커서는 서버 발급 문자열이 아니라
  **마지막으로 받은 `NotificationID`**(`lastNotificationID`)이고, 종료 판단은 응답의 `isLoadable`이다.
- **셀 탭 = 두 가지 일**: ① VM이 읽음 처리 — 목록 표시는 **항상** 낙관 반영하되 `MarkNotificationAsReadUseCase`
  호출은 딥링크에 따라 갈린다(아래 화면 동작 계약), ② View가 `NotificationDeeplink`를 분기해 상위 콜백
  발화(`.notificationDetail`→상세, `.feedDetail`→피드, `.unknown`/nil→전환 없음).
- **에러 분화**: 첫 페이지 실패=전면 `NetworkErrorView`(재시도), 더보기 실패=토스트, 인증 만료=`requiresAuthentication`
  신호 → `onAuthenticationRequired` 콜백(Feature 공통 계약).

## 화면 동작 계약 (#181)

정적 디자인으로는 안 잡혀 **확인받아 확정한 것**만 적는다(정본·컨벤션으로 정해지는 건 제외).

- **시안 2장은 별개 화면**이다(노드명이 둘 다 "알림"이라 헷갈리기 쉽다) — 목록과 상세는 상단 "고정 영역"
  (뒤로가기 + 중앙 "알림" `title2`)만 공유하고 그 아래가 완전히 다르다.
- **읽음/미읽음은 셀 배경색으로만 구분**한다 — 미읽음 `wssPrimary20`, 읽음 `wssWhite`. 뱃지·점 표시는 없다.
  - ⚠️ **구분선(`wssGray50` #F4F5F8)은 미읽음 배경(#F5F7FF) 위에서 거의 보이지 않는다.** 두 값 모두 시안
    그대로라 의도된 결과이고, 시안엔 미읽음이 연속으로 오는 배치가 없어 드러나지 않았을 뿐이다.
    **실서버에서는 미읽음이 연달아 오는 게 기본이라 셀 경계가 실제로 사라진다**(#181 실측 — 안 읽은 알림이
    쌓인 계정에선 목록이 한 덩어리로 보인다). 값을 임의로 진하게 바꾸지 말고, 고칠 거면 디자이너와 정할 것.
- **제목은 1줄 말줄임, 본문은 최대 2줄**(시안 근거: 제목 프레임 높이 22 고정 + 말줄임 샘플, 본문 최대 34=2줄).
- **셀 탭은 두 가지를 동시에** 한다 — 읽음 처리(낙관) + 딥링크 전환. **`.unknown`이어도 읽음 처리는 한다**
  (전환만 없음). 갈 곳이 없다고 탭을 죽이면 미읽음 표시를 지울 방법이 사라진다.
- ⚠️ **읽음 처리 API(`read`)는 상세로 가는 알림엔 보내지 않는다** — 알림 상세 조회(`GET /notifications/{id}`)를
  **서버가 읽음 처리까지 겸하기** 때문이다(→ [NotificationData](../../Data/NotificationData/CLAUDE.md)).
  갈리는 건 **서버 호출뿐**이고 목록 셀의 읽음 표시는 딥링크와 무관하게 전부 즉시 바뀐다(서버도 결국 읽음으로
  만드니 재진입 시 값이 어긋나지 않는다). 반대로 `.feedDetail`·`.novelDetail`·`.unknown`/nil은 상세 API를 타지
  않으므로 **여기서 `read`를 보내지 않으면 영영 미읽음으로 남는다** — "상세도 부르는데 통일하자"며 되돌리지 말 것.
- **읽음 처리가 실패해도 롤백하지 않는다** — 화면은 읽음인 채로 두고 로그만 남긴다. 셀 탭은 대개 화면 전환과
  동시에 일어나 사용자가 이미 다음 화면에 있고, 되돌리면 돌아왔을 때 이유 없이 미읽음으로 복귀한 것처럼 보인다.
  읽음 여부는 재진입 시 서버 값으로 다시 맞춰진다. (NovelDetail 관심 토글의 "실패 시 롤백"과 **일부러 다르다**.)
- **빈 상태는 이미지 + 문구뿐, CTA 없음**("아직 도착한 알림이 없어요" = `WSSEmptyType.notification`). 시안이 없어
  확인받아 정했다 — 알림은 사용자가 직접 만들 수 있는 게 아니라 유도할 행동이 마땅치 않다. 이걸 위해 #181에서
  **`WSSEmptyView`가 `action`을 옵셔널로 받게 고쳤다**(nil이면 버튼과 그 위 간격이 사라진다) — 화면에서 다시 그리지 말 것.
- **아이콘은 서버 이미지**(`NotificationItem.iconURL`)다 — 알림 종류별 로컬 에셋은 DesignSystem에 없다
  (`icAnnouncement`는 홈 알림 벨용). 배경 캡슐(36 / radius 12 / `wssPrimary20`)만 로컬로 그리고 그 안에
  이미지를 27로 얹는다(시안 인셋 4.5).
  - **서버 이미지는 배경 없는 글리프만 온다**(실서버 실측 — #181). 그래서 **배경 캡슐은 반드시 로컬로 그려야**
    하고, 이미지를 배경과 같은 36으로 키우면 캡슐이 가려져 사라진다. 27을 임의로 키우지 말 것.
- **작품 알림(완결·휴재 복귀)은 작품 상세로 간다** — 응답의 `novelId`를 매퍼가 `.novelDetail`로 옮기고
  `onNovelSelected` 콜백이 발화한다(#181에서 연결). 알림 상세 API를 타지 않는 경로라 **`read` 호출도 함께 나간다**.
  ⚠️ **실서버에서 값이 채워진 샘플을 아직 못 봤다** — 테스트 계정 알림이 전부 공지(`isNotice: true`, `novelId: null`)라
  매핑은 `NotificationMapperTests`로만 고정돼 있다. 실제 완결 알림이 오는 계정이 생기면 전환을 눈으로 확인할 것.

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ **`NotificationID`·`FeedID`·`NovelID`는 셋 다 `IDWrapper<Int>`의 typealias라 컴파일러에겐 같은 타입이다** —
  딥링크 세 갈래를 라우팅할 때 `navigationDestination(for: NotificationID.self)`·`FeedID.self`·`NovelID.self`를
  나란히 두면 **먼저 등록된 쪽이 나머지를 다 삼켜** 엉뚱한 화면으로 간다. 호출자는 반드시 **세 경로 모두**
  자체 Route enum으로 감싸야 한다(Demo가 `DemoRoute`로 그렇게 한다).
  ⚠️ `.novelDetail`이 #181에서 열리면서 **이 함정은 이제 실제로 세 갈래다** — 호출자가 셋 다 감싸지 않으면 샌다.
- ⚠️ **목록 로드에 취소·무효화 장치가 일부러 없다** — `reloadFromScratch`가 `loadTask?.cancel()`도, 세대(generation)
  카운터도 쓰지 않는다. 두 호출자(`load`·`retry`)가 모두 `loadTask == nil`을 선행 확인해 **인플라이트 요청이 있는 채로
  재로드가 걸리는 경로 자체가 없기** 때문이다(재시도 버튼은 전면 실패 뷰에서만 보이고 그때 목록은 비어 있다).
  - **재로드 경로를 하나라도 추가하면**(당겨서 새로고침·"전체 읽음"·필터 등) **그날 깨진다** — 늦게 도착한 옛 응답이
    새 목록을 덮는다. 그때는 `cancel()`을 넣는 동시에 **`loadPage`의 `defer`를 걷어내고 정리를 성공·실패 경로로
    옮겨야** 한다(Swift의 취소는 협력적이라 `await` 재개 뒤엔 `catch`·`defer`가 그대로 돈다 — 취소된 로드가
    새 로드의 `loadTask`를 지우고 스피너를 끈다). 그 형태는 서재가 정본이다. → [LibraryFeature](../LibraryFeature/CLAUDE.md)
  - #181 리뷰에서 **세대(generation) 카운터**를 한 번 넣었다가 **지금 쓰이지 않는 배관이라 되돌렸다** — "정본이 쓰니까"를
    근거로 다시 넣지 말 것(서재도 #181에서 세대 카운터를 걷어내고 위 방식으로 바꿨다). 넣을 근거는 정본이 아니라
    **이 화면에 재로드 경로가 생겼다는 사실**이다.
- ⚠️ **목록 중간에 셀 하나 크기의 빈 공간이 뚫리면 "레이아웃 문제"가 아니라 `ForEach` 중복 ID를 의심한다.**
  `listSection`이 `ForEach(..., id: \.element.id)`라, 같은 `NotificationID`가 두 번 들어오면 SwiftUI가 뒤엣것을
  그리지 않고 **자리만 비워 둔다**(에러도 크래시도 없어 페이지네이션 버그처럼 보인다). 빈 공간의 위치가 곧
  **페이지 경계**(20개씩이면 20↔21 사이)라는 게 결정적 단서다. 커서(`lastNotificationID`)는 **exclusive**여야
  한다 — "마지막으로 받은 ID"를 그대로 시작점으로 삼으면 그 항목이 다음 페이지에 다시 실린다.
  #181에서 Demo mock(`DemoNotificationData.pagedItems`)이 실제로 이 off-by-one이었고, 시뮬레이터에서
  20↔21·40↔41 두 곳이 비고 총 50개가 48개로 보였다. **실서버 응답도 같은 형태로 깨질 수 있으니**
  증상을 보면 mock인지 실서버인지부터 가른다(ViewModel엔 중복 제거 방어가 없다 — 지금은 일부러 없는 상태).
- **읽음 처리는 실패해도 롤백하지 않는다** — 같은 셀 재탭은 `markedAsReadIDs`로 막고 로그만 남긴다.
  읽음 여부는 재진입 시 서버 값으로 다시 맞춰지므로, 실패를 토스트로 알리면 화면 전환과 겹쳐 시끄럽다.
  - `markedAsReadIDs` 가드는 **서버 호출 경로에만** 걸린다(상세 딥링크 알림은 애초에 호출하지 않아 집합에
    안 들어간다) — 낙관 반영 쪽 중복은 `applyReadState`의 `!isRead` 가드가 따로 막는다.
- **`NotificationItem`은 전 프로퍼티가 `let`** — 낙관 반영은 `mutating` 정책이 아니라 새 인스턴스 교체로 한다
  (Domain에 `markedAsRead()` 같은 정책 메서드가 없다).
