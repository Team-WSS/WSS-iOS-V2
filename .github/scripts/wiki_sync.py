#!/usr/bin/env python3
"""Claude 커스텀 스킬(.claude/skills)·서브 에이전트(.claude/agents)를 GitHub 위키 페이지로 동기화한다.

사용: python3 .github/scripts/wiki_sync.py <위키_클론_디렉터리>
  - 매번 전체를 다시 생성한다(멱등) → 커밋·push는 워크플로가 diff가 있을 때만 한다.
  - 이 스크립트가 관리하는 페이지만 쓴다: `Claude-Skills`, `Claude-Agents`, `Skill-*`, `Agent-*`.
    그 밖의 위키 페이지(Home 등 사람이 쓴 것)는 건드리지 않는다.
  - 원본에서 사라진 `Skill-*`/`Agent-*` 페이지는 삭제한다.

정본은 레포의 SKILL.md / agents/*.md 다. 위키는 읽기용 사본이라 위키에서 직접 고치면 다음 동기화 때 덮어쓴다.
외부 의존성 없음 원칙에 따라 표준 라이브러리만 쓴다.
"""

import glob
import os
import posixpath
import re
import sys

SKILLS_DIR = ".claude/skills"
AGENTS_DIR = ".claude/agents"
SERVER = os.environ.get("GITHUB_SERVER_URL", "https://github.com")
REPO = os.environ.get("GITHUB_REPOSITORY", "Team-WSS/WSS-iOS-V2")
BRANCH = "develop"
NOTICE = (
    "> 🤖 `skill-archive` 워크플로가 레포 원본에서 자동 생성한 페이지예요. "
    "**위키에서 직접 고치면 다음 동기화 때 덮어써지니**, 수정은 원본 파일에서 PR로 해주세요."
)
REL_LINK = re.compile(r"(\]\()(?!https?://|mailto:|#|/)([^)\s]+)(\))")


def parse(path):
    """frontmatter(한 줄 key: value 형식 전제)와 본문을 분리."""
    text = open(path, encoding="utf-8").read()
    meta, body = {}, text
    if text.startswith("---\n"):
        end = text.find("\n---", 4)
        if end != -1:
            for line in text[4:end].splitlines():
                m = re.match(r"^\s*([\w-]+):\s*(.*)$", line)
                if m:
                    meta[m.group(1)] = m.group(2).strip().strip("\"'")
            body = text[end + 4 :].lstrip("\n")
    return meta, body


def blob(path):
    return f"{SERVER}/{REPO}/blob/{BRANCH}/{path}"


def absolutize_links(body, src_path):
    """`../commit-types.md` 같은 상대 링크는 위키에서 깨지므로 레포 blob URL로 바꾼다."""
    base = posixpath.dirname(src_path)

    def repl(m):
        target, _, anchor = m.group(2).partition("#")
        resolved = posixpath.normpath(posixpath.join(base, target))
        return f"{m.group(1)}{blob(resolved)}{'#' + anchor if anchor else ''}{m.group(3)}"

    return REL_LINK.sub(repl, body)


def cell(text, limit=160):
    text = " ".join(text.split()).replace("|", "\\|")
    return text if len(text) <= limit else text[: limit - 1].rstrip() + "…"


def first_sentence(text):
    m = re.match(r"(.+?(?:다|요)\.)(\s|$)", text)
    return m.group(1) if m else text


def skill_page(name, meta, body, src):
    issue_q = f"{SERVER}/{REPO}/issues?q=label%3Askill-archive+%22%5BSkill%5D+{name}%22+in%3Atitle"
    lines = [
        f"# /{name}",
        "",
        NOTICE,
        "",
        f"**{meta['short-description']}**" if meta.get("short-description") else "",
        "",
        "## 언제 쓰나",
        meta.get("description", "(description 없음)"),
        "",
        f"- 원본: [{src}]({blob(src)})",
        f"- 추가 이유·변경 이력: [아카이브 이슈]({issue_q}) (Discord 스레드 링크도 거기 있어요)",
        f"- 호출: Claude Code에서 `/{name}` 또는 설명의 트리거 문구로 요청",
        "",
        "---",
        "",
        absolutize_links(body, src),
    ]
    return "\n".join(lines).rstrip() + "\n"


