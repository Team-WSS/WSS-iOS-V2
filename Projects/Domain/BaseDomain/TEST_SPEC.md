# BaseDomain 테스트 명세

<!-- 자동 생성 파일 — 손으로 고치지 않는다. 갱신: swift run --package-path Tooling/ArchLint ArchLint --write-test-specs . -->

## 매력 포인트

`Tests/Entity/AttractivePointTests.swift`

- 매력 포인트는 디자인이 정한 순서대로 보인다

## 작성자 프로필 이동

`Tests/Entity/AuthorTests.swift`

- 작성자를 알면 그 작성자의 프로필로 이동할 수 있다
- 탈퇴한 작성자의 프로필로는 이동할 수 없다
- 작성자를 모르면 프로필로 이동할 수 없다

## 딥링크

`Tests/Entity/DeepLinkTests.swift`

### 링크 만들기

- 컬렉션 상세 링크는 websoso 스킴, collections 주소, id 하나로 만든다
- 작품·피드·알림 상세는 링크를 만들지 않는다
  - `DeepLink.novelDetail(NovelID(7))` — 푸시로 받기만 한다
  - `.feedDetail(FeedID(7))` — 푸시로 받기만 한다
  - `.notificationDetail(NotificationID(7))` — 푸시로 받기만 한다
- 컬렉션 상세의 카카오 공유 값에는 컬렉션 id 하나만 담는다
- 작품·피드·알림 상세는 카카오 공유 값이 비어 있다
  - `DeepLink.novelDetail(NovelID(7))` — 푸시로 받기만 한다
  - `.feedDetail(FeedID(7))` — 푸시로 받기만 한다
  - `.notificationDetail(NotificationID(7))` — 푸시로 받기만 한다

### 링크 읽기

- 주소가 화면 종류를, 경로의 숫자가 id를 정한다
  - `("websoso://collections/1", DeepLink.collectionDetail(CollectionID(1)))` — 컬렉션 상세. 가장 작은 id도 읽는다
  - `("websoso://novels/22", .novelDetail(NovelID(22)))` — 작품 상세
  - `("websoso://feeds/22", .feedDetail(FeedID(22)))` — 피드 상세
  - `("websoso://notifications/22", .notificationDetail(NotificationID(22)))` — 알림 상세
- 스킴과 주소는 대소문자를 가리지 않는다
- websoso가 아닌 스킴은 읽지 않는다
- 모르는 주소나 주소가 없는 링크는 읽지 않는다
  - `"websoso://comments/22"` — 모르는 주소
  - `"websoso:///22"` — 주소가 없다
- id가 양의 정수가 아니면 읽지 않는다
  - `"abc"` — 숫자가 아니다
  - `"0"` — 서버가 주는 id는 1부터다
  - `"-1"` — 음수다
- id가 없거나 경로가 더 붙어 있으면 읽지 않는다
  - `"websoso://collections"` — id가 없다
  - `"websoso://collections/22/extra"` — id 뒤에 경로가 더 있다

### 카카오톡 링크 읽기

- 카카오톡 링크의 컬렉션 id를 읽어 컬렉션 상세로 간다
- 카카오톡 링크는 스킴이 무엇이든 읽는다
- 카카오톡 링크에 컬렉션 id가 없거나 양의 정수가 아니면 읽지 않는다
  - `"kakao1234abcd://kakaolink"` — 컬렉션 id가 없다
  - `"kakao1234abcd://kakaolink?collectionId=abc"` — 숫자가 아니다
  - `"kakao1234abcd://kakaolink?collectionId=0"` — 서버가 주는 id는 1부터다
  - `"kakao1234abcd://kakaolink?collectionId=-1"` — 음수다

### 푸시 알림 읽기

