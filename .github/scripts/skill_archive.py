#!/usr/bin/env python3
"""Claude 스킬 아카이브 — `.claude/skills/<name>/` 변경을 GitHub 이슈 + Discord 포럼 스레드로 기록한다.

스킬 1개 = `skill-archive` 라벨 이슈 1개(정본 아카이브) = Discord 포럼 글 1개(논의 스레드).
이슈 본문의 `<!-- discord-thread-id: N -->` 마커가 둘을 잇는다 → 수정·삭제 시 같은 스레드에 이어 붙인다.

실행 모드 (.github/workflows/skill-archive.yml이 env로 넘긴다):
  - push        : BEFORE..AFTER diff에서 신규/수정/삭제 스킬을 골라 처리
  - dispatch    : INPUT_SKILLS(`all` 또는 쉼표 목록)를 백필 — 이미 스레드가 있는 스킬은 건너뜀
  - --dry-run   : gh 쓰기·웹훅 호출 없이 만들어질 이슈 본문/payload만 출력(로컬 검증용)

외부 의존성 없음 원칙에 따라 표준 라이브러리만 쓴다(PyYAML 등 ❌ — frontmatter는 한 줄 key: value 형식 전제).
"""

import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request

SKILLS_DIR = ".claude/skills"
LABEL = "skill-archive"
ZERO_SHA = "0" * 40
THREAD_MARKER = re.compile(r"<!-- discord-thread-id: (\d+) -->")
DESC_BLOCK = re.compile(r"<!-- desc:start -->.*?<!-- desc:end -->", re.S)
TRUNC_NOTE = "…(전체는 아카이브 이슈 참조)"

DRY_RUN = "--dry-run" in sys.argv
WEBHOOK = os.environ.get("DISCORD_SKILL_WEBHOOK_URL", "").strip()
SERVER = os.environ.get("GITHUB_SERVER_URL", "https://github.com")


def log(msg):
    print(msg, flush=True)


def run(cmd, check=True):
    res = subprocess.run(cmd, capture_output=True, text=True)
    if check and res.returncode != 0:
        raise RuntimeError(f"{' '.join(cmd)} 실패:\n{res.stderr.strip()}")
    return res.stdout


def truncate(text, limit):
    text = text.strip()
    if len(text) <= limit:
        return text
    return text[: limit - len(TRUNC_NOTE)].rstrip() + TRUNC_NOTE


def resolve_repo():
    repo = os.environ.get("GITHUB_REPOSITORY")
    if repo:
        return repo
    return run(["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"]).strip()


# ── 스킬 메타 ────────────────────────────────────────────────────────────────


def read_frontmatter(name, rev):
    """rev 시점의 SKILL.md frontmatter를 {name, description, short} 으로. 없으면 None."""
    res = subprocess.run(
        ["git", "show", f"{rev}:{SKILLS_DIR}/{name}/SKILL.md"], capture_output=True, text=True
    )
    if res.returncode != 0:
        return None
    lines = res.stdout.splitlines()
    if not lines or lines[0].strip() != "---":
        return {"name": name, "description": "", "short": ""}
    meta = {}
    for line in lines[1:]:
        if line.strip() == "---":
            break
        m = re.match(r"^\s*([\w-]+):\s*(.*)$", line)
        if m:
            meta[m.group(1)] = m.group(2).strip().strip("\"'")
    return {
        "name": meta.get("name") or name,
        "description": meta.get("description", ""),
        "short": meta.get("short-description", ""),
    }


