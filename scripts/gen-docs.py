#!/usr/bin/env python3
"""Generate both READMEs from two description maps (single source of truth per language).

- Chinese README  (README.md)     ← descriptions.zh.json
- English README  (README.en.md)  ← descriptions.en.json

If a skill is missing from the map for one language, the original `description`
of its SKILL.md is used as a fallback, and a warning tells you which entries
still need translating. Unlisted skills go to a trailing "Other / 其他" section.

Usage:
    python3 scripts/gen-docs.py

Run automatically by `upload.sh` before committing, so both documents always
stay in sync — and each language always has content.
"""
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKILLS = os.path.join(REPO, 'skills')
ZH_MAP = os.path.join(REPO, 'descriptions.zh.json')
EN_MAP = os.path.join(REPO, 'descriptions.en.json')

# (zh title, en title, [skill names]) — anything not listed goes to "Other / 其他"
CATEGORIES = [
    ("🎨 设计与视觉", "🎨 Design & Visual", [
        "algorithmic-art", "canvas-design", "frontend-design", "brand-guidelines",
        "theme-factory", "web-artifacts-builder", "slack-gif-creator",
    ]),
    ("📄 办公文档", "📄 Documents & Office", [
        "docx", "pdf", "pptx", "xlsx", "receipts", "internal-comms", "doc-coauthoring",
    ]),
    ("🛠 开发工程 / MCP", "🛠 Engineering & MCP", [
        "claude-api", "mcp-builder", "build-mcp-server", "build-mcp-app", "build-mcpb",
        "mcp-integration", "agent-development", "command-development", "hook-development",
        "plugin-settings", "plugin-structure", "skill-development", "skill-creator",
        "writing-skills", "webapp-testing", "math-olympiad",
    ]),
    ("🔄 工作流与协作", "🔄 Workflow & Collaboration", [
        "brainstorming", "writing-plans", "executing-plans", "test-driven-development",
        "systematic-debugging", "verification-before-completion",
        "subagent-driven-development", "dispatching-parallel-agents",
        "requesting-code-review", "receiving-code-review", "using-git-worktrees",
        "finishing-a-development-branch", "using-superpowers",
    ]),
    ("🤖 Claude Code 工具", "🤖 Claude Code Tools", [
        "graphify", "claude-automation-recommender", "claude-md-improver", "claude-security",
        "writing-rules", "session-report", "project-artifact", "playground",
        "discernment-nudge", "academy-guide", "karpathy-guidelines",
        "example-command", "example-skill",
    ]),
    ("👤 个人", "👤 Personal", [
        "add-tool-doc", "skill-sync",
    ]),
]

OTHER_ZH = "📦 其他"
OTHER_EN = "📦 Other"


def raw_description(name: str) -> str:
    """Read the original description from a skill's SKILL.md (fallback)."""
    path = os.path.join(SKILLS, name, 'SKILL.md')
    if not os.path.isfile(path):
        return ''
    text = open(path, encoding='utf-8').read()
    m = re.match(r'^---\s*\n(.*?)\n---', text, re.S)
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
    return re.sub(r'\s+', ' ', val).strip().strip('"\'"')


def desc_of(name: str, m: dict) -> str:
    """Description for one language: map first, SKILL.md original as fallback."""
    v = (m.get(name) or '').strip()
    return v if v else raw_description(name)


def esc(text: str, limit: int = 150) -> str:
    text = text.replace('|', '\\|')
    if len(text) > limit:
        text = text[:limit - 3].rstrip() + '...'
    return text


