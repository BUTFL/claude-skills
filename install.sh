#!/usr/bin/env bash
# 一键安装 / 更新本仓库的 skills 到 Claude Code / Codex / CodeBuddy。
# 安装/更新时会打印每个 skill 的名称与用途：优先中文（descriptions.zh.json），缺失时回退 SKILL.md 原文。
#
# 用法：
#   ./install.sh                        # 安装到 ~/.claude/skills
#   ./install.sh --target codex         # 安装到 ~/.codex/skills
#   ./install.sh --target codebuddy     # 安装到 ~/.codebuddy/skills
#   ./install.sh --target both          # Claude Code + Codex
#   ./install.sh --target all           # 三个都装
#   ./install.sh --force                # 覆盖（更新）已存在的 skill
#
# 仓库是公开的，免 clone 一键安装：
#   curl -fsSL https://raw.githubusercontent.com/BUTFL/claude-skills/main/install.sh | bash -s -- --target both
#
# 国内可用 Gitee 镜像：
#   curl -fsSL https://gitee.com/BUTFL/claude-skills/raw/main/install.sh | bash -s -- --target both
set -euo pipefail

REPO_SLUG="${REPO_SLUG:-BUTFL/claude-skills}"
REPO_URL="${REPO_URL:-https://github.com/${REPO_SLUG}.git}"
TARGET="claude"
FORCE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-claude}"; shift 2 ;;
    --force) FORCE="1"; shift ;;
    -h|--help)
      echo "用法: install.sh [--target claude|codex|codebuddy|both|all] [--force]"
      echo "  claude     ~/.claude/skills（默认）"
      echo "  codex      ~/.codex/skills"
      echo "  codebuddy  ~/.codebuddy/skills"
      echo "  both       Claude Code + Codex"
      echo "  all        三个都装"
      exit 0 ;;
    *) echo "未知参数：$1" >&2; exit 1 ;;
  esac
done

# 定位 skill 源：本地运行用仓库内 skills/；远程管道运行时先拉取（私有仓库优先走 gh 认证）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/skills" ]; then
  SRC_SKILLS="$SCRIPT_DIR/skills"
else
  tmp="$(mktemp -d)"
  echo "→ 从 GitHub 拉取仓库…"
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    gh repo clone "$REPO_SLUG" "$tmp/repo" -- --depth 1 >/dev/null 2>&1
  else
    git clone --depth 1 "$REPO_URL" "$tmp/repo" >/dev/null 2>&1
  fi
  SRC_SKILLS="$tmp/repo/skills"
fi

ZH_MAP="$(dirname "$SRC_SKILLS")/descriptions.zh.json"

# 取 skill 的中文说明：优先 descriptions.zh.json，缺失时回退 SKILL.md 原文
skill_desc() {
  python3 - "$1/SKILL.md" "$ZH_MAP" "$(basename "$1")" <<'PY'
import json, re, sys
skill_md, zh_map, name = sys.argv[1], sys.argv[2], sys.argv[3]

try:
    zh = json.load(open(zh_map, encoding='utf-8'))
    v = (zh.get(name) or '').strip()
    if v:
        print(v); sys.exit()
except Exception:
    pass

try:
    t = open(skill_md, encoding='utf-8').read()
except Exception:
    print(''); sys.exit()
m = re.match(r'^---\s*\n(.*?)\n---', t, re.S)
if not m:
    print(''); sys.exit()
fm = m.group(1)
mm = re.search(r'^description:\s*(.*)$', fm, re.M)
if not mm:
    print(''); sys.exit()
val = mm.group(1).strip()
if val in ('', '>', '>-', '>+', '|', '|-', '|+'):
    lines = fm.splitlines()
    idx = next((i for i, l in enumerate(lines) if l.startswith('description:')), None)
    buf = []
    if idx is not None:
        for l in lines[idx + 1:]:
            if re.match(r'^\s+', l):
                buf.append(l.strip())
            elif l.strip() == '':
                continue
            else:
                break
    val = ' '.join(x for x in buf if x)
print(re.sub(r'\s+', ' ', val).strip()[:160])
PY
}

install_to() {
  local dest="$1" label="$2" n=0 s=0
  mkdir -p "$dest"
  for d in "$SRC_SKILLS"/*/; do
    [ -f "$d/SKILL.md" ] || continue
    local name
    name="$(basename "$d")"
    if [ -e "$dest/$name" ] && [ -z "$FORCE" ]; then
      s=$((s+1)); continue
    fi
    rm -rf "$dest/$name"
    cp -R "$d" "$dest/$name"
    echo "  + $name：$(skill_desc "$d")"
    n=$((n+1))
  done
  echo "  ✓ $label（$dest）：安装 $n 个，跳过 $s 个已存在"
}

echo "→ 安装 skills..."
case "$TARGET" in
  claude)    install_to "$HOME/.claude/skills" "Claude Code" ;;
  codex)     install_to "$HOME/.codex/skills" "Codex" ;;
  codebuddy) install_to "$HOME/.codebuddy/skills" "CodeBuddy" ;;
  both)
    install_to "$HOME/.claude/skills" "Claude Code"
    install_to "$HOME/.codex/skills" "Codex" ;;
  all)
    install_to "$HOME/.claude/skills" "Claude Code"
    install_to "$HOME/.codex/skills" "Codex"
    install_to "$HOME/.codebuddy/skills" "CodeBuddy" ;;
  *) echo "--target 只支持 claude | codex | codebuddy | both | all" >&2; exit 1 ;;
esac

echo "完成。重启对应工具后新 skill 生效（已有的用 --force 覆盖）。"
