---
name: api-spec
description: WSS-iOS-V2에서 서버 API 스펙(OpenAPI/Swagger)이 필요할 때 사용한다. Data 레이어 DTO·Endpoint를 짜기 전, Domain Entity 필드셋을 확정하기 전, 또는 응답 필드·에러 코드를 확인할 때 dev 서버 OpenAPI 명세를 받아 읽는다. "API 스펙 확인해줘", "스웨거 봐줘", "이 엔드포인트 응답이 뭐야", "/api-spec <키워드>" 같은 요청에 트리거.
metadata:
  short-description: 서버 OpenAPI 명세 조회 (Swagger UI 링크 대신 JSON 직접 열람)
---

# API Spec — 서버 OpenAPI 명세 조회 (WSS-iOS-V2)

Swagger **UI 링크는 에이전트에게 쓸모없다**. UI는 빈 HTML 껍데기고 명세는 JS가 나중에 받아온다.
아래 **JSON 원본**을 직접 받아 읽는다.

## 스펙 위치 (중요)

| URL | 인증 | 비고 |
|---|---|---|
| `https://dev.websoso.kr/swagger-ui/openapi3.json` | **불필요** ✅ | **이걸 쓴다.** 정적 파일이라 그냥 열린다 |
| `https://dev.websoso.kr/v3/api-docs` | 필요 ❌ | 인증 필터에 막혀 401 (`AUTH-001`). 함정 |
| `https://dev.websoso.kr/swagger-ui/index.html` | - | 사람용 UI. 에이전트가 fetch하면 내용 없음 |

> Swagger UI 상단 Explore 입력창의 값(`./openapi3.json`)이 실제 스펙 경로다.
> 서버가 경로를 바꾸면 UI를 브라우저로 열어 그 값을 다시 확인한다.

## 절차

### 1. 조회

```bash
# 전체 엔드포인트 한 줄 목록
node .claude/skills/api-spec/scripts/fetch-api-spec.mjs

# 키워드(경로·태그·summary) 매칭 → 요청/응답 스키마 + 에러 코드 예시까지
node .claude/skills/api-spec/scripts/fetch-api-spec.mjs collection

# 원본 JSON이 필요하면 (스크래치패드에 저장해 재사용)
node .claude/skills/api-spec/scripts/fetch-api-spec.mjs --json > <스크래치패드>/openapi3.json
```

node가 PATH에 없으면 `/opt/homebrew/bin/node`를 쓴다. node 자체가 없을 때의 무의존 대안:

```bash
curl -s https://dev.websoso.kr/swagger-ui/openapi3.json | python3 -m json.tool | less
```

운영 서버 등 다른 스펙을 볼 땐 `WSS_SPEC_URL=<url>`로 덮어쓴다.

### 2. 찾는 API가 없을 때 (자주 겪는다)

이 명세는 **Spring REST Docs 테스트로 생성**된다 → 서버에 문서화 테스트가 있는 엔드포인트만 올라온다.
앱이 실제로 쓰는 API의 극히 일부만 담겨 있다(스크립트가 매번 총 개수와 태그 분포를 함께 출력하니 그 숫자로 감을 잡는다).

**"스펙에 없다 ≠ 서버에 없다"** — 순서대로 확인한다:

1. 전체 목록을 눈으로 훑는다. **제품 용어와 서버 용어가 다르다** — 예를 들어 "서재"는 경로에 `library`가 없고
   `/users/{userId}/novels` 다. 감이 안 오면 `Projects/Data/*/Sources/Endpoint/`의 `path`를 먼저 보고 키워드를 정한다.
2. 그래도 없으면 **기존 Data 모듈의 코드가 그 API의 진실 소스**다 —
   `Projects/Data/<모듈>Data/Sources/Endpoint/` 와 `Sources/DTO/` 를 읽는다.
3. 신규 API인데 스펙에도 코드에도 없으면 서버팀에 문서화를 요청한다. 추측으로 DTO를 짜지 않는다.

### 3. 읽을 때 확인할 것

- **엔드포인트 description(`>` 인용 블록)을 건너뛰고 스키마부터 보지 말 것.** summary 한 줄에 없는 운영 규칙이
  거기 있다 — "마이페이지 미리보기는 이 API를 size=3으로 호출해 구성한다" 처럼 **화면 구성 방식**을 정해버리는 문장,
  커서 페이지네이션 절차, 필드 간 관계, 에러 코드별 의미까지.
- **필드 description에 정책이 들어있다** — 글자 수 제한, null 조건, 정렬 순서, "이번 페이지 개수가 아니다" 같은 함정.
  Entity·DTO 주석과 Domain 테스트 케이스는 여기서 그대로 따온다.
  - **배열·중첩 객체 필드의 description을 특히 흘리지 말 것.** 설계를 좌우하는 정책이 거기 몰려 있다
    (예: `novelIds` → "배열 순서가 그대로 표시 순서로 저장되며 앞쪽이 최신", `recentNovels` → "최대 5개이고 대표 작품을 제외하지 않는다").
- **`*` 표시가 required 필드다.** 스크립트가 스키마의 `required` 배열을 반영해 붙인다 —
  다만 응답 쪽은 비어 있을 수 있으니, optional 판단은 `*` 유무와 description의 "생략할 수 있고" / "없으면 null이다" 문구를 **함께** 본다.
- **요청 바디 content-type이 `application/json;charset=UTF-8`** 이다. `application/json`만 정확 매칭하면
  requestBody가 통째로 누락된다(스크립트는 prefix 매칭으로 처리 완료).
- **에러 코드는 `responses[*].examples`에 있다.** 상태 코드만으론 원인 구분이 안 되므로
  (`400`에 `BAD_REQUEST`/`COLLECTION-002`/`COLLECTION-003`… 공존) `RepositoryError` 매핑은 **code 문자열 기준**으로 짠다.
  - 공용 매핑은 `Projects/Data/BaseData/Sources/Networking/NetworkingError+RepositoryError.swift`의 `toRepositoryError()`.
    특정 화면에서만 의미가 다른 코드(예: 비공개·차단)는 공용 매핑에 섞지 말고 **그 Data 리포지토리 메서드에서** 개별 변환한다
    (`RepositoryError.privateProfile` 선례 — `BaseDomain/CLAUDE.md` 참고).

### 4. 인증이 필요한 API를 실제로 호출해봐야 할 때

`Config/Config_Debug.xcconfig`의 `TEST_API_KEY`는 **만료돼 있을 수 있다**(`AUTH-000`).
개발용 토큰 발급 엔드포인트로 새로 받는다:

```bash
curl -s -X POST https://dev.websoso.kr/users/login \
  -H 'Content-Type: application/json' -d '42'          # 본문은 DB에 있는 사용자 ID 숫자만
# → {"Authorization":"<Access Token>"}
```

Access Token만 나오고 Refresh Token은 안 나온다. 클라이언트 로직에 쓰면 안 된다(deprecated 표시된 보조 API).

## 주의사항 (작업 중 발견 시 누적)

- 사용자가 Swagger **UI 링크**를 주면 그대로 fetch하지 말고 위 `openapi3.json`으로 바꿔 접근한다. UI 링크만 보고
  "인증이 막혀 못 본다"고 결론 내린 적이 있다 — 실제로는 인증 없이 열리는 경로가 따로 있었다.
- 스크립트 경로는 **`.claude/skills/...`** 로 쓴다. 이 머신엔 `.agents/skills → ../.claude/skills` 심링크가 있어
  `.agents/...` 로도 실행되지만, 그 링크는 `.git/info/exclude`에 등록된 **로컬 전용**이라 팀원이 clone하면 없다.
