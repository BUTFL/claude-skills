#!/usr/bin/env bash
# 反向同步：把本机 skills 收集回本仓库，可选自动提交推送。
# 支持中英双语界面（--lang zh|en），--pick 交互选择时会先让用户选语言。
# 提交前会自动运行 scripts/gen-docs.py，同步 README.md（中文）与 README.en.md（英文）。
# .skillignore 中列出的 skill 会被跳过，且若已存在于仓库会被移除（不上传）。
#
# 用法：
#   ./upload.sh                        # 从 ~/.claude/skills 收集到 ./skills/（不推送）
#   ./upload.sh --pick                 # 交互选择语言 + 选择要上传的 skill
#   ./upload.sh --lang en --pick       # 直接指定英文界面
#   ./upload.sh --from both            # 从 claude + codebuddy 两边收集
#   ./upload.sh --push                 # 先跑 validate.sh 校验，通过后自动 commit + push
#   ./upload.sh --dry-run              # 只预览会做什么，不写入
#   ./upload.sh --prune                # 删除仓库里本机已不存在的 skill（谨慎）
#   ./upload.sh --no-docs              # 跳过中英文档自动同步
#   ./upload.sh --skip-check           # 跳过校验（不推荐）
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
DEST="$REPO_DIR/skills"
ZH_MAP="$REPO_DIR/descriptions.zh.json"
EN_MAP="$REPO_DIR/descriptions.en.json"
IGNORE_FILE="$REPO_DIR/.skillignore"
FROM="claude"
PUSH=""
DRY=""
PRUNE=""
SKIP_CHECK=""
NO_DOCS=""
PICK=""
LANG_MODE=""
PR_MODE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --from) FROM="${2:-claude}"; shift 2 ;;
    --lang) LANG_MODE="${2:-zh}"; shift 2 ;;
    --pick|-i) PICK=1; shift ;;
    --push) PUSH=1; shift ;;
    --pr) PR_MODE=1; shift ;;
    --dry-run) DRY=1; shift ;;
    --prune) PRUNE=1; shift ;;
    --no-docs) NO_DOCS=1; shift ;;
    --skip-check) SKIP_CHECK=1; shift ;;
    -h|--help)
      echo "用法: upload.sh [--lang zh|en] [--pick] [--from claude|codebuddy|both] [--push|--pr] [--dry-run] [--prune] [--no-docs] [--skip-check]"
      echo "  --push  校验通过后直接提交并推送到 main"
      echo "  --pr    校验通过后新建分支、推送并创建 Pull Request（描述自动中英双语）"
      exit 0 ;;
    *) echo "未知参数：$1" >&2; exit 1 ;;
  esac
done

# 双语提示：msg "中文" "English"
msg() {
  if [ "${LANG_MODE:-zh}" = "en" ]; then
    echo "$2"
  else
    echo "$1"
  fi
}

src_dirs() {
  case "$FROM" in
    claude)    echo "$HOME/.claude/skills" ;;
    codebuddy) echo "$HOME/.codebuddy/skills" ;;
    both)
      echo "$HOME/.claude/skills"
      echo "$HOME/.codebuddy/skills" ;;
    *) echo "未知 --from：$FROM（支持 claude|codebuddy|both）" >&2; exit 1 ;;
  esac
}

# .skillignore 是本地私有文件（不上传）。缺失时自动从示例初始化。
if [ ! -f "$IGNORE_FILE" ] && [ -f "$IGNORE_FILE.example" ]; then
  cp "$IGNORE_FILE.example" "$IGNORE_FILE"
fi

# 判断 skill 是否在忽略名单中
is_ignored() {
  local n="$1"
  [ -f "$IGNORE_FILE" ] || return 1
  grep -qE "^[[:space:]]*${n}[[:space:]]*$" "$IGNORE_FILE"
}

