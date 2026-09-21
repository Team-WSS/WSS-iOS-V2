---
name: commit-staged
description: WSS-iOS-V2 프로젝트에서, 이미 스테이징된(staged) Git 변경분만 커밋할 때 사용한다. unstaged·untracked 작업은 그대로 보존하고, 스테이징된 것만 검사해 커밋한다. "스테이징한 거 커밋", "/commit-staged" 같은 요청에 트리거. 커밋 양식은 `[Type] #이슈 - 내용`으로 고정.
metadata:
  short-description: 이미 스테이징된 변경만 WSS 양식으로 커밋
---

# Commit Staged (WSS-iOS-V2)

이미 스테이징된 변경분만 커밋한다. unstaged·untracked 작업은 건드리지 않는다.

## 커밋 양식 (고정)

```
[Type] #<이슈번호> - <한글 내용>
```

예: `[Fix] #132 - 작품 평가 뒤로가기 경합 수정`

- **`[Type]`**: 아래 [Type 표](#type-표)에서 변경 성격에 맞는 하나. **브랜치의 Type과 무관** — 스테이징된 변경 내용 기준.
- **`#<이슈번호>`**: 현재 브랜치명에서 자동 추출한다 (→ [이슈 번호 추출](#이슈-번호-추출)).
- **`<한글 내용>`**: 변경을 한 줄로 요약한 **한글** 설명.
- 이 양식에서 벗어나지 않는다. 헷갈리면 `git log --oneline -8`의 실제 커밋들이 진실.

## 이슈 번호 추출

1. `git branch --show-current`로 현재 브랜치명을 얻는다 (정규형 `<Type>/#<번호>`, 예: `Feat/#132`).
2. 브랜치명에서 `#` 뒤 숫자, 없으면 마지막 `/` 뒤 숫자를 이슈 번호로 쓴다.
3. 추출 실패 시 → `git log --oneline -8`에서 최근 커밋의 `#번호`를 재사용하거나, 모호하면 **사용자에게 묻는다**. 지어내지 않는다.

## 절차

1. 워크트리 파악:
   - `git status --short` 실행.
   - 스테이징된 항목(`M  file`, `A  file`, `D  file` 등)을 unstaged(` M file`)·untracked(`?? file`)와 분리해 식별한다.
   - 사용자가 명시적으로 요청하지 않는 한 파일을 스테이징/언스테이징/수정하지 않는다.

2. 스테이징된 내용만 검토:
   - `git diff --cached --stat`, `git diff --cached --name-only` 실행.
   - 제목을 정하려면 필요 시 `git diff --cached`로 내용을 확인한다.

3. 이슈 번호 확보: 위 [이슈 번호 추출](#이슈-번호-추출) 절차 수행.

4. 커밋:
   - 스테이징된 변경이 없으면 커밋하지 말고 "스테이징된 게 없다"고 설명한다.
   - `git commit -m "[Type] #번호 - 내용"` 한 번으로 커밋.
   - 샌드박스가 `.git` 쓰기를 막으면 좁은 사유를 달아 권한 상승 후 같은 명령 재시도.

5. 검증:
   - `git status --short`, `git log --oneline -1` 실행.
   - 커밋 해시·제목, 남은 unstaged/untracked 파일을 보고한다.

## Type 표

`[Type]`은 **반드시 [`../commit-types.md`](../commit-types.md)를 읽어** 그 표에서 변경 성격에 맞는 하나를 고른다.
표를 여기 복제하지 않는다 — 그 파일이 단일 진실 소스다. 커밋 헤더에서는 대괄호로 감싼다(`[Feat]` 등).

- unstaged/untracked 파일을 커밋된 변경처럼 요약에 포함하지 않는다.

## 안전 규칙

- 사용자가 명시적으로 요청하지 않는 한 `git add`·`git reset`·`git checkout` 등 파괴적 명령 금지.
- unstaged·untracked 파일은 절대 커밋하지 않는다.
- 스테이징된 변경이 무관한 주제들로 섞여 있으면 멈추고 함께 커밋해도 될지 묻는다.