def collect_changes(before, after):
    """BEFORE..AFTER diff → {skill: 'added'|'modified'|'deleted'}. 루트 파일(commit-types.md 등)은 제외."""
    if not before or before == ZERO_SHA:
        before = f"{after}^"
    out = run(["git", "diff", "--no-renames", "--name-status", before, after, "--", SKILLS_DIR])
    changes = {}
    for line in out.splitlines():
        status, path = line.split("\t", 1)
        parts = path.split("/")
        if len(parts) < 4:  # .claude/skills/<file> — 스킬 디렉터리가 아님
            continue
        skill, rest = parts[2], "/".join(parts[3:])
        if rest == "SKILL.md" and status == "A":
            changes[skill] = "added"
        elif rest == "SKILL.md" and status == "D":
            changes[skill] = "deleted"
        else:
            changes.setdefault(skill, "modified")
    # 보조 파일만 바뀌었는데 SKILL.md가 이미 사라진 경우 등은 삭제로 본다
    for skill, action in list(changes.items()):
        if action == "modified" and read_frontmatter(skill, after) is None:
            changes[skill] = "deleted"
    return changes


# ── PR 정보 ──────────────────────────────────────────────────────────────────


def extract_summary(body):
    """PR 템플릿의 `## 💭 Summary` 절 본문만 뽑는다(HTML 주석·<br> 제거)."""
    if not body:
        return ""
    body = body.replace("\r\n", "\n")  # GitHub 웹에서 쓴 PR 본문은 CRLF
    m = re.search(r"^##\s*💭\s*Summary\s*$(.*?)(?=^##\s|\Z)", body, re.S | re.M)
    if not m:
        return ""
    text = re.sub(r"<!--.*?-->", "", m.group(1), flags=re.S)
    text = re.sub(r"<br\s*/?>", "", text)
    return re.sub(r"\n{3,}", "\n\n", text).strip()


def find_pr(repo, sha):
    """sha를 포함한 PR(머지 커밋이면 그 PR). 못 찾으면 None."""
    try:
        out = run(["gh", "api", f"repos/{repo}/commits/{sha}/pulls"])
        prs = json.loads(out)
    except (RuntimeError, json.JSONDecodeError) as e:
        log(f"  ⚠️ PR 조회 실패({sha[:8]}): {e}")
        return None
    if not prs:
        return None
    merged = [p for p in prs if p.get("merged_at")] or prs
    p = merged[0]
    return {
        "number": p["number"],
        "title": p["title"],
        "url": p["html_url"],
        "author": (p.get("user") or {}).get("login", ""),
        "summary": extract_summary(p.get("body") or ""),
    }


def intro_info(repo, name):
    """이번 머지가 '도입'이 아닌 스킬(백필, 아카이브 없이 수정된 스킬)의 소개용 정보.

    초기 스킬들은 기능 PR 스택에 섞여 머지돼 `commits/{sha}/pulls`가 무관한 PR(예: #144 작품 평가)을
    돌려준다 → 그 PR Summary를 '추가 이유'로 쓰면 오해를 부르니, 도입 커밋 제목을 이유로 쓴다.
    """
    out = run(
        ["git", "log", "--diff-filter=A", "--format=%H%x00%s", "-1", "--", f"{SKILLS_DIR}/{name}/SKILL.md"],
        check=False,
    ).strip()
    if not out:
        return None
    sha, subject = out.split("\x00", 1)
    pr = find_pr(repo, sha) or {"number": None, "title": "", "url": "", "author": ""}
    pr["summary"] = f"기존 스킬 백필 — 도입 커밋 `{subject}` ({SERVER}/{repo}/commit/{sha[:8]})"
    return pr


# ── GitHub 이슈 (아카이브 정본) ───────────────────────────────────────────────


def load_archive_issues(repo):
    """라벨 이슈 전체를 제목 → 이슈로. search API(색인 지연)가 아니라 list를 써서 방금 만든 것도 보인다."""
    try:
        out = run(
            ["gh", "issue", "list", "--repo", repo, "--label", LABEL, "--state", "all",
             "--limit", "500", "--json", "number,title,body,state,url"]
        )
    except RuntimeError as e:
        if DRY_RUN:
            log(f"  ⚠️ (dry-run) 이슈 목록 조회 실패 — 전부 신규로 간주: {e}")
            return {}
        raise
    return {i["title"]: i for i in json.loads(out)}


