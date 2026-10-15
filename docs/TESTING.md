# 테스트 가이드

> **AI가 코드를 쓰고, 사람은 테스트를 보고 믿는다.**

## 왜 이렇게 쓰나

구현과 리뷰를 AI가 맡으면서, 사람이 구현 코드를 모두 읽는 일이 병목이 됐다.
그래서 사람이 확인하는 최소 지점을 **테스트**로 잡는다. 테스트 이름이 "이 기능은 이렇게 동작한다"를 말하고,
그 말이 진짜라면 사람은 구현 대신 테스트를 보고 믿을 수 있다.

기준은 문서로만 두지 않는다. 지킬 수 있는 것은 전부 **ArchLint가 검사**한다(규칙 목록과 id →
[Tooling/ArchLint/README.md](../Tooling/ArchLint/README.md)의 "테스트 명세 규칙"). 이 문서는 규칙을 다시 적지 않고,
**규칙의 이유**와 **기계가 못 하는 사람의 판단**, **작업 순서**만 적는다.

## 테스트가 지켜야 할 5가지

1. **읽힌다** — 테스트 이름만 읽어도 그 기능의 규칙을 알 수 있다.
   이름은 "무엇을 하면 어떻게 된다"를 말하는 한국어 문장이다. 메서드 이름·"성공 케이스" 같은 말은 쓰지 않는다.
   본문도 준비 / 실행 / 확인을 빈 줄로 나눠, 무엇을 하고 무엇을 확인하는지 한눈에 보이게 한다.
2. **판단하는 코드를 테스트한다** — 분기·검증·계산이 실제로 들어 있는 코드를 직접 불러서 테스트한다.
   넘기기만 하는 코드는 테스트하지 않는다. 테스트는 그 코드가 있는 모듈에 둔다.
3. **버그가 생기면 테스트가 잡아낼 수 있어야 한다** — 기대값은 정확한 값으로 비교한다.
   `!= nil`처럼 "있다"만 보거나, 소스의 상수를 기대값으로 쓰면 버그가 나도 통과한다.
4. **버그가 아니면 테스트가 깨지지 않아야 한다** — 동작은 같고 구현만 바뀐 리팩터링에는 깨지지 않는다.
   그래서 "어떻게 했는지"(몇 번 불렀는지)가 아니라 바깥에서 보이는 결과(돌려받은 값·바뀐 상태·보낸 요청)를 본다.
   버그도 없는데 빨간불이 자주 켜지면 사람은 빨간불을 믿지 않고 테스트를 같이 고쳐 버린다.
5. **늘 같다** — 언제·어디서·어떤 순서로 돌려도 결과가 같다. 현재 시각·기기 설정·난수·공유 상태에 기대지 않는다.

## 무엇을 테스트하고, 무엇을 안 하나

- **테스트한다**: Entity·Draft의 규칙(검증·정규화·상태 변화), 여러 저장소를 조합하거나 값을 바꾸는 UseCase.
- **테스트하지 않는다**: 저장소 호출을 그대로 넘기는 UseCase, 값만 담는 타입.
  넘기기만 하는 UseCase를 테스트하면 "Mock을 불렀다"만 확인하면서, 이름은 "토큰을 지운다"처럼 다른 레이어의 일을 확인한 것처럼 보이게 된다.
  그 일은 그 레이어(Data)에서 테스트한다.
- **담는 것은 넘기는 것이 아니다.** 규칙이 있는 Entity·Draft가 값을 담는 일(`rating = newRating`)은 그 타입 자신의 일이라
  대신 지켜 줄 곳이 없다. 특히 **옵셔널 값**은 대입을 지워도 `nil`로 조용히 컴파일돼 컴파일러도 못 잡는다
  (NovelReview 평점이 이렇게 뮤테이션에서 살아남았다 — 지워지면 사용자가 매긴 평점이 사라진다).
  애매하면 뮤테이션 도구의 생존 여부로 판단한다.
- 테스트하지 않기로 한 것은 **목록 합의 때 이유와 함께 적는다**. 빠뜨린 것과 뺀 것을 구분하기 위해서다.

## 작업 순서

1. **테스트 목록을 먼저 합의한다** — 스위트 이름, 테스트 이름, 넣지 않는 테스트와 그 이유. 사람이 승인한다.
2. **테스트를 쓰고 통과시킨다** — 모듈 스킴으로 테스트 실행.
3. **ArchLint를 통과시킨다** — `swift run --package-path Tooling/ArchLint ArchLint .`
   테스트 이름을 바꿨으면 `--write-test-specs`로 모듈 루트의 `TEST_SPEC.md`(테스트 목록)를 갱신해 같이 커밋한다.