# 取 skill 的说明：中文模式优先 descriptions.zh.json；英文模式用 SKILL.md 原文
# 用法：skill_desc <skill 目录> [zh|en]，第二参数省略时跟随 LANG_MODE
skill_desc() {
  local _dir="$1"
  local _lang="${2:-${LANG_MODE:-zh}}"
  python3 - "$_dir/SKILL.md" "$ZH_MAP" "$(basename "$_dir")" "$_lang" <<'PY'
import json, re, sys
skill_md, zh_map, name, lang = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

def raw():
    try:
        t = open(skill_md, encoding='utf-8').read()
    except Exception:
        return ''
    m = re.match(r'^---\s*\n(.*?)\n---', t, re.S)
    if not m:
        return ''
    fm = m.group(1)
    mm = re.search(r'^description:\s*(.*)$', fm, re.M)
    if not mm:
        return ''
    val = mm.group(1).strip()
    if val in ('', '>', '>-', '>+', '|', '|-', '|+'):
        lines = fm.splitlines()
        idx = next((i for i, l in enumerate(lines) if l.startswith('description:')), None)
        buf = []
        if idx is not None:
            for line in lines[idx + 1:]:
                if re.match(r'^\s+', line):
                    buf.append(line.strip())
                elif line.strip() == '':
                    continue
                else:
                    break
        val = ' '.join(x for x in buf if x)
    return re.sub(r'\s+', ' ', val).strip()

if lang != 'en':
    try:
        zh = json.load(open(zh_map, encoding='utf-8'))
        v = (zh.get(name) or '').strip()
        if v:
            print(v); sys.exit()
    except Exception:
        pass

print(raw()[:200])
PY
}

# 检查某 skill 是否已有对应语言的说明
has_zh() {
  python3 -c "import json,sys; d=json.load(open(sys.argv[1],encoding='utf-8')); sys.exit(0 if (d.get(sys.argv[2]) or '').strip() else 1)" "$ZH_MAP" "$1" 2>/dev/null
}
has_en() {
  python3 -c "import json,sys; d=json.load(open(sys.argv[1],encoding='utf-8')); sys.exit(0 if (d.get(sys.argv[2]) or '').strip() else 1)" "$EN_MAP" "$1" 2>/dev/null
}

mkdir -p "$DEST"
added=0 updated=0 removed=0
ADD_LIST=()
UPD_LIST=()
PICK_LIST_FILE=""

# 0) 语言选择 + 交互选择要上传的 skill
if [ -n "$PICK" ]; then
  if [ -z "$LANG_MODE" ]; then
    if [ -t 0 ]; then
      echo "请选择语言 / Please select a language:"
      echo "  1) 中文"
      echo "  2) English"
      printf '[1/2, 默认 1 / default 1]: '
      read -r lsel || lsel=""
      if [ "$lsel" = "2" ]; then LANG_MODE="en"; else LANG_MODE="zh"; fi
    else
      LANG_MODE="zh"
    fi
  fi
fi
[ -z "$LANG_MODE" ] && LANG_MODE="zh"