def build_zh(total: int, actual: set, zh: dict, others: list) -> list:
    L = []
    A = L.append
    A('# claude-skills')
    A('')
    A('[English](README.en.md) | 简体中文')
    A('')
    A(f'我的 Claude Code skills 合集（共 **{total} 个**），支持一键安装、更新与备份。')
    A('')
    A('> 中文说明来自 `descriptions.zh.json`，英文说明来自 `descriptions.en.json`；'
      '两份 README 由 `scripts/gen-docs.py` 自动生成并保持同步。')
    A('')
    A('---')
    A('')
    A('## 目录')
    A('')
    A(f'- [Skill 清单（{total} 个）](#skill-清单{total}-个)')
    A('- [一键安装](#一键安装推荐)')
    A('- [更新已有 skills](#更新已有-skills)')
    A('- [反向同步（本机 → 仓库）](#本地新增-skill-后反向同步uploadsh)')
    A('- [上传新 skill 前（强制流程）](#上传新-skill-前强制流程)')
    A('- [用 AI 一键同步](#用-ai-一键同步skill-sync)')
    A('')
    A('---')
    A('')
    A(f'## Skill 清单（{total} 个）')
    A('')
    for zh_title, _en_title, names in CATEGORIES:
        names = [n for n in names if n in actual]
        if not names:
            continue
        A(f'### {zh_title}（{len(names)}）')
        A('')
        A('| Skill | 用途 |')
        A('|---|---|')
        for n in names:
            A(f'| `{n}` | {esc(desc_of(n, zh))} |')
        A('')
    if others:
        A(f'### {OTHER_ZH}（{len(others)}）')
        A('')
        A('| Skill | 用途 |')
        A('|---|---|')
        for n in others:
            A(f'| `{n}` | {esc(desc_of(n, zh))} |')
        A('')
    A('---')
    A('')
    A('## 一键安装（推荐）')
    A('')
    A('> 本仓库是**公开**仓库，直接免 clone 一键安装：')
    A('')
    A('```bash')
    A('curl -fsSL https://raw.githubusercontent.com/BUTFL/claude-skills/main/install.sh | bash -s -- --target both')
    A('```')
    A('')
    A('或先克隆再安装：')
    A('')
    A('```bash')
    A('git clone https://github.com/BUTFL/claude-skills.git')
    A('cd claude-skills')
    A('./install.sh --target both')
    A('```')
    A('')
    A('## 更新已有 skills')
    A('')
    A('```bash')
    A('cd claude-skills')
    A('git pull')
    A('./install.sh --target both --force')
    A('```')
    A('')
    A('## 本地新增 skill 后反向同步（upload.sh）')
    A('')
    A('把本机 skills 收集回仓库（可选自动提交推送）：')
    A('')
    A('```bash')
    A('./upload.sh --from claude          # 从 ~/.claude/skills 收集')
    A('./upload.sh --pick                 # 交互选择要上传的 skill（可先选语言）')
    A('./upload.sh --push                 # 直接推送到 main')
    A('./upload.sh --pr                   # 走 Pull Request（描述自动中英双语）')
    A('```')
    A('')
    A('用 `--push` / `--pr` 时，**提交信息、终端输出、PR 描述都会列出每个新增/更新 skill 的中英双语用途**，'
      '并自动同步两份 README。')
    A('')
    A('## 上传新 skill 前（强制流程）')
    A('')
    A('| 步骤 | 内容 |')
    A('|---|---|')
    A('| ① 符合格式 | 目录结构、`SKILL.md` frontmatter（`name` 必须与目录名一致），详见 [CONTRIBUTING.md](CONTRIBUTING.md) |')
    A('| ② 校验全绿 | `./validate.sh` 必须输出 `✅ 全部检查通过` |')
    A('| ③ code review | 由 AI 复核结构、双语说明与安全，通过后才允许提交 |')
    A('| ④ 提交 | `./upload.sh --push` 或 `--pr`（内置校验，不通过会**拒绝提交**） |')
    A('')
    A('## 用 AI 一键同步（skill-sync）')
    A('')
    A('仓库内含 `skills/skill-sync`。装好后直接对 AI 说：')
    A('')
    A('> 同步我的 skills / 更新 skills / 恢复 skills')
    A('')
    A('它就会自动拉取本仓库并安装到位。')
    A('')
    A('## 说明')
    A('')
    A('| 参数 | 作用 |')
    A('|---|---|')
    A('| `--target claude` | 安装到 `~/.claude/skills`（默认） |')
    A('| `--target codebuddy` | 安装到 `~/.codebuddy/skills` |')
    A('| `--target both` | 两边都装 |')
    A('| `--force` | 覆盖已存在的同名 skill（默认跳过） |')
    A('')
    A('- 默认**跳过已存在**的 skill，不会误删你本地的其他 skill。')
    A('- 装完需**重启对应工具**，新 skill 才会出现在可用列表。')
    A('- 每个 skill 一个目录（含 `SKILL.md`），全部位于 `skills/` 下。')
    A('- 中英文档由 `scripts/gen-docs.py` 自动生成，`upload.sh` 提交前自动同步；'
      '未归类的 skill 自动进入「其他」分类。')
    A('- 不想上传的 skill 写进本地 `.skillignore`（详见 [CONTRIBUTING.md](CONTRIBUTING.md)）。')
    A('- 本仓库自身（脚本与文档）以 **MIT** 许可发布；部分 skill 来自公开市场，遵循各自原许可证。')
    A('')
    return L


