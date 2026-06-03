<!--
새 모듈 문서 작성 시 이 파일을 복사해서 docs/modules/<레이어>/<모듈명>.md 로 만든다.
괄호 안내문은 지우고 채운다. 작성 후 docs/modules/README.md 인덱스에 한 줄 추가.
-->
# <모듈명> (예: NovelDomain)

- **레이어**: <App | Feature | UI | Domain | Data | Core> → 규칙은 [../../layers/<레이어>.md](../../layers/<레이어>.md)
- **식별자**: `ModuleType.<layer>(.<case>)`
- **위치**: `Projects/<레이어>/<모듈명>/`
- **한 줄 책임**: (이 모듈이 무엇을 하는가)

## 의존성

- internal: (예: `BaseDomain`)
- external: (없으면 "없음")

## 주요 구성요소

(레이어 구조에 맞춰. Domain이면 Entity/UseCase/Repository, Data면 DTO/Service/Mapper/Repository/Factory)

| 종류 | 이름 | 역할 |
|---|---|---|
| | | |

## 핵심 동작 / 시나리오

(이 모듈이 처리하는 주요 흐름을 2~4개. 외부에서 어떻게 진입하는지 포함)

## 주의사항 (작업 중 발견 시 누적)

- (모듈 특유의 함정·예외·TODO)
