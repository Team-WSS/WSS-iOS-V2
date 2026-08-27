#!/usr/bin/env bash
#
# Swift 6 준비도(A4) — strict concurrency 경고 수집기. report-only가 기본.
#
# 왜 이렇게 하나 (코드만 봐선 모르는 배경):
#   Swift 6로 한 번에 넘어가면 위험하다(애플 공식 가이드도 "모듈 하나씩 천천히"를 전제).
#   그래서 A4 1단계는 Swift 5 모드를 **그대로 두고** `SWIFT_STRICT_CONCURRENCY=complete`만
#   빌드 세팅으로 얹는다 → strict concurrency 위반이 error가 아니라 **warning**으로 뜬다.
#   빌드는 안 깨지고, 우리는 "Swift 6에서 error가 될 것들"의 목록·규모만 모은다.
#
#   ⚠️ 왜 App 스킴(WSS-iOS) 한 방이 아니라 모듈 스킴을 하나씩 도나:
#     App 스킴을 fresh derivedDataPath로 빌드해도 프레임워크 모듈이 소스에서
#     재컴파일되지 않아(무엇이 no-op을 만드는지는 불명) 경고가 하나도 안 잡힌다.
#     반면 각 모듈 스킴을 직접 빌드하면 그 모듈이 소스에서 컴파일돼 경고가 뜬다(실측 확인).
#     그래서 모든 모듈 스킴을 **공유 DD**에 순회 빌드한다(의존 모듈은 한 번만 컴파일 → 재사용).
#
#   왜 env.baseSetting에 안 박고 빌드 오버라이드로만 주입하나:
#     baseSetting에 넣으면 전 개발자의 로컬 Xcode 빌드에 경고가 홍수처럼 뜬다(잡음).
#     이 게이트는 CI에서만 돌면 되므로 xcodebuild 명령줄 오버라이드로만 얹는다.
#
# 사용:
#   Tooling/StrictConcurrency/scan.sh [--strict] [--out <md파일>] [--layer <Layer>]
#     --strict : concurrency 경고가 1건이라도 있으면 종료코드 1(전체 게이트 승격 후 사용).
#                기본은 report-only — 집계만 출력하고 항상 0으로 끝난다.
#     --out    : 마크다운 리포트를 이 파일에도 쓴다(CI가 PR 코멘트로 사용).
#     --layer  : 특정 레이어(Domain|Data|Core|UI|Feature)만 빌드·집계(레이어별 승격 검증용).
#
#   전제: 이미 `tuist generate`로 WSS-iOS-V2.xcworkspace가 생성돼 있어야 한다.
#
set -uo pipefail

STRICT=0
OUT=""
LAYER=""
while [ $# -gt 0 ]; do
  case "$1" in
    --strict) STRICT=1; shift ;;
    --out)    OUT="${2:-}"; shift 2 ;;
    --layer)  LAYER="${2:-}"; shift 2 ;;
    *) echo "알 수 없는 인자: $1" >&2; exit 2 ;;
  esac
done

WORKSPACE="WSS-iOS-V2.xcworkspace"
if [ ! -d "$WORKSPACE" ]; then
  echo "::error::$WORKSPACE 가 없습니다 — 먼저 'tuist generate'를 실행하세요." >&2
  exit 3
fi

# 전제 검증(추측 금지): xcodebuild이 실제로 있는지.
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "::error::xcodebuild을 찾을 수 없습니다(macOS 러너가 아닙니다)." >&2
  exit 3
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
DD="$WORKDIR/DD"
COMBINED="$WORKDIR/combined.log"
: > "$COMBINED"

# 스킴 목록: xcodebuild -list에서 뽑아 App/워크스페이스 스킴만 제외한다(모듈 스킴만 남김).
# ModuleType에 스킴을 다시 하드코딩하지 않기 위해 -list를 진실 소스로 쓴다.
SCHEMES_RAW="$(xcodebuild -workspace "$WORKSPACE" -list -json 2>/dev/null)"
if [ -z "$SCHEMES_RAW" ]; then
  echo "::error::스킴 목록을 가져오지 못했습니다(xcodebuild -list 실패)." >&2
  exit 4
fi

# 제외: App 스킴 3종(WSS-iOS, -DEBUG, -RELEASE) + 워크스페이스 집계 스킴.
mapfile_compat() {
  # bash 3.2 호환: python으로 스킴 배열을 개행 목록으로.
  python3 - "$SCHEMES_RAW" << 'PY'
import json, sys
data = json.loads(sys.argv[1])
schemes = data.get("workspace", {}).get("schemes", [])
EXCLUDE = {"WSS-iOS", "WSS-iOS-DEBUG", "WSS-iOS-RELEASE", "WSS-iOS-V2-Workspace"}
for s in schemes:
    if s in EXCLUDE:
        continue
    print(s)
PY
}

SCHEMES=()
while IFS= read -r s; do
  [ -n "$s" ] || continue
  SCHEMES+=("$s")
done < <(mapfile_compat)

if [ ${#SCHEMES[@]} -eq 0 ]; then
  echo "::error::빌드할 모듈 스킴이 없습니다." >&2
  exit 4
fi

# --layer 필터: 경로가 아니라 스킴명 접미로 거른다(Domain/Data/Feature) 또는 Core/UI는 명시 목록.
layer_match() {
  local scheme="$1"
  case "$LAYER" in
    "") return 0 ;;
    Domain)  [[ "$scheme" == *Domain ]] ;;
    Data)    [[ "$scheme" == *Data ]] ;;
    Feature) [[ "$scheme" == *Feature ]] ;;
    Core)    [[ "$scheme" == Keychain || "$scheme" == Logger || "$scheme" == Networking || "$scheme" == PushAuthorization ]] ;;
    UI)      [[ "$scheme" == DesignSystem || "$scheme" == WSSComponent ]] ;;
    *) echo "알 수 없는 --layer: $LAYER (Domain|Data|Core|UI|Feature)" >&2; exit 2 ;;
  esac
}