def issue_title(name):
    return f"[Skill] {name}"


def skill_url(repo, name):
    return f"{SERVER}/{repo}/blob/develop/{SKILLS_DIR}/{name}/SKILL.md"


def wiki_url(repo, name):
    return f"{SERVER}/{repo}/wiki/Skill-{name}"  # wiki_sync.py가 만드는 페이지명과 맞춘다


def desc_block(meta):
    short = f"> {meta['short']}\n\n" if meta["short"] else ""
    return f"<!-- desc:start -->\n{short}{meta['description'] or '(description 없음)'}\n<!-- desc:end -->"


def issue_body(repo, meta, pr, thread_id=None):
    reason = (pr or {}).get("summary") or "(PR Summary 없음)"
    pr_line = f"- 관련 PR: #{pr['number']} {pr['title']}" if pr and pr["number"] else "- 관련 PR: (찾지 못함)"
    marker = f"\n<!-- discord-thread-id: {thread_id} -->" if thread_id else ""
    return (
        f"## `/{meta['name']}`\n\n"
        f"### 설명 · 활용\n{desc_block(meta)}\n\n"
        f"### 추가 이유\n{reason}\n\n"
        f"### 링크\n- SKILL.md: {skill_url(repo, meta['name'])}\n- 위키: {wiki_url(repo, meta['name'])}\n{pr_line}\n\n"
        f"> 🤖 `skill-archive` 워크플로가 관리하는 이슈예요. 보완 논의는 Discord 스레드에서, "
        f"변경 이력은 이 이슈 코멘트에 쌓여요.{marker}\n"
    )


def gh_write(args, stdin=None):
    if DRY_RUN:
        log(f"  [dry-run] gh {' '.join(args[:3])} …")
        return ""
    res = subprocess.run(["gh", *args], input=stdin, capture_output=True, text=True)
    if res.returncode != 0:
        raise RuntimeError(f"gh {' '.join(args[:3])} 실패:\n{res.stderr.strip()}")
    return res.stdout


def create_issue(repo, title, body):
    out = gh_write(["issue", "create", "--repo", repo, "--title", title, "--label", LABEL, "--body-file", "-"], body)
    if DRY_RUN:
        log(f"  [dry-run] 이슈 본문:\n{body}")
        return {"number": 0, "url": f"{SERVER}/{repo}/issues/0", "body": body, "state": "OPEN"}
    url = out.strip().splitlines()[-1]
    return {"number": int(url.rstrip("/").split("/")[-1]), "url": url, "body": body, "state": "OPEN"}


def edit_issue_body(repo, issue, body):
    gh_write(["issue", "edit", str(issue["number"]), "--repo", repo, "--body-file", "-"], body)
    issue["body"] = body


def comment_issue(repo, issue, body):
    gh_write(["issue", "comment", str(issue["number"]), "--repo", repo, "--body-file", "-"], body)


# ── Discord 웹훅 ─────────────────────────────────────────────────────────────


def post_webhook(payload, thread_id=None):
    """메시지를 보내고 응답 메시지 객체를 돌려준다. thread_id 없으면 포럼에 새 글(payload에 thread_name 필요)."""
    if DRY_RUN or not WEBHOOK:
        log(f"  [dry-run] webhook{' → thread ' + thread_id if thread_id else ' → 새 포럼 글'}:\n"
            + json.dumps(payload, ensure_ascii=False, indent=2))
        return {"channel_id": "DRY_RUN_THREAD"}
    query = "?wait=true" + (f"&thread_id={thread_id}" if thread_id else "")
    data = json.dumps(payload).encode()
    for _ in range(5):
        req = urllib.request.Request(
            WEBHOOK + query, data=data, method="POST",
            # 기본 Python-urllib UA는 Discord(Cloudflare)가 403으로 막는다
            headers={"Content-Type": "application/json", "User-Agent": "WSS-skill-archive (github-actions, 1.0)"},
        )
        try:
            with urllib.request.urlopen(req) as res:
                return json.loads(res.read() or b"{}")
        except urllib.error.HTTPError as e:
            if e.code == 429:
                wait = float(json.loads(e.read() or b"{}").get("retry_after", 2))
                log(f"  ⏳ Discord rate limit — {wait}s 대기")
                time.sleep(wait + 0.5)
                continue
            raise RuntimeError(f"Discord 웹훅 {e.code}: {e.read().decode(errors='replace')}")
    raise RuntimeError("Discord 웹훅 rate limit 재시도 초과")


