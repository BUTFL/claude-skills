# claude-skills

[English](README.en.md) | 简体中文

我的 Claude Code / Codex skills 合集（共 **12 个**），支持一键安装、更新与备份。

> 中文说明来自 `descriptions.zh.json`，英文说明来自 `descriptions.en.json`；两份 README 由 `scripts/gen-docs.py` 自动生成并保持同步。

---

## 目录

- [Skill 清单（12 个）](#skill-清单12-个)
- [一键安装](#一键安装推荐)
- [更新已有 skills](#更新已有-skills)
- [反向同步（本机 → 仓库）](#本地新增-skill-后反向同步uploadsh)
- [上传新 skill 前（强制流程）](#上传新-skill-前强制流程)
- [用 AI 一键同步](#用-ai-一键同步skill-sync)

---

## Skill 清单（12 个）

### 🎨 设计与视觉（1）

| Skill | 用途 |
|---|---|
| `frontend-design` | 前端视觉设计指导：明确审美方向、字体与布局，做出不像「模板默认」的 UI。 |

### 📄 办公文档（1）

| Skill | 用途 |
|---|---|
| `docx` | 创建、读取、编辑 Word 文档（.docx/.dotx）：目录、页码、信头、图片、修订与批注。 |

### 🔄 工作流与协作（7）

| Skill | 用途 |
|---|---|
| `brainstorming` | 任何创作开始前必用：先把需求、意图和设计聊清楚，再动手实现，避免方向做错。 |
| `writing-plans` | 拿到多步任务的需求或规格后、动代码前，先写实施计划。 |
| `executing-plans` | 手上有书面实施计划时，按计划分步执行并在检查点复盘。 |
| `test-driven-development` | 实现任何功能或修复前，先写测试定义成功标准（TDD）。 |
| `systematic-debugging` | 遇到任何 bug、测试失败或异常行为时，先系统排查根因，再提修复方案。 |
| `verification-before-completion` | 声称「完成 / 修好 / 通过」前必须实际运行验证命令并确认输出，禁止无证据下结论。 |
| `requesting-code-review` | 任务完成、功能实现或合并前，发起代码评审以确认满足需求。 |

### 🤖 Claude Code 工具（1）

| Skill | 用途 |
|---|---|
| `graphify` | 把代码库、文档、图片等转成持久知识图谱，用于快速熟悉项目结构、查文件关系与架构。 |

### 👤 个人（2）

| Skill | 用途 |
|---|---|
| `skill-sync` | 从 GitHub 拉取并安装或更新我的个人 skills 合集（claude-skills 仓库）。 |
| `skills-hub` | 全部 skills 的总索引与路由：按任务场景列出所有 skill 及用途，帮你快速定位该加载哪一个（问「用哪个 skill」先查它）。 |

---

## 一键安装（推荐）

> 本仓库是**公开**仓库，直接免 clone 一键安装：

```bash
curl -fsSL https://raw.githubusercontent.com/BUTFL/claude-skills/main/install.sh | bash -s -- --target both
```

国内网络可用 **Gitee 镜像**（与 GitHub 自动同步）：

```bash
curl -fsSL https://gitee.com/BUTFL/claude-skills/raw/main/install.sh | bash -s -- --target both
```

或先克隆再安装：

```bash
git clone https://github.com/BUTFL/claude-skills.git
cd claude-skills
./install.sh --target both
```

## 更新已有 skills

```bash
cd claude-skills
git pull
./install.sh --target both --force
```

## 本地新增 skill 后反向同步（upload.sh）

把本机 skills 收集回仓库（可选自动提交推送）：

```bash
./upload.sh --from claude          # 从 ~/.claude/skills 收集
./upload.sh --pick                 # 交互选择要上传的 skill（可先选语言）
./upload.sh --push                 # 直接推送到 main
./upload.sh --pr                   # 走 Pull Request（描述自动中英双语）
```

用 `--push` / `--pr` 时，**提交信息、终端输出、PR 描述都会列出每个新增/更新 skill 的中英双语用途**，并自动同步两份 README。

## 上传新 skill 前（强制流程）

| 步骤 | 内容 |
|---|---|
| ① 符合格式 | 目录结构、`SKILL.md` frontmatter（`name` 必须与目录名一致），详见 [CONTRIBUTING.md](CONTRIBUTING.md) |
| ② 校验全绿 | `./validate.sh` 必须输出 `✅ 全部检查通过` |
| ③ code review | 由 AI 复核结构、双语说明与安全，通过后才允许提交 |
| ④ 提交 | `./upload.sh --push` 或 `--pr`（内置校验，不通过会**拒绝提交**） |

## 用 AI 一键同步（skill-sync）

仓库内含 `skills/skill-sync`。装好后直接对 AI 说：

> 同步我的 skills / 更新 skills / 恢复 skills

它就会自动拉取本仓库并安装到位。

## 说明

| 参数 | 作用 |
|---|---|
| `--target claude` | 安装到 `~/.claude/skills`（默认） |
| `--target codex` | 安装到 `~/.codex/skills` |
| `--target codebuddy` | 安装到 `~/.codebuddy/skills` |
| `--target both` | Claude Code + Codex |
| `--target all` | 三个都装 |
| `--force` | 覆盖已存在的同名 skill（默认跳过） |

- 默认**跳过已存在**的 skill，不会误删你本地的其他 skill。
- 装完需**重启对应工具**，新 skill 才会出现在可用列表。
- 每个 skill 一个目录（含 `SKILL.md`），全部位于 `skills/` 下。
- 中英文档由 `scripts/gen-docs.py` 自动生成，`upload.sh` 提交前自动同步；未归类的 skill 自动进入「其他」分类。
- 不想上传的 skill 写进本地 `.skillignore`（详见 [CONTRIBUTING.md](CONTRIBUTING.md)）。
- 本仓库自身（脚本与文档）以 **MIT** 许可发布；部分 skill 来自公开市场，遵循各自原许可证。