def build_en(total: int, actual: set, en: dict, others: list) -> list:
    L = []
    A = L.append
    A('# claude-skills')
    A('')
    A('English | [简体中文](README.md)')
    A('')
    A(f'My **Claude Code skills** collection (total **{total}**), with one-command '
      'install, update and backup.')
    A('')
    A('> Chinese descriptions come from `descriptions.zh.json`, English ones from '
      '`descriptions.en.json`; both READMEs are generated by `scripts/gen-docs.py` and stay in sync.')
    A('')
    A('---')
    A('')
    A('## Contents')
    A('')
    A('- [Skill list](#skill-list)')
    A('- [One-line install](#one-line-install-recommended)')
    A('- [Updating skills](#updating-skills)')
    A('- [Sync back (local → repo)](#sync-back-local--repo-uploadsh)')
    A('- [Before uploading (mandatory)](#before-uploading-mandatory)')
    A('- [Sync with AI](#sync-with-ai-skill-sync)')
    A('')
    A('---')
    A('')
    A('## Skill list')
    A('')
    for _zh_title, en_title, names in CATEGORIES:
        names = [n for n in names if n in actual]
        if not names:
            continue
        A(f'### {en_title} ({len(names)})')
        A('')
        A('| Skill | What it does |')
        A('|---|---|')
        for n in names:
            A(f'| `{n}` | {esc(desc_of(n, en))} |')
        A('')
    if others:
        A(f'### {OTHER_EN} ({len(others)})')
        A('')
        A('| Skill | What it does |')
        A('|---|---|')
        for n in others:
            A(f'| `{n}` | {esc(desc_of(n, en))} |')
        A('')
    A('---')
    A('')
    A('## One-line install (recommended)')
    A('')
    A('> This is a **public** repo — install without cloning:')
    A('')
    A('```bash')
    A('curl -fsSL https://raw.githubusercontent.com/BUTFL/claude-skills/main/install.sh | bash -s -- --target both')
    A('```')
    A('')
    A('Or clone first:')
    A('')
    A('```bash')
    A('git clone https://github.com/BUTFL/claude-skills.git')
    A('cd claude-skills')
    A('./install.sh --target both')
    A('```')
    A('')
    A('## Updating skills')
    A('')
    A('```bash')
    A('cd claude-skills')
    A('git pull')
    A('./install.sh --target both --force')
    A('```')
    A('')
    A('## Sync back (local → repo) (upload.sh)')
    A('')
    A('Collect local skills back into the repo (optionally commit & push):')
    A('')
    A('```bash')
    A('./upload.sh --from claude          # collect from ~/.claude/skills')
    A('./upload.sh --pick                 # interactively choose skills (language first)')
    A('./upload.sh --push                 # push directly to main')
    A('./upload.sh --pr                   # open a Pull Request (bilingual body)')
    A('```')
    A('')
    A('With `--push` / `--pr`, the **commit message, terminal output and PR body list every '
      'added/updated skill in both Chinese and English**, and both READMEs are synced automatically.')
    A('')
    A('## Before uploading (mandatory)')
    A('')
    A('| Step | What to do |')
    A('|---|---|')
    A('| ① Format | Follow [CONTRIBUTING.en.md](CONTRIBUTING.en.md) |')
    A('| ② Validation green | `./validate.sh` must print `All checks passed` |')
    A('| ③ Code review | AI reviews structure, bilingual descriptions and security |')
    A('| ④ Submit | `./upload.sh --push` or `--pr` (validation runs automatically and **blocks** on failure) |')
    A('')
    A('## Sync with AI (skill-sync)')
    A('')
    A('The repo ships `skills/skill-sync`. Once installed, just tell the AI:')
    A('')
    A('> sync my skills / update skills / restore skills')
    A('')
    A('It will pull this repo and install everything for you.')
    A('')
    A('## Notes')
    A('')
    A('| Flag | Effect |')
    A('|---|---|')
    A('| `--target claude` | Install into `~/.claude/skills` (default) |')
    A('| `--target codebuddy` | Install into `~/.codebuddy/skills` |')
    A('| `--target both` | Install into both |')
    A('| `--force` | Overwrite existing skills (skipped by default) |')
    A('')
    A('- Existing skills are **skipped** by default; your other local skills are never deleted.')
    A('- **Restart** the tool after installing so new skills show up in the list.')
    A('- One directory per skill (containing `SKILL.md`), all under `skills/`.')
    A('- Both READMEs are generated by `scripts/gen-docs.py`; `upload.sh` syncs them before '
      'committing. Uncategorized skills land in the "Other" section automatically.')
    A('- Skills you do not want to upload go into your local `.skillignore` '
      '(see [CONTRIBUTING.en.md](CONTRIBUTING.en.md)).')
    A('- The repo itself (scripts and docs) is **MIT** licensed; some skills come from public '
      'marketplaces and keep their original licenses.')
    A('')
    return L