4. **뮤테이션 도구로 확인한다** — `swift run --package-path Tooling/ArchLint Mutate <모듈>`.
   소스에 버그를 하나씩 심어 테스트가 잡는지 본다. 살아남은 버그는 사람이 판단한다(아래).
5. **PR에서 사람이 읽는다** — 아래 "사람이 보는 곳".

## 사람이 보는 곳

기계가 모양은 검사하지만, 아래는 사람이 판단한다.

- **`TEST_SPEC.md`의 변화(주로 여기)** — 목록이 기능을 다 말하는가, 빠진 경계값·엣지 케이스는 없는가, 이름이 말하는 게 정말 원하는 동작인가.
- **테스트 본문(마지막 확인)** — 이름이 말한 것을 본문이 실제로 확인하는가.
- **살아남은 버그** — 테스트를 더할지, 결과가 같아 의미 없는 변이인지.
- **`// archlint:allow <규칙> — 이유` 주석** — 그 이유가 타당한가. 이유 없는 주석은 무시되므로, 이 주석이 곧 사람이 볼 예외 목록이다.
- **`test-aaa-act` 경고(실행이 여러 문장)** — 한 동작을 여러 번 호출해야 한다면 메서드 설계를 바꿀 신호일 수 있다. 유지하면 allow 주석에 이유를 남긴다.
- **단어** — 한 단어에 뜻 하나. 같은 단어가 두 뜻으로 쓰이면 목록이 안 읽힌다.
  (예: 탈퇴 화면에서 고르는 것은 "항목", '직접입력'에서 쓰는 글은 "탈퇴 이유" — "사유"를 둘 다에 쓰지 않는다.)

## 쓰는 법

```swift
import Testing

import AuthDomain

@Suite("탈퇴 사유 작성")
struct WithdrawalReasonDraftTests {

    @Test("탈퇴 이유가 80자를 넘으면 앞 80자만 남는다")
    func cutsReasonOver80Characters() {
        var draft = WithdrawalReasonDraft()
        draft.setOption(.custom)
        // 81번째 글자만 다르게 둬서, 잘려 나간 쪽이 뒤인지 확인한다.
        let reason = String(repeating: "가", count: 80) + "나"

        draft.setCustomReasonText(reason)

        #expect(draft.customReasonText == String(repeating: "가", count: 80))
    }

    @Test(
        "'직접입력'은 탈퇴 이유가 비었거나 공백뿐이면 정책에 동의해도 제출할 수 없다",
        arguments: [
            "",      // 아무것도 쓰지 않음
            "   ",   // 스페이스만
            "\n\t "  // 줄바꿈·탭도 공백으로 본다
        ]
    )
    func customOptionCannotSubmitWithBlankReason(reason: String) { … }
}
```

- `@Suite`는 **기능 단위**(타입·메서드 단위가 아님). 함수 이름은 영어, 설명은 `@Test("…")`에.
- 여러 입력은 for/if 대신 `arguments:`로. 항목마다 줄을 바꾸고, 리터럴에는 왜 그 값인지 주석을 단다.
  튜플에 `nil`이 섞이면 컴파일러가 타입을 못 정해 "failed to produce diagnostic"으로 죽는다 — 배열 뒤에 `as [(Date?, Date?)]`처럼 타입을 붙인다(검사기·목록 파일은 그대로 읽는다).
- 경계값은 "딱 그 값"과 "하나 넘는 값"을 둘 다 둔다. 위 예처럼 넘는 쪽은 어디가 잘렸는지까지 보이게 만든다.
- 에러는 case를 적어 확인한다: `#expect(throws: Draft.ValidationError.tooLong(max: 20)) { … }` (타입만 적으면 다른 case도 통과).
- 공개 API로만 테스트한다(`@testable import` ❌) — internal에 기대면 리팩터링마다 깨진다.

## 가짜 객체: Stub과 Mock

용어는 둘만 쓴다(클래스 이름은 `Mock…Repository`로 통일).

- **Stub — 조회(`fetch…`·`load…`)**: 정해 둔 값을 돌려줄 뿐 호출을 기록하지 않는다.
  조회 입력이 맞는지는 Stub이 입력마다 다른 값을 돌려주게 해서 **결과로** 확인한다.
  "몇 번 불렀나"를 확인하면 캐시를 붙이는 것 같은 정상 리팩터링에도 깨진다.
