#!/usr/bin/env bash
# 上传前强制校验：格式规范 + 安全扫描 + 中文说明完整性。
# 任一项失败即退出码非 0，upload.sh --push 会因此中止提交。
#
#   ./validate.sh            # 跑全部检查
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
SKILLS="$REPO_DIR/skills"
ZH_MAP="$REPO_DIR/descriptions.zh.json"

fails=0
warns=0
fail() { echo "  ✗ $1"; fails=$((fails + 1)); }
warn() { echo "  ⚠ $1"; warns=$((warns + 1)); }
ok()   { echo "  ✓ $1"; }

if [ ! -d "$SKILLS" ]; then
  echo "✗ 缺少 skills/ 目录"
  exit 1
fi

echo "=== 1. 目录结构：每个 skill 必须含 SKILL.md ==="
count=0
for d in "$SKILLS"/*/; do
  [ -d "$d" ] || continue
  count=$((count + 1))
  name="$(basename "$d")"
  if [ -f "$d/SKILL.md" ]; then ok "$name"; else fail "$name 缺少 SKILL.md"; fi
done
echo "  （共 $count 个 skill）"

echo ""
echo "=== 2. 命名规范：只允许小写字母 / 数字 / 连字符 ==="
for d in "$SKILLS"/*/; do
  name="$(basename "$d")"
  if echo "$name" | grep -qE '^[a-z0-9][a-z0-9-]*$'; then
    ok "$name"
  else
    fail "$name 命名不合规（只允许 a-z、0-9、-）"
  fi
done

echo ""
echo "=== 3. frontmatter：必须有 name 与 description，且 name 与目录名一致 ==="
python3 - "$SKILLS" <<'PY'
import os, re, sys
base = sys.argv[1]
bad = 0
for d in sorted(os.listdir(base)):
    sk = os.path.join(base, d, 'SKILL.md')
    if not os.path.isfile(sk):
        continue
    t = open(sk, encoding='utf-8').read()
    m = re.match(r'^---\s*\n(.*?)\n---', t, re.S)
    if not m:
        print(f"  ✗ {d} 缺少 frontmatter（--- 包裹）"); bad += 1; continue
    fm = m.group(1)
    if not re.search(r'^name:', fm, re.M):
        print(f"  ✗ {d} frontmatter 缺少 name"); bad += 1; continue
    if not re.search(r'^description:', fm, re.M):
        print(f"  ✗ {d} frontmatter 缺少 description"); bad += 1; continue
    nm = re.search(r'^name:\s*(.+)$', fm, re.M).group(1).strip().strip('"\'')
    if nm != d:
        print(f"  ✗ {d} frontmatter name({nm}) 与目录名不一致"); bad += 1; continue
    print(f"  ✓ {d}")
sys.exit(1 if bad else 0)
PY
[ $? -ne 0 ] && fails=$((fails + 1))

echo ""
echo "=== 4. 中文说明：descriptions.zh.json 必须覆盖每个 skill ==="
python3 - "$SKILLS" "$ZH_MAP" <<'PY'
import json, os, sys
base, zhmap = sys.argv[1], sys.argv[2]
try:
    zh = json.load(open(zhmap, encoding='utf-8'))
except Exception as e:
    print(f"  ✗ 无法读取 {zhmap}：{e}")
    sys.exit(1)
bad = 0
missing = []
for d in sorted(os.listdir(base)):
    sk = os.path.join(base, d, 'SKILL.md')
    if not os.path.isfile(sk):
        continue
    if not (zh.get(d) or '').strip():
        print(f"  ✗ {d} 缺少中文说明"); missing.append(d); bad += 1
    else:
        print(f"  ✓ {d}")
if missing:
    print(f"  → 请补进 descriptions.zh.json：{', '.join(missing)}")
sys.exit(1 if bad else 0)
PY
[ $? -ne 0 ] && fails=$((fails + 1))

echo ""
echo "=== 5. 安全扫描：敏感文件与疑似密钥 ==="
sensitive=$(find "$SKILLS" \( -name '.last-*' -o -name '.env' -o -name '*.pem' -o -name 'id_rsa*' \) 2>/dev/null | head -5)
if [ -n "$sensitive" ]; then
  fail "发现敏感文件："
  echo "$sensitive" | sed 's/^/      /'
else
  ok "无敏感文件"
fi

secret_files=$(grep -rIlE 'sk-[a-zA-Z0-9]{24,}|ghp_[a-zA-Z0-9]{20,}|gho_[a-zA-Z0-9]{20,}' "$SKILLS" 2>/dev/null | head -5)
if [ -n "$secret_files" ]; then
  fail "发现疑似密钥："
  echo "$secret_files" | sed 's/^/      /'
else
  ok "无疑似密钥"
fi

echo ""
echo "=== 6. 杂项：不应有 .DS_Store ==="
ds=$(find "$SKILLS" -name .DS_Store 2>/dev/null | wc -l | tr -d ' ')
if [ "$ds" -gt 0 ]; then
  warn "skills/ 下有 $ds 个 .DS_Store（upload 时会自动清理）"
else
  ok "无 .DS_Store"
fi

echo ""
echo "=== 7. 双语文档：README 与 CONTRIBUTING 必须中英双份 ==="
for f in README.md README.en.md CONTRIBUTING.md CONTRIBUTING.en.md; do
  if [ -f "$REPO_DIR/$f" ]; then
    ok "$f"
  else
    fail "缺少 $f（必须中英双文档）"
  fi
done

echo ""
echo "=== 8. 忽略名单：.skillignore 中的 skill 不应出现在仓库 ==="
if [ -f "$REPO_DIR/.skillignore" ]; then
  while IFS= read -r n; do
    n="$(echo "$n" | tr -d '[:space:]')"
    [ -z "$n" ] && continue
    case "$n" in \#*) continue ;; esac
    if [ -d "$SKILLS/$n" ]; then
      fail "$n 在 .skillignore 中，但仍存在于 skills/（应删除）"
    else
      ok "$n 已排除"
    fi
  done < "$REPO_DIR/.skillignore"
else
  ok "无 .skillignore（全部上传）"
fi

echo ""
echo "================================"
if [ "$fails" -eq 0 ]; then
  echo "✅ 全部检查通过（失败 0，警告 $warns）—— 可以提交"
  exit 0
else
  echo "❌ 校验未通过（失败 $fails，警告 $warns）—— 已阻止提交，请先修复"
  exit 1
fi