if [ -n "$PICK" ]; then
  cands=()
  while IFS= read -r line; do
    [ -n "$line" ] && cands+=("$line")
  done < <(for src in $(src_dirs); do
      [ -d "$src" ] || continue
      for d in "$src"/*/; do
        [ -f "$d/SKILL.md" ] || continue
        basename "$d"
      done
    done | sort -u)

  if [ ${#cands[@]} -eq 0 ]; then
    msg "本机没有可上传的 skill。" "No local skills found to upload."
    exit 0
  fi

  PICK_LIST_FILE="$(mktemp)"
  if command -v fzf >/dev/null 2>&1 && [ -t 0 ]; then
    msg "→ 用 fzf 选择要上传的 skill（Tab 多选，回车确认）..." \
        "→ Select skills to upload with fzf (Tab to select, Enter to confirm)..."
    if [ "$LANG_MODE" = "en" ]; then
      prompt_str="Select skills to upload > "
    else
      prompt_str="选择要上传的 skill > "
    fi
    printf '%s\n' "${cands[@]}" | fzf --multi --prompt="$prompt_str" > "$PICK_LIST_FILE"
  else
    msg "→ 本机可上传的 skill：" "→ Local skills available:"
    i=1
    for n in "${cands[@]}"; do
      if is_ignored "$n"; then
        if [ "$LANG_MODE" = "en" ]; then
          printf '  %2d) %s  (already in .skillignore)\n' "$i" "$n"
        else
          printf '  %2d) %s  (已在 .skillignore)\n' "$i" "$n"
        fi
      else
        printf '  %2d) %s\n' "$i" "$n"
      fi
      i=$((i + 1))
    done
    echo ""
    if [ "$LANG_MODE" = "en" ]; then
      printf 'Enter numbers (space separated; a = all; Enter = cancel): '
    else
      printf '输入要上传的编号（空格分隔；a=全部；回车=取消）：'
    fi
    read -r sel || sel=""
    if [ -z "$sel" ]; then
      msg "未选择，取消上传。" "Nothing selected, upload cancelled."
      rm -f "$PICK_LIST_FILE"
      exit 0
    fi
    if [ "$sel" = "a" ] || [ "$sel" = "A" ]; then
      printf '%s\n' "${cands[@]}" > "$PICK_LIST_FILE"
    else
      for idx in $sel; do
        if [ "$idx" -ge 1 ] 2>/dev/null && [ "$idx" -le ${#cands[@]} ] 2>/dev/null; then
          echo "${cands[$((idx - 1))]}" >> "$PICK_LIST_FILE"
        fi
      done
    fi
  fi

  if [ ! -s "$PICK_LIST_FILE" ]; then
    msg "未选择任何 skill，取消上传。" "No skill selected, upload cancelled."
    rm -f "$PICK_LIST_FILE"
    exit 0
  fi

  # 询问是否把未选中的加入忽略名单
  notsel=()
  for n in "${cands[@]}"; do
    grep -qxF "$n" "$PICK_LIST_FILE" 2>/dev/null || notsel+=("$n")
  done
  if [ ${#notsel[@]} -gt 0 ] && [ -t 0 ]; then
    echo ""
    msg "未选择：${notsel[*]}" "Not selected: ${notsel[*]}"
    if [ "$LANG_MODE" = "en" ]; then
      printf 'Add unselected to .skillignore (skip automatically next time)? [y/N] '
    else
      printf '把未选中的加入 .skillignore（下次自动跳过）？[y/N] '
    fi
    read -r ans || ans=""
    if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then
      for n in "${notsel[@]}"; do
        is_ignored "$n" || echo "$n" >> "$IGNORE_FILE"
      done
      msg "✓ 已加入 .skillignore：${notsel[*]}" "✓ Added to .skillignore: ${notsel[*]}"
    fi
  fi
  echo ""
fi

# 本次上传白名单（未用 --pick 时全部允许）
pick_ok() {
  [ -z "$PICK" ] && return 0
  grep -qxF "$1" "$PICK_LIST_FILE" 2>/dev/null
}

# 0.5) 移除仓库中本应忽略的 skill（不上传）
if [ -f "$IGNORE_FILE" ]; then
  while IFS= read -r n; do
    n="$(echo "$n" | tr -d '[:space:]')"
    [ -z "$n" ] && continue
    case "$n" in \#*) continue ;; esac
    if [ -d "$DEST/$n" ]; then
      [ -z "$DRY" ] && rm -rf "$DEST/$n"
      if [ "$LANG_MODE" = "en" ]; then
        echo "- removed $n (in .skillignore, not uploaded)"
      else
        echo "- 移除 $n（在 .skillignore 中，不上传）"
      fi
      removed=$((removed+1))
    fi
  done < "$IGNORE_FILE"
fi

# 1) 收集本机 skill 到仓库
for src in $(src_dirs); do
  [ -d "$src" ] || continue
  for d in "$src"/*/; do
    [ -f "$d/SKILL.md" ] || continue
    name="$(basename "$d")"
    if is_ignored "$name"; then
      msg "· 跳过 $name（在 .skillignore 中）" "· skipped $name (in .skillignore)"
      continue
    fi
    if ! pick_ok "$name"; then
      msg "· 跳过 $name（本次未选择）" "· skipped $name (not selected this time)"
      continue
    fi
    if [ -e "$DEST/$name" ]; then
      if diff -rq "$d" "$DEST/$name" >/dev/null 2>&1; then
        continue
      fi
      [ -z "$DRY" ] && { rm -rf "$DEST/$name"; cp -R "$d" "$DEST/$name"; }
      if [ "$LANG_MODE" = "en" ]; then
        echo "↻ updated $name: $(skill_desc "$d")"
      else
        echo "↻ 更新 $name：$(skill_desc "$d")"
      fi
      updated=$((updated+1)); UPD_LIST+=("$name")
    else
      [ -z "$DRY" ] && cp -R "$d" "$DEST/$name"
      if [ "$LANG_MODE" = "en" ]; then
        echo "+ added $name: $(skill_desc "$d")"
      else
        echo "+ 新增 $name：$(skill_desc "$d")"
      fi
      added=$((added+1)); ADD_LIST+=("$name")
    fi
  done
done

# 2) 可选：删除仓库里本机已不存在的 skill
if [ -n "$PRUNE" ]; then
  for d in "$DEST"/*/; do
    [ -f "$d/SKILL.md" ] || continue
    name="$(basename "$d")"
    found=0
    for src in $(src_dirs); do
      [ -d "$src/$name" ] && found=1
    done
    if [ "$found" = 0 ]; then
      [ -z "$DRY" ] && rm -rf "$DEST/$name"
      msg "- 删除 $name（本机已不存在）" "- deleted $name (no longer present locally)"
      removed=$((removed+1))
    fi
  done
fi

# 3) 清理杂项
if [ -z "$DRY" ]; then
  find "$DEST" -name .DS_Store -delete 2>/dev/null || true
  find "$DEST" -name '.last-*' -delete 2>/dev/null || true
  rm -rf "$DEST"/template 2>/dev/null || true
fi

echo "---"
if [ "$LANG_MODE" = "en" ]; then
  echo "added $added, updated $updated, removed $removed"
else
  echo "新增 $added 个，更新 $updated 个，移除 $removed 个"
fi

# 双语说明缺口检测：缺哪边就提示补哪边（由 AI 自动翻译补齐，用户无需操作）
miss_zh=""
miss_en=""
changed_all=()
if [ ${#ADD_LIST[@]} -gt 0 ]; then changed_all+=("${ADD_LIST[@]}"); fi
if [ ${#UPD_LIST[@]} -gt 0 ]; then changed_all+=("${UPD_LIST[@]}"); fi
if [ ${#changed_all[@]} -gt 0 ]; then
  for n in "${changed_all[@]}"; do
    has_zh "$n" || miss_zh="$miss_zh $n"
    has_en "$n" || miss_en="$miss_en $n"
  done
fi
if [ -n "$miss_zh" ]; then
  msg "⚠️ 以下 skill 缺少中文说明（已回退原文），将由 AI 自动翻译补进 descriptions.zh.json：" \
      "⚠️ missing Chinese description (used original), AI will translate into descriptions.zh.json:"
  echo "  $miss_zh"
fi
if [ -n "$miss_en" ]; then
  msg "⚠️ 以下 skill 缺少英文说明（已回退原文），将由 AI 自动翻译补进 descriptions.en.json：" \
      "⚠️ missing English description (used original), AI will translate into descriptions.en.json:"
  echo "  $miss_en"
fi

if [ -n "$DRY" ]; then
  [ -n "$PICK_LIST_FILE" ] && rm -f "$PICK_LIST_FILE"
  msg "（dry-run，未写入任何文件）" "(dry-run, nothing was written)"
  exit 0
fi

cd "$REPO_DIR"

# 3.5) 自动同步中英文档
if [ -z "$NO_DOCS" ]; then
  if command -v python3 >/dev/null 2>&1 && [ -f "$REPO_DIR/scripts/gen-docs.py" ]; then
    python3 "$REPO_DIR/scripts/gen-docs.py" > /dev/null || echo "⚠️ 文档生成失败，继续提交"
  else
    echo "⚠️ 缺少 python3 或 scripts/gen-docs.py，跳过文档同步"
  fi
fi

[ -n "$PICK_LIST_FILE" ] && rm -f "$PICK_LIST_FILE"

if [ -z "$(git status --porcelain)" ]; then
  msg "仓库无变化，无需提交。" "Nothing changed, nothing to commit."
  exit 0
fi

# 4) 生成提交信息（跟随所选语言）
NOW="$(date '+%Y-%m-%d %H:%M')"
TODAY="$(date '+%Y-%m-%d')"

# 非 skill 的其他文件改动（脚本、文档、LICENSE 等）——避免"提交什么都不写"
# 注意：case 必须写在函数体内。bash 3.2（macOS 自带）在 $( ) 命令替换内部
# 直接写 case 时，会把模式里的 ")" 误解析为替换结束，导致语法错误。
collect_other_changes() {
  git status --porcelain | head -50 | while IFS= read -r line; do
    st="${line:0:2}"
    path="${line:3}"
    case "$path" in skills/*) continue ;; esac
    case "$st" in
      M*|" M") t="修改"; te="modified" ;;
      A*|"??") t="新增"; te="added" ;;
      D*|" D") t="删除"; te="deleted" ;;
      R*)      t="重命名"; te="renamed" ;;
      *)       t="变更"; te="changed" ;;
    esac
    if [ "$LANG_MODE" = "en" ]; then echo "- [$te] $path"; else echo "- [$t] $path"; fi
  done
}
other_out="$(collect_other_changes)"

msgfile="$(mktemp)"
{
  if [ "$LANG_MODE" = "en" ]; then
    echo "skills update ($TODAY)"
    if [ ${#ADD_LIST[@]} -gt 0 ]; then
      echo ""
      echo "Added ${#ADD_LIST[@]}:"
      for n in "${ADD_LIST[@]}"; do echo "- $n: $(skill_desc "$DEST/$n")"; done
    fi
    if [ ${#UPD_LIST[@]} -gt 0 ]; then
      echo ""
      echo "Updated ${#UPD_LIST[@]}:"
      for n in "${UPD_LIST[@]}"; do echo "- $n: $(skill_desc "$DEST/$n")"; done
    fi
    if [ "$removed" -gt 0 ]; then
      echo ""
      echo "Removed $removed."
    fi
    if [ -n "$other_out" ]; then
      echo ""
      echo "Other changes:"
      echo "$other_out"
    fi
    echo ""
    echo "Committed at: $NOW"
  else
    echo "skills 更新（$TODAY）"
    if [ ${#ADD_LIST[@]} -gt 0 ]; then
      echo ""
      echo "新增 ${#ADD_LIST[@]} 个："
      for n in "${ADD_LIST[@]}"; do echo "- $n：$(skill_desc "$DEST/$n")"; done
    fi
    if [ ${#UPD_LIST[@]} -gt 0 ]; then
      echo ""
      echo "更新 ${#UPD_LIST[@]} 个："
      for n in "${UPD_LIST[@]}"; do echo "- $n：$(skill_desc "$DEST/$n")"; done
    fi
    if [ "$removed" -gt 0 ]; then
      echo ""
      echo "移除 $removed 个。"
    fi
    if [ -n "$other_out" ]; then
      echo ""
      echo "其他改动："
      echo "$other_out"
    fi
    echo ""
    echo "提交时间：$NOW"
  fi
} > "$msgfile"

echo "=== 提交信息预览 / commit preview ==="
cat "$msgfile"
echo "======================"

if [ -n "$PUSH" ] || [ -n "$PR_MODE" ]; then
  if [ -z "$SKIP_CHECK" ]; then
    msg "→ 上传前校验（validate.sh）..." "→ Running validation (validate.sh)..."
    if ! bash "$REPO_DIR/validate.sh" > /tmp/validate_out.txt 2>&1; then
      cat /tmp/validate_out.txt
      echo ""
      msg "⛔ 校验未通过，已取消提交。请修复后重试。" \
          "⛔ Validation failed — commit aborted. Fix the issues and retry."
      rm -f "$msgfile"
      exit 1
    fi
    msg "→ 校验通过，继续提交。" "→ Validation passed, committing."
  else
    echo "⚠️ 已用 --skip-check 跳过校验 / validation skipped"
  fi

  if [ -n "$PR_MODE" ]; then
    # ---- PR 流程：新建分支 → 提交 → 推送 → 创建中英双语 PR ----
    BRANCH="sync/$(date '+%Y%m%d-%H%M%S')"
    git checkout -b "$BRANCH" >/dev/null 2>&1
    git add -A
    git -c user.name=BUTFL -c user.email=BUTFL@users.noreply.github.com commit -F "$msgfile"
    git -c http.version=HTTP/1.1 push -u origin "$BRANCH"

    prfile="$(mktemp)"
    {
      echo "## 变更说明（中文）"
      echo ""
      if [ ${#ADD_LIST[@]} -gt 0 ]; then
        echo "**新增 ${#ADD_LIST[@]} 个：**"
        for n in "${ADD_LIST[@]}"; do echo "- \`$n\`：$(skill_desc "$DEST/$n" zh)"; done
        echo ""
      fi
      if [ ${#UPD_LIST[@]} -gt 0 ]; then
        echo "**更新 ${#UPD_LIST[@]} 个：**"
        for n in "${UPD_LIST[@]}"; do echo "- \`$n\`：$(skill_desc "$DEST/$n" zh)"; done
        echo ""
      fi
      if [ "$removed" -gt 0 ]; then
        echo "**移除 $removed 个。**"
        echo ""
      fi
      echo "> \`./validate.sh\` 全部通过；中英文档已自动同步（README.md / README.en.md）。"
      echo ""
      echo "---"
      echo ""
      echo "## Summary (English)"
      echo ""
      if [ ${#ADD_LIST[@]} -gt 0 ]; then
        echo "**Added ${#ADD_LIST[@]}:**"
        for n in "${ADD_LIST[@]}"; do echo "- \`$n\`: $(skill_desc "$DEST/$n" en)"; done
        echo ""
      fi
      if [ ${#UPD_LIST[@]} -gt 0 ]; then
        echo "**Updated ${#UPD_LIST[@]}:**"
        for n in "${UPD_LIST[@]}"; do echo "- \`$n\`: $(skill_desc "$DEST/$n" en)"; done
        echo ""
      fi
      if [ "$removed" -gt 0 ]; then
        echo "**Removed $removed.**"
        echo ""
      fi
      echo "> \`./validate.sh\` passed; both READMEs synced automatically."
    } > "$prfile"

    PR_TITLE="skills 更新 / skills update（$TODAY）"
    echo "→ 创建 Pull Request..."
    gh pr create --base main --head "$BRANCH" --title "$PR_TITLE" --body-file "$prfile"
    msg "✓ 已创建 PR（分支：$BRANCH）" "✓ Pull Request created (branch: $BRANCH)"
    git checkout main >/dev/null 2>&1
    rm -f "$prfile"
  else
    git add -A
    git -c user.name=BUTFL -c user.email=BUTFL@users.noreply.github.com commit -F "$msgfile"
    git -c http.version=HTTP/1.1 push
    msg "✓ 已提交并推送" "✓ committed and pushed"

    # 顺带同步仓库 About 描述里的 skill 数量（失败不影响主流程）
    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
      _cnt=$(ls -1 "$DEST" | wc -l | tr -d ' ')
      gh repo edit "${REPO_SLUG:-BUTFL/claude-skills}" --description \
        "Claude Code skills 合集（${_cnt} 个）：一键安装、中英双语文档、上传前自动校验 | My Claude Code skills collection (${_cnt} skills): one-command install, bilingual docs, auto-validation before upload" \
        >/dev/null 2>&1 || true
      msg "✓ 已同步仓库描述（${_cnt} 个 skill）" "✓ repo description synced (${_cnt} skills)"
    fi
  fi
else
  msg "已写入仓库（未提交）。加 --push 直接推送，或 --pr 创建 Pull Request。" \
      "Written to repo (not committed). Add --push to push, or --pr to open a Pull Request."
fi
rm -f "$msgfile"
