---
name: rewrite-domain-tests
description: WSS-iOS-V2에서 아직 "테스트=기능 명세" 기준으로 안 바뀐 Domain 모듈의 테스트를 다시 쓸 때 사용한다(#293에서 Auth·NovelReview·Base·Collection에 한 과정 그대로). 모듈명을 받아 ① 현재 소스와 기존 테스트 읽기(기존 테스트는 실제 사고 기록만 추림) → ② 기준 모듈(NovelReviewDomain)을 본떠 테스트 목록 초안 → ③ 사람이 목록 승인 → ④ 테스트 재작성·넘기기 테스트 정리 → ⑤ ArchLint 적용 범위에 추가·검사 통과·TEST_SPEC.md 생성 → ⑥ 사람이 본문 훑기 → ⑦ 뮤테이션 도구 실행·살아남은 버그를 사람이 판단, 까지 단계별 게이트로 진행한다. "도메인 테스트 다시 쓰자", "이 모듈 테스트 명세로 바꾸자", 또는 "/rewrite-domain-tests <ModuleName>" 같은 요청에 트리거. 새 코드를 TDD로 쓰는 일이나 Feature/Data 테스트는 범위 밖.
metadata:
  short-description: Domain 모듈 테스트를 기능 명세로 재작성 (목록 합의 → 재작성 → ArchLint → 본문 확인 → 뮤테이션), 단계별 게이트
---

# Rewrite Domain Tests — Domain 테스트를 기능 명세로 재작성 (WSS-iOS-V2)

인자: `<ModuleName>` (예: `Feed` → `FeedDomain`). 비면 묻는다.
**AI가 테스트 코드를 쓰고, 무엇을 확인할지는 사람이 정한다.** 이 스킬은 그 결정 지점(🚦)을 빼먹지 않게 하는 순서다.

> ⚠️ **규칙은 여기 없다 — 정본을 먼저 읽는다.** 5원칙·Stub/Mock·쓰는 법·사람이 보는 곳은
> [docs/TESTING.md](../../../docs/TESTING.md), 기계가 검사하는 규칙 id는
> [Tooling/ArchLint/README.md](../../../Tooling/ArchLint/README.md)의 "테스트 명세 규칙"이 정본이다.
> 이 스킬은 **순서와 사람 게이트만** 적는다. 규칙을 여기 복사하지 않는다(어긋난다).
>
> ⚠️ **기준 모듈(이렇게 쓰면 된다는 본보기)** — 지어내지 말고 읽고 따른다.
> - **NovelReviewDomain** — 주 기준. Entity(Draft) 테스트·하위 Suite·`TEST_SPEC.md` 모양:
>   `Projects/Domain/NovelReviewDomain/Tests/Entity/NovelReviewDraftTests.swift`, `TEST_SPEC.md`
> - **BaseDomain `Tests/UseCase/`** — UseCase 테스트와 Stub/Mock(NovelReview엔 UseCase 테스트가 없다):
>   `AppReviewRequestUseCaseTests.swift`, `Testing/Mock/MockKeywordRepository.swift`
> - **CollectionDomain** — 하위 Suite를 개념으로 나눈 예, `ValidationError` case별 `#expect(throws:)`
>
> ⚠️ **게이트 승인 = 커밋 지시.** 게이트에서 진행을 물을 때 *무엇을 몇 개의 커밋으로, 어떤 메시지로*
> 할지 같이 보여준다. 커밋은 `commit` 스킬 규약(`[Type] #이슈 - 한글`, 이슈번호는 브랜치명에서,
> 명시적 경로로만 스테이징). **push는 안 한다.**

## 절차

### 0. 준비
- `ModuleType.swift`에서 `<Module>Domain`이 정식 모듈인지 확인한다(폴더 `ls`로 판단 ❌ — 유령 폴더).
- `TestSpecSupport.swift`의 `TestSpecScope.modules`에 이미 있으면 → 이미 끝난 모듈이라고 알리고 멈춘다.
- 모듈 `Sources`·`Tests`에 커밋 안 한 변경이 있으면 먼저 정리한다(뮤테이션 도구가 시작을 거부한다).

### 1. 재료 읽기
- **현재 소스가 기준이다.** `Sources/` 전부를 읽고 타입·메서드마다 분류한다:
  판단(분기·검증·계산·정규화·상태 변화) / 담기(규칙 있는 타입이 값을 담음 — **테스트 대상**) / 넘기기(저장소 호출 그대로) / 값만 담는 타입.
  ⚠️ "담는 것은 넘기는 것이 아니다" — NovelReview에서 setter를 '판단 없음'으로 뺐다가 뮤테이션에서 걸렸다(TESTING.md).
- **기존 테스트는 가볍게만 본다.** 옛 방식이라 구조는 본뜨지 않는다. 대신 **실제 사고·버그 이력이 적힌 테스트·주석**
  (이슈 번호, "실측", "버그" 같은 말)만 추려서, 목록에 살릴 후보로 들고 간다.
- 이 모듈의 `Testing/Mock`을 누가 쓰는지 `Projects/` 전체에서 grep 해 둔다(다른 모듈·Feature 테스트가 쓰면 지울 수 없다).

### 2. 테스트 목록 초안
- 기준 모듈의 `TEST_SPEC.md` 모양 그대로 쓴다: Suite 이름 → (하위 Suite) → 테스트 이름(한국어 문장).
- 같이 적는다:
  - **넣지 않는 것과 이유** — 넘기기 UseCase, 값만 담는 타입 등. 빠뜨린 것과 뺀 것을 구분하기 위해서다.
  - **지울 것** — 넘기기 UseCase 테스트, 그래서 안 쓰게 되는 Mock·`Testing` 타깃(1단계 grep 결과 근거).
  - **1단계에서 추린 사고 이력**을 어느 테스트가 이어받는지.
  - 판단이 필요한 곳(경계값, 순서가 명세인지, 시각·달력 의존을 인자로 뺄지 등)은 **질문으로** 따로 뽑는다.
- 하위 Suite 묶음은 **개념** 기준(개수 ❌). 묶음도 사람이 정할 몫이라 초안은 제안일 뿐이다.
- **판단 코드가 하나도 없으면**(전부 넘기기·값만 담는 타입 — SocialDomain 시험 실행에서 나옴) 목록은 "테스트 0개"다.
  이때 초안에 TESTING.md "적용 범위"의 테스트 없는 모듈 처리(타깃 빼기·적용 범위엔 넣기)를 그대로 제안한다.

### 🚦 3. 사람이 목록 승인
- 목록과 질문을 보여주고 **승인 전에는 테스트 코드를 쓰지 않는다.**
- 소스를 바꿔야 하는 결정(예: `calendar` 인자 추가, 중복 거부 추가)이 나오면 여기서 확정한다 — 소스 변경도 승인 범위다.
- 커밋할 것 없음(목록은 대화에만). 승인되면 4단계로.

### 4. 테스트 재작성
- 승인된 목록대로 `Tests/{Entity,UseCase}/`를 다시 쓴다. 쓰는 법은 TESTING.md "쓰는 법"·"가짜 객체" 그대로.
- 지우기로 한 테스트·Mock을 지우고, Mock이 전부 사라지면 `Project.swift`의 `.testing` 타깃도 뺀다.
  테스트가 0개가 되면 `.tests` 타깃도 빼고 `tuist generate` 후 모듈 스킴 **빌드**로 확인한다(돌릴 테스트가 없다).
- 모듈 스킴으로 테스트를 돌려 통과시킨다(XcodeBuildMCP `test_sim`, scheme `<Module>Domain` — `…Tests` 스킴은 없다).
  ⚠️ `Executed 0 tests`는 실패가 아니다(TESTING.md 주의사항).

### 5. ArchLint 켜기
- `TestSpecScope.modules`에 `<Module>Domain`을 추가한다(빼먹으면 규칙이 이 모듈엔 아예 안 돈다).
- `swift run --package-path Tooling/ArchLint ArchLint --write-test-specs .` → `TEST_SPEC.md` 생성.
- `swift run --package-path Tooling/ArchLint ArchLint .` error 0이 될 때까지 고친다.
  - **규칙 오탐이면 allow 주석으로 덮지 말고 사용자에게 알린다.** 규칙을 고칠지(별도 `[Fix]` 커밋 + 규칙 자체 테스트), 이유 단 allow로 둘지 사람이 정한다.
  - `test-aaa-act` warning(실행 여러 문장)은 설계 점검 질문으로 사용자에게 넘긴다.
- **커밋 제안**: 재작성 + 적용 범위 추가 + `TEST_SPEC.md`를 `[Test] #이슈 - <Module>Domain 테스트를 기능 명세로 재작성` 하나로
  (`TEST_SPEC.md`는 적용 범위가 있어야 검사되므로 같이 간다). 소스 변경이 있었으면 관심사별로 나눠 제안한다.

### 🚦 6. 사람이 본문 훑기
- 사람에게 볼 곳을 짚어준다: 이름이 말한 것을 본문이 실제로 확인하는지, `arguments` 이유 주석, allow 주석.
- 고칠 게 나오면 고치고 4~5단계 검사를 다시 통과시킨 뒤 넘어간다.

### 7. 뮤테이션 → 🚦 살아남은 버그 판단
- `tuist generate` 후 `swift run --package-path Tooling/ArchLint Mutate <Module>Domain` (모듈 전체 — 테스트를 바꿨으므로 `--changed-since` ❌).
  오래 걸리니 백그라운드로 돌린다.
  테스트가 0개인 모듈은 도구가 "테스트가 없다"로 멈춘다 — 6·7단계는 건너뛰고 그 사실을 보고한다.
- 결과를 **있는 그대로** 보고한다: 잡힘 / 살아남음 / 컴파일 불가.
- **살아남은 버그마다** 무엇이 바뀌었고 사용자에게 어떤 결과가 나는지 한 줄로 설명하고 사람이 고른다:
  테스트 추가 / 결과가 같아 의미 없는 변이 / 규칙 없는 값이라 테스트 안 함. 이유는 PR 본문 재료로 남긴다.
- 테스트를 추가했으면 5단계 검사(`--write-test-specs` 포함)를 다시 통과시키고 `[Test] #이슈 - <무엇을> 확인` 으로 따로 커밋 제안.

### 8. 마무리 보고
- 테스트 수 전후, 지운 넘기기 테스트 수, 뮤테이션 잡힘/생존, allow 주석 수, 발견한 규칙 오탐.
- 함정을 새로 알았으면 모듈 `CLAUDE.md`(또는 TESTING.md 주의사항)에 한 줄 누적한다.
- 다음 단계로 `make-PR`을 제안한다(자동 실행 ❌).