- **Mock — 명령(저장·삭제·전송)**: 호출 자체가 결과라 보낸 값을 기록하고 확인한다.
- 중복 요청 금지처럼 조회 횟수가 진짜 요구사항이면 allow 주석에 그 이유를 적는다.
- Entity 테스트에는 가짜 객체를 쓰지 않는다 — 값과 규칙뿐이라 결과로 확인한다.
- 가짜 객체는 `Testing/` 타깃(`<Module>DomainTesting`)에 둔다. 다른 모듈의 Testing 타깃을 쓰려면 그 모듈
  `Project.swift`에 `testDependencies: [.module(.domain(.base), type: .testing)]`처럼 선언해야 import 된다(없으면 "No such module").

## 위치

```
Projects/Domain/<Module>Domain/
├── TEST_SPEC.md                         # 자동 생성 테스트 목록(손으로 고치지 않는다)
├── Testing/Mock/Mock[Protocol].swift    # 가짜 객체 — 필요한 모듈만
└── Tests/{Entity,UseCase}/[X]Tests.swift
```

- **Swift Testing**(`@Test`·`#expect`·`@Suite`). XCTest ❌.

## 적용 범위 (#293 진행 중)

- ArchLint 테스트 규칙은 **재작성을 마친 모듈에만** 켜져 있다 — `Tooling/ArchLint/Sources/ArchLintCore/TestSpecSupport.swift`의 `TestSpecScope.modules`.
  모듈을 이 기준으로 다시 쓰면 거기에 추가한다. 안 고친 모듈까지 켜면 옛 테스트가 전부 error로 떠 게이트가 막힌다.
- 아직 안 켜진 Domain 모듈에도 **새로 쓰는 테스트는 이 기준**을 따른다. 옛 방식 테스트(예: `@testable`, 메서드별 `// MARK:`, 호출 횟수 확인)를 본뜨지 않는다.

## CI

- 트리거: **develop 대상 PR을 올리면 자동 실행**. `/domain-test` 댓글·수동 `workflow_dispatch`는 재실행용. `.github/workflows/test.yml`.
- `Project.swift`가 `.tests` 타깃을 선언한 **정식 모듈(Domain·Data·Feature)** 을 자동 스캔 → 선언만 하면 자동 포함.
- 유령 폴더는 `Project.swift`가 없어 자동 제외된다(폴더 잔재가 매트릭스를 깨지 않는다).
- `All Tests Passed` job이 전체 통과를, `Architecture Rules` job이 ArchLint(테스트 규칙·`TEST_SPEC.md` 최신 여부 포함)를 판정한다.
- 뮤테이션 도구는 느려서(버그마다 빌드+테스트) CI에 없다 — 로컬에서 수동으로 돌린다.

## 주의사항 (작업 중 발견 시 누적)

- Mock·테스트가 프로토콜/UseCase 시그니처 변경을 못 따라가 컴파일이 깨지는 drift가 있을 수 있다. 시그니처를 바꾸면 **같은 PR에서 Mock·테스트도 갱신**.
- ⚠️ **`tuist test`의 `Executed 0 tests, with 0 failures`는 테스트가 안 돌았다는 뜻이 아니다.** 그 줄은 XCTest 카운터라
  Swift Testing(`@Test`)을 세지 않는다. 실제 실패는 `Failing tests:` + `** TEST FAILED **`로, 성공은 `Test Succeeded`로 나온다.
  의심되면 일부러 실패하는 테스트를 하나 넣어 러너가 잡는지 확인하면 된다(카나리) — `0 tests`만 보고 러너가 죽었다고 판단하지 말 것.
- ⚠️ **`@Test("…")` 설명에 `/`를 넣지 말 것**(ArchLint `test-name`이 막는다) — XcodeBuildMCP `test_sim` 리포터가 `/`를 스위트 구분자로 읽어 이름을 쪼갠다
  (`"websoso://collections/{id}를 파싱하면…"` → 스위트 `websoso:/collections` + 테스트 `{id}를 파싱하면…`으로 보고됨, #228 실측).
  URL·경로가 들어가는 명세는 "websoso 스킴에 collections host와 id가 붙은 URL"처럼 말로 풀어 쓴다.
- 뮤테이션 도구는 소스를 고쳤다가 되돌린다 — 모듈 `Sources`에 커밋 안 한 변경이 있으면 시작하지 않고, 도중에 끊기면 `git checkout -- <모듈>/Sources`로 되돌린다.