def intro_embed(repo, meta, pr, issue):
    fields = [
        {"name": "설명 · 활용", "value": truncate(meta["description"] or "(description 없음)", 1024)},
        {"name": "추가 이유", "value": truncate((pr or {}).get("summary") or "(PR Summary 없음)", 1024)},
    ]
    links = [f"[SKILL.md]({skill_url(repo, meta['name'])})", f"[위키]({wiki_url(repo, meta['name'])})", f"[아카이브 이슈 #{issue['number']}]({issue['url']})"]
    if pr and pr["number"]:
        links.insert(1, f"[관련 PR #{pr['number']}]({pr['url']})")
    fields.append({"name": "링크", "value": " · ".join(links)})
    embed = {
        "title": f"🧩 /{meta['name']}",
        "url": skill_url(repo, meta["name"]),
        "color": 0x5865F2,
        "fields": fields,
        "footer": {"text": "보완 아이디어·피드백은 이 스레드에 남겨주세요"
                   + (f" · by @{pr['author']}" if pr and pr.get("author") else "")},
    }
    if meta["short"]:
        embed["description"] = truncate(meta["short"], 4096)
    return embed


def change_text(kind, pr, compare_url):
    head = {"modified": "🔧 스킬이 업데이트됐어요", "deleted": "🗑 스킬이 삭제됐어요", "readded": "♻️ 스킬이 다시 추가됐어요"}[kind]
    lines = [f"**{head}**"]
    if pr and pr["number"]:
        lines.append(f"PR [#{pr['number']} {pr['title']}]({pr['url']})" + (f" by @{pr['author']}" if pr["author"] else ""))
        if pr["summary"]:
            lines.append("\n" + pr["summary"])
    if compare_url:
        lines.append(f"\n[변경 diff]({compare_url})")
    return "\n".join(lines)


# ── 처리 ─────────────────────────────────────────────────────────────────────


def open_thread(repo, meta, pr, issue):
    """포럼 글을 만들고 스레드 ID를 이슈 본문 마커에 기록. 실패 시 다음 실행에서 재시도된다(마커가 없으니까)."""
    payload = {"thread_name": truncate(f"/{meta['name']}", 100), "embeds": [intro_embed(repo, meta, pr, issue)]}
    msg = post_webhook(payload)
    thread_id = str(msg.get("channel_id", ""))
    if thread_id:
        edit_issue_body(repo, issue, issue_body(repo, meta, pr, thread_id))
    return thread_id