def load_map(path: str) -> dict:
    try:
        return json.load(open(path, encoding='utf-8'))
    except Exception as e:
        print(f'✗ cannot read {path}: {e}', file=sys.stderr)
        return {}


def main() -> int:
    if not os.path.isdir(SKILLS):
        print('✗ skills/ directory not found', file=sys.stderr)
        return 1

    zh = load_map(ZH_MAP)
    en = load_map(EN_MAP)

    listed = {n for _z, _e, names in CATEGORIES for n in names}
    actual = {d for d in os.listdir(SKILLS)
              if os.path.isfile(os.path.join(SKILLS, d, 'SKILL.md'))}

    # Uncategorized skills still appear in the docs, under "Other / 其他"
    others = sorted(actual - listed)
    total = len(actual)

    zh_path = os.path.join(REPO, 'README.md')
    en_path = os.path.join(REPO, 'README.en.md')
    open(zh_path, 'w', encoding='utf-8').write('\n'.join(build_zh(total, actual, zh, others)))
    open(en_path, 'w', encoding='utf-8').write('\n'.join(build_en(total, actual, en, others)))

    # Missing translations (fallback to SKILL.md original was used)
    missing_zh = sorted(n for n in actual if not (zh.get(n) or '').strip())
    missing_en = sorted(n for n in actual if not (en.get(n) or '').strip())

    print(f'✓ {zh_path}  (Chinese, from descriptions.zh.json)')
    print(f'✓ {en_path}  (English, from descriptions.en.json)')
    print(f'  skills: {total}, categories: {len(CATEGORIES)}, other: {len(others)}')
    if others:
        print(f'  ℹ in "Other / 其他": {", ".join(others)}')
    if missing_zh:
        print(f'  ⚠ missing Chinese description (needs translating): {", ".join(missing_zh)}')
    if missing_en:
        print(f'  ⚠ missing English description (needs translating): {", ".join(missing_en)}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