- 푸시의 화면 종류에 맞는 id로 상세를 연다
  - `(["view": "novelDetail", "novelId": "12345", "feedId": ""], DeepLink.novelDetail(NovelID(12345)))` — 작품 상세. 서버는 다른 id를 빈 값으로 함께 보내기도 한다.
  - `(["view": "feedDetail", "feedId": "42", "novelId": ""], .feedDetail(FeedID(42)))` — 피드 상세
  - `(["view": "notificationDetail", "notificationId": "3853"], .notificationDetail(NotificationID(3853)))` — 알림 상세(공지). 실제 공지 푸시는 알림 id만 있고 작품 id 키는 없다(#243).
- 모르는 화면 종류이거나 화면 종류가 없으면 읽지 않는다
  - `["view": "commentDetail", "novelId": "7"]` — 모르는 화면 종류
  - `["novelId": "7"]` — 화면 종류가 없다
- 화면 종류에 맞는 id가 없거나 양의 정수가 아니면 읽지 않는다
  - `["view": "notificationDetail", "novelId": "7"]` — 화면 종류와 다른 id만 있다
  - `["view": "novelDetail", "novelId": ""]` — id가 비었다
  - `["view": "novelDetail", "novelId": "abc"]` — 숫자가 아니다
  - `["view": "novelDetail", "novelId": "0"]` — 서버가 주는 id는 1부터다
  - `["view": "novelDetail", "novelId": "-1"]` — 음수다

## 작품 관심 등록

`Tests/Entity/NovelTests.swift`

- 관심 작품으로 등록하면 관심 수가 하나 늘어난다
- 이미 관심 작품이면 다시 등록해도 그대로다
- 관심 여부를 모르는 작품은 관심 작품으로 등록하지 않는다
- 관심을 해제하면 관심 수가 하나 줄어든다
- 관심 작품이 아니면 해제해도 그대로다
- 관심 수가 0이면 해제해도 0 아래로 내려가지 않는다
- 관심 작품에서 관심을 전환하면 해제된다
- 관심 작품이 아닐 때 관심을 전환하면 등록된다

## 평점

`Tests/Entity/RatingTests.swift`

- 0.5부터 5.0까지 0.5점 단위면 평점이 된다
  - `0.5` — 가장 낮은 평점
  - `2.5` — 0.5점이 붙은 평점
  - `3.0` — 중간의 정수 평점
  - `5.0` — 가장 높은 평점
- 범위 밖이면 평점이 아니다
  - `0.0` — 가장 낮은 평점보다 0.5점 작다
  - `5.5` — 가장 높은 평점보다 0.5점 크다
- 0.5점 단위가 아니면 평점이 아니다
  - `4.7` — 소수 첫째 자리가 0.5점 단위가 아니다
  - `1.25` — 0.5점보다 잘게 나눴다

## 독서 기간

`Tests/Entity/ReadingPeriodTests.swift`

### 만들기

- 시작일이나 종료일 하나만 있어도 기간이 된다
  - `(yesterday, nil)` — 시작일만 있다
  - `(nil, yesterday)` — 종료일만 있다
- 같은 날이어도 기간이 된다
- 둘 다 없으면 기간이 아니다
- 시작일이 종료일보다 늦으면 기간이 아니다
- 오늘 이후 날짜는 넣을 수 없다
  - `(tomorrow, nil)` — 시작일이 내일이다
  - `(nil, tomorrow)` — 종료일이 내일이다
- 오늘 날짜면 시각이 기준보다 늦어도 넣을 수 있다

### 독서 상태에 맞추기

- 읽는 중이면 시작일만 남긴다
- 읽는 중인데 종료일만 있으면 그 날을 시작일로 옮긴다
- 다 읽음이면 빈 쪽을 채운다
- 다 읽음인데 종료일만 있으면 그 날로 시작일을 채운다
- 하차면 종료일만 남긴다
- 하차인데 시작일만 있으면 그 날을 종료일로 옮긴다

## 앱 리뷰 요청

`Tests/UseCase/AppReviewRequestUseCaseTests.swift`

- 참여가 2번뿐이면 리뷰를 요청하지 않는다
- 참여가 3번이 되면 리뷰를 요청한다
- 이번 버전에 이미 리뷰를 요청했으면 다시 요청하지 않는다
- 리뷰를 요청했다고 기록하면 이번 버전에서는 다시 요청하지 않는다
- 버전이 바뀌면 지난 버전의 참여는 세지 않는다
- 버전이 바뀐 뒤 참여를 기록하면 처음부터 다시 센다
- 새 버전에서 다시 3번 참여하면 지난 버전에 요청했어도 다시 요청한다

## 전체 키워드 불러오기

`Tests/UseCase/LoadTotalKeywordsUseCaseTests.swift`

- 처음 불러오기에 성공하면 동기화하지 않는다
- 불러오기에 실패하면 동기화한 뒤 다시 불러온 결과를 준다
- 동기화한 뒤에도 실패하면 그 에러를 전한다

## 키워드 검색

`Tests/UseCase/SearchKeywordsUseCaseTests.swift`

- 처음 검색에 성공하면 동기화하지 않는다
- 검색에 실패하면 동기화한 뒤 다시 검색한 결과를 준다
- 동기화한 뒤에도 실패하면 그 에러를 전한다
- 묶음별 검색 결과를 키워드 목록 하나로 펼친다