def process(repo, issues, name, action, pr, compare_url):
    title = issue_title(name)
    issue = issues.get(title)
    thread_id = (THREAD_MARKER.search(issue["body"] or "") or [None, None])[1] if issue else None

    if action == "deleted":
        if not issue:
            log("  아카이브 이슈 없음 — 건너뜀")
            return
        text = change_text("deleted", pr, compare_url)
        if thread_id:
            post_webhook({"content": truncate(text, 2000)}, thread_id)
        comment_issue(repo, issue, text)
        if issue["state"] == "OPEN":
            gh_write(["issue", "close", str(issue["number"]), "--repo", repo])
        return

    meta = read_frontmatter(name, os.environ.get("AFTER") or "HEAD")
    if meta is None:
        log("  SKILL.md 없음 — 건너뜀")
        return

    # 이번 머지가 스킬을 '도입'한 게 아니면(백필·아카이브 없는 스킬의 수정) 이번 PR Summary는 추가 이유가 아니다
    intro = pr if action == "added" else intro_info(repo, name)
    if not issue:
        issue = create_issue(repo, title, issue_body(repo, meta, intro))
        issues[title] = issue
        log(f"  📁 아카이브 이슈 생성 {issue['url']}")
        log(f"  💬 Discord 스레드 {open_thread(repo, meta, intro, issue)}")
        return

    # 이미 아카이브된 스킬: 설명 블록 최신화 + (닫혀 있으면) 재오픈
    readded = issue["state"] != "OPEN"
    if readded:
        gh_write(["issue", "reopen", str(issue["number"]), "--repo", repo])
    new_body = DESC_BLOCK.sub(lambda _: desc_block(meta), issue["body"] or "", count=1)
    if new_body != issue["body"]:
        edit_issue_body(repo, issue, new_body)

    if not thread_id:  # 이전 실행에서 Discord만 실패했던 경우 → 소개 글부터 다시(최신 내용이라 변경 글은 생략)
        log(f"  💬 Discord 스레드(재시도) {open_thread(repo, meta, intro, issue)}")
        return

    if action == "backfill":
        log("  이미 스레드 있음 — 건너뜀")
        return

    text = change_text("readded" if readded else "modified", pr, compare_url)
    if thread_id:
        post_webhook({"content": truncate(text, 2000)}, thread_id)
    comment_issue(repo, issue, text)
    log(f"  🔧 업데이트 기록 → {issue['url']}")


def main():
    if not WEBHOOK and not DRY_RUN:
        # fail-soft: 시크릿 미설정이 develop 빌드를 빨갛게 만들지 않게
        print("::warning::DISCORD_SKILL_WEBHOOK_URL 시크릿이 없어 스킬 아카이브를 건너뜀")
        return 0

    repo = resolve_repo()
    after = os.environ.get("AFTER") or run(["git", "rev-parse", "HEAD"]).strip()
    os.environ["AFTER"] = after
    before = os.environ.get("BEFORE", "")
    input_skills = os.environ.get("INPUT_SKILLS", "").strip()

    if input_skills:
        if input_skills == "all":
            names = sorted(d for d in os.listdir(SKILLS_DIR) if os.path.isfile(f"{SKILLS_DIR}/{d}/SKILL.md"))
        else:
            names = [s.strip() for s in input_skills.split(",") if s.strip()]
        targets = {n: "backfill" for n in names}
        pr_of = lambda _: None  # 백필은 process()가 intro_info()로 도입 커밋 기준 정보를 만든다
        compare_url = None
    else:
        targets = collect_changes(before, after)
        pr = find_pr(repo, after)
        pr_of = lambda _: pr
        compare_url = f"{SERVER}/{repo}/compare/{before}...{after}" if before and before != ZERO_SHA else None

    if not targets:
        log("변경된 스킬 없음")
        return 0

    if not DRY_RUN:
        gh_write(["label", "create", LABEL, "--repo", repo, "--color", "5865F2",
                  "--description", "Claude 스킬 아카이브 (skill-archive 워크플로 관리)", "--force"])
    issues = load_archive_issues(repo)

    failed = []
    for name, action in targets.items():
        log(f"▶ {name} ({action})")
        try:
            process(repo, issues, name, action, pr_of(name), compare_url)
        except Exception as e:  # 한 스킬 실패가 나머지를 막지 않게 모아서 마지막에 실패 처리
            log(f"  ❌ {e}")
            failed.append(name)
        time.sleep(0 if DRY_RUN else 1)

    if failed:
        print(f"::error::스킬 아카이브 실패: {', '.join(failed)} — workflow_dispatch(skills=…)로 재시도 가능")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