BUILD_FAILED=0
echo "🔎 strict concurrency 스캔 — 모듈 ${#SCHEMES[@]}개${LAYER:+ (레이어: $LAYER)}, mode: $([ $STRICT -eq 1 ] && echo strict || echo report-only)"
for S in "${SCHEMES[@]}"; do
  layer_match "$S" || continue
  L="$WORKDIR/mod-$S.log"
  xcodebuild build \
    -workspace "$WORKSPACE" \
    -scheme "$S" \
    -sdk iphonesimulator \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DD" \
    SWIFT_STRICT_CONCURRENCY=complete \
    -quiet > "$L" 2>&1
  EC=$?
  ERRS=$(grep -c ': error:' "$L" 2>/dev/null || true)
  # 진짜 컴파일 실패(concurrency는 warning이라 여기 안 걸림)는 fail-loud로 표시.
  if [ "$EC" -ne 0 ] || [ "${ERRS:-0}" -ne 0 ]; then
    echo "::error::[$S] 빌드 실패(exit=$EC, error=$ERRS) — concurrency와 무관한 컴파일 오류입니다."
    grep ': error:' "$L" | sort -u | head -10
    BUILD_FAILED=1
  fi
  cat "$L" >> "$COMBINED"
done

# 집계 + 마크다운 리포트: concurrency 계열 경고만 dedupe해 레이어/모듈별로 센다.
REPORT="$WORKDIR/report.md"
COUNT="$(python3 - "$COMBINED" "$REPORT" << 'PY'
import re, sys
log_path, report_path = sys.argv[1], sys.argv[2]

# concurrency 계열 판별 키워드(대소문자 무시). strict concurrency가 켜져야만 뜨는 진단들.
KEYS = re.compile(
    r"sendable|concurrency-safe|swift 6 language mode|@?preconcurrency|"
    r"actor-isolated|main actor|global actor|nonisolated|data race|"
    r"non-sendable|mutable state|@sendable|isolated conformance",
    re.IGNORECASE,
)
WARN = re.compile(r'^(/[^:]+):(\d+):(\d+): warning: (.*)$')
PROJ = re.compile(r'/Projects/([^/]+)/([^/]+)/')

seen = set()
buckets = {}   # (layer, module) -> count
for line in open(log_path, encoding="utf-8", errors="ignore"):
    m = WARN.match(line.strip())
    if not m:
        continue
    path, ln, col, msg = m.groups()
    if not KEYS.search(msg):
        continue
    key = (path, ln, col, msg)
    if key in seen:
        continue
    seen.add(key)
    pm = PROJ.search(path)
    if pm:
        layer, module = pm.group(1), pm.group(2)
    else:
        layer, module = "(기타)", "(기타)"
    buckets[(layer, module)] = buckets.get((layer, module), 0) + 1

total = sum(buckets.values())
LAYER_ORDER = {"Domain": 0, "Core": 1, "UI": 2, "Data": 3, "Feature": 4, "App": 5}
rows = sorted(buckets.items(), key=lambda kv: (LAYER_ORDER.get(kv[0][0], 9), -kv[1], kv[0][1]))

with open(report_path, "w", encoding="utf-8") as f:
    f.write("## Swift 6 준비도 — strict concurrency 경고\n\n")
    f.write(f"`SWIFT_STRICT_CONCURRENCY=complete`로 빌드했을 때 뜨는 경고(= Swift 6에서 error가 될 것들). **총 {total}건.**\n\n")
    if total == 0:
        f.write("🎉 concurrency 경고 없음 — 이 범위는 Swift 6 준비 완료.\n")
    else:
        # 레이어 소계
        by_layer = {}
        for (layer, _mod), c in buckets.items():
            by_layer[layer] = by_layer.get(layer, 0) + c
        f.write("| Layer | 경고 |\n|---|---|\n")
        for layer in sorted(by_layer, key=lambda l: LAYER_ORDER.get(l, 9)):
            f.write(f"| {layer} | {by_layer[layer]} |\n")
        f.write("\n<details><summary>모듈별 상세</summary>\n\n")
        f.write("| Layer | Module | 경고 |\n|---|---|---|\n")
        for (layer, module), c in rows:
            f.write(f"| {layer} | {module} | {c} |\n")
        f.write("\n</details>\n")
    f.write("\n<sub>report-only — 이 잡은 실패하지 않습니다. 레이어별 경고 0 달성 후 그 레이어를 error로 승격합니다.</sub>\n")

print(total)
PY
)"

cat "$REPORT"
if [ -n "$OUT" ]; then
  cp "$REPORT" "$OUT"
fi

# 진짜 빌드 실패는 항상 실패로(concurrency와 무관한 breakage는 숨기면 안 됨).
if [ "$BUILD_FAILED" -ne 0 ]; then
  echo "::error::일부 모듈이 concurrency와 무관한 이유로 빌드 실패했습니다(위 참조)." >&2
  exit 1
fi

if [ "$STRICT" -eq 1 ] && [ "${COUNT:-0}" -ne 0 ]; then
  echo "::error::strict 모드: concurrency 경고 ${COUNT}건 — 게이트 실패." >&2
  exit 1
fi

[ "$STRICT" -eq 0 ] && [ "${COUNT:-0}" -ne 0 ] && echo "ℹ️ (report-only) concurrency 경고 ${COUNT}건 — 게이트를 실패시키지 않습니다."
exit 0