def agent_page(name, meta, body, src):
    lines = [
        f"# {name} (서브 에이전트)",
        "",
        NOTICE,
        "",
        "## 언제 쓰나",
        meta.get("description", "(description 없음)"),
        "",
        f"- 원본: [{src}]({blob(src)})",
        f"- 사용 도구: `{meta['tools']}`" if meta.get("tools") else "- 사용 도구: (지정 없음 — 전체)",
        f"- 모델: `{meta['model']}`" if meta.get("model") else None,
        f"- 호출: Claude Code에서 \"{name}로 리뷰해줘\"처럼 이름을 지정하거나, 스킬이 내부에서 띄운다",
        "",
        "---",
        "",
        absolutize_links(body, src),
    ]
    return "\n".join(l for l in lines if l is not None).rstrip() + "\n"


def index_page(title, intro, rows, prefix):
    out = [f"# {title}", "", NOTICE, "", intro, "", "| 이름 | 설명 |", "|---|---|"]
    for name, summary in rows:
        out.append(f"| [{name}]({prefix}{name}) | {cell(summary)} |")
    return "\n".join(out) + "\n"


def main():
    if len(sys.argv) != 2 or not os.path.isdir(sys.argv[1]):
        sys.exit("사용: wiki_sync.py <위키_클론_디렉터리>")
    wiki = sys.argv[1]
    pages = {}

    skill_rows = []
    for path in sorted(glob.glob(f"{SKILLS_DIR}/*/SKILL.md")):
        name = path.split("/")[2]
        meta, body = parse(path)
        pages[f"Skill-{name}.md"] = skill_page(name, meta, body, path)
        skill_rows.append((name, meta.get("short-description") or first_sentence(meta.get("description", ""))))

    agent_rows = []
    for path in sorted(glob.glob(f"{AGENTS_DIR}/*.md")):
        meta, body = parse(path)
        name = meta.get("name") or os.path.splitext(os.path.basename(path))[0]
        pages[f"Agent-{name}.md"] = agent_page(name, meta, body, path)
        agent_rows.append((name, first_sentence(meta.get("description", ""))))

    pages["Claude-Skills.md"] = index_page(
        "Claude 커스텀 스킬",
        f"레포의 `{SKILLS_DIR}/`에 있는 팀 공용 Claude Code 스킬 {len(skill_rows)}개예요. "
        "작업 흐름 속 쓰임새는 [docs/WORKFLOW.md]" f"({blob('docs/WORKFLOW.md')})의 \"스킬 체인\" 절을 보세요.",
        skill_rows,
        "Skill-",
    )
    pages["Claude-Agents.md"] = index_page(
        "Claude 서브 에이전트",
        f"레포의 `{AGENTS_DIR}/`에 있는 팀 공용 서브 에이전트 {len(agent_rows)}개예요. 주로 스킬이 리뷰·추출 단계에서 띄워요.",
        agent_rows,
        "Agent-",
    )

    # 원본에서 사라진 관리 대상 페이지 정리
    for stale in glob.glob(os.path.join(wiki, "Skill-*.md")) + glob.glob(os.path.join(wiki, "Agent-*.md")):
        if os.path.basename(stale) not in pages:
            os.remove(stale)
            print(f"🗑 {os.path.basename(stale)}")

    for fname, content in pages.items():
        dest = os.path.join(wiki, fname)
        old = open(dest, encoding="utf-8").read() if os.path.exists(dest) else None
        if old != content:
            with open(dest, "w", encoding="utf-8") as f:
                f.write(content)
            print(f"{'✏️' if old is not None else '🆕'} {fname}")
    print(f"스킬 {len(skill_rows)}개 · 에이전트 {len(agent_rows)}개 동기화 완료")


if __name__ == "__main__":
    main()
