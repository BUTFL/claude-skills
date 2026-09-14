# claude-skills

[English](README.en.md) | 简体中文

我的 Claude Code skills 合集（共 **57 个**），支持一键安装、更新与备份。

> 中文说明来自 `descriptions.zh.json`，英文说明来自 `descriptions.en.json`；两份 README 由 `scripts/gen-docs.py` 自动生成并保持同步。

---

## 目录

- [Skill 清单（57 个）](#skill-清单57-个)
- [一键安装](#一键安装推荐)
- [更新已有 skills](#更新已有-skills)
- [反向同步（本机 → 仓库）](#本地新增-skill-后反向同步uploadsh)
- [上传新 skill 前（强制流程）](#上传新-skill-前强制流程)
- [用 AI 一键同步](#用-ai-一键同步skill-sync)

---

## Skill 清单（57 个）

### 🎨 设计与视觉（7）

| Skill | 用途 |
|---|---|
| `algorithmic-art` | 用 p5.js + 种子随机做生成艺术（流场、粒子、噪声），输出可交互的 HTML 作品。 |
| `canvas-design` | 用设计方法论创作 .png / .pdf 视觉作品：海报、艺术图、静态设计稿。 |
| `frontend-design` | 前端视觉设计指导：明确审美方向、字体与布局，做出不像「模板默认」的 UI。 |
| `brand-guidelines` | 在产物中套用 Anthropic 官方品牌色与字体规范。 |
| `theme-factory` | 给产物套统一主题样式：幻灯片、文档、报告、落地页等。 |
| `web-artifacts-builder` | 用现代前端技术栈构建复杂的多组件 claude.ai HTML artifact。 |
| `slack-gif-creator` | 制作适配 Slack 的动图 GIF：尺寸约束、校验工具与优化建议。 |

### 📄 办公文档（7）

| Skill | 用途 |
|---|---|
| `docx` | 创建、读取、编辑 Word 文档（.docx/.dotx）：目录、页码、信头、图片、修订与批注。 |
| `pdf` | 创建、读取与处理 PDF：抽取文本、合并拆分、表单填写、加解密。 |
| `pptx` | 创建与编辑 PowerPoint 演示文稿：母版、占位符、图表、备注与版式。 |
| `xlsx` | 以表格文件为主要输入或输出的任务：创建、读取、编辑 Excel 与数据校验。 |
| `receipts` | 把操作过程与产出整理成可核验的凭据与记录。 |
| `internal-comms` | 撰写内部沟通文案：周报、公告、FAQ、状态更新等对内文档。 |
| `doc-coauthoring` | 结构化文档共创流程：高效传递上下文、迭代打磨、验证读者可用性。 |

### 🛠 开发工程 / MCP（16）

| Skill | 用途 |
|---|---|
| `claude-api` | Claude API / Anthropic SDK 权威参考：模型 ID、价格、参数、流式、工具调用、MCP、缓存与迁移。 |
| `mcp-builder` | 构建高质量 MCP 服务器：工具设计、资源与提示词、认证与部署。 |
| `build-mcp-server` | 构建 MCP 服务器的入口技能：确定部署形态（远程 HTTP / MCPB / 本地 stdio）与工具设计模式。 |
| `build-mcp-app` | 构建带交互 UI（表单、选择器、看板）的 MCP 应用，在对话里直接渲染组件。 |
| `build-mcpb` | 把本地 MCP 服务器打包成 .mcpb 分发，用户无需预装 Node/Python。 |
| `mcp-integration` | 把 MCP 服务器接入插件与工作流：配置、认证与调用方式。 |
| `agent-development` | 创建与编写子代理（subagent）：frontmatter、系统提示词、触发条件与最佳实践。 |
| `command-development` | 编写斜杠命令（slash command）：frontmatter、参数、文件引用、交互模式与最佳实践。 |
| `hook-development` | 开发 hookify 规则：定义 hook 的触发条件与行为，约束 AI 的自动化动作。 |
| `plugin-settings` | 插件设置机制：声明与读取用户配置项。 |
| `plugin-structure` | 插件目录与清单结构：plugin.json、skills、commands、hooks 的组织方式。 |
| `skill-development` | 开发 skill 的规范：写 SKILL.md、加进插件、校验与迭代。 |
| `skill-creator` | 创建新 skill、改进现有 skill、度量 skill 表现（含评测流程）。 |
| `writing-skills` | 创建或编辑 skill，并在部署前验证其有效性。 |
| `webapp-testing` | 用 Playwright 测试本地 Web 应用：验证前端行为、填表单、截图与调试。 |
| `math-olympiad` | 数学奥赛题解题：严谨推理、分步证明与答案验证。 |

### 🔄 工作流与协作（13）

| Skill | 用途 |
|---|---|
| `brainstorming` | 任何创作开始前必用：先把需求、意图和设计聊清楚，再动手实现，避免方向做错。 |
| `writing-plans` | 拿到多步任务的需求或规格后、动代码前，先写实施计划。 |
| `executing-plans` | 手上有书面实施计划时，按计划分步执行并在检查点复盘。 |
| `test-driven-development` | 实现任何功能或修复前，先写测试定义成功标准（TDD）。 |
| `systematic-debugging` | 遇到任何 bug、测试失败或异常行为时，先系统排查根因，再提修复方案。 |
| `verification-before-completion` | 声称「完成 / 修好 / 通过」前必须实际运行验证命令并确认输出，禁止无证据下结论。 |
| `subagent-driven-development` | 在当前会话里用子代理执行实施计划中的独立任务。 |
| `dispatching-parallel-agents` | 面对 2 个以上互不依赖的任务时，并行派发给多个子代理同时处理。 |
| `requesting-code-review` | 任务完成、功能实现或合并前，发起代码评审以确认满足需求。 |
| `receiving-code-review` | 收到代码评审意见后的处理：先验证再采纳，保持技术严谨而非表面顺从。 |
| `using-git-worktrees` | 需要与当前工作区隔离、或执行实施计划前，用 git worktree 建独立工作区。 |
| `finishing-a-development-branch` | 开发分支收尾：实现完成、测试通过后，决定如何合并与集成。 |
| `using-superpowers` | 每次对话起始时建立「先查可用 skill 再回答」的工作方式。 |

### 🤖 Claude Code 工具（13）

| Skill | 用途 |
|---|---|
| `graphify` | 把代码库、文档、图片等转成持久知识图谱，用于快速熟悉项目结构、查文件关系与架构。 |
| `claude-automation-recommender` | 分析代码库并推荐 Claude Code 自动化方案（hooks、子代理、skills、插件、MCP）。 |
| `claude-md-improver` | 审计并改进仓库里的 CLAUDE.md：质量检查、模板对照、定向修订。 |
| `claude-security` | 代码安全菜单：扫描全库或指定范围，审计依赖、配置与潜在安全问题。 |
| `writing-rules` | 编写 hookify 规则文件：语法、触发条件与调试方法。 |
| `session-report` | 生成 Claude Code 会话用量报告（token、缓存、子代理、skills、高花费环节）的 HTML。 |
| `project-artifact` | 为项目生成可交付的 artifact 文档（方案、报告、总结）。 |
| `playground` | 在内置演练场里快速试验想法并可视化结果。 |
| `discernment-nudge` | 在给出可执行的建议或结论后，追加 2-3 个追问，帮你核查事实、假设与遗漏。 |
| `academy-guide` | 回答「如何使用 Claude / Claude 产品」类问题时，推荐 Claude Academy 里匹配的课程与教程。 |
| `karpathy-guidelines` | Karpathy 式编码准则：先思考再写、最简实现、外科手术式改动、可验证的成功标准。 |
| `example-command` | 示例斜杠命令，演示 frontmatter 选项与 skills 目录布局。 |
| `example-skill` | 示例 skill，演示 skill 开发模式与标准模板结构。 |

### 👤 个人（1）

| Skill | 用途 |
|---|---|
| `skill-sync` | 从 GitHub 拉取并安装或更新我的个人 skills 合集（claude-skills 仓库）。 |

---

## 一键安装（推荐）

> 本仓库是**公开**仓库，直接免 clone 一键安装：

```bash
curl -fsSL https://raw.githubusercontent.com/BUTFL/claude-skills/main/install.sh | bash -s -- --target both
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
| `--target codebuddy` | 安装到 `~/.codebuddy/skills` |
| `--target both` | 两边都装 |
| `--force` | 覆盖已存在的同名 skill（默认跳过） |

- 默认**跳过已存在**的 skill，不会误删你本地的其他 skill。
- 装完需**重启对应工具**，新 skill 才会出现在可用列表。
- 每个 skill 一个目录（含 `SKILL.md`），全部位于 `skills/` 下。
- 中英文档由 `scripts/gen-docs.py` 自动生成，`upload.sh` 提交前自动同步；未归类的 skill 自动进入「其他」分类。
- 不想上传的 skill 写进本地 `.skillignore`（详见 [CONTRIBUTING.md](CONTRIBUTING.md)）。
