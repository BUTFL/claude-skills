---
name: skills-hub
description: "全部 skills 的总索引与路由（master index & router for all local skills）。当用户问「有哪些 skill」「能做什么」「该用哪个 skill」、任务跨领域需要选型、或不确定从哪开始时使用。Triggers: 有什么skill / 用哪个skill / skill 列表 / which skill / list skills / what can you do."
---

# Skills Hub · 总索引

> ⚙️ 本文件由 `scripts/gen-docs.py` 自动生成（上传时自动刷新），请勿手工编辑。

**共 8 个 skill。** 找到目标后，用 `use_skill("<名称>")` 加载对应 skill。

## 一、常见任务速查

| 我想…… | 用这些 skill |
|---|---|
| 快速看懂一个项目 / 代码库结构 | `graphify` |
| 规划一个开发任务 | `brainstorming`（先对齐需求）→ `writing-plans`（出实施计划） |
| 排查疑难 bug / 异常 | `systematic-debugging` |
| 做前端界面 / 视觉设计 | `frontend-design` |
| 写 Word 文档 | `docx` |
| 同步 / 备份 / 装回 skills | `skill-sync` |
| 不确定该用哪个 | 就是本 skill —— 看下面的「分类表」列出的全部可用项 |

## 二、按分类浏览

### 🎨 设计与视觉

| Skill | 什么时候用 |
|---|---|
| `frontend-design` | 前端视觉设计指导：明确审美方向、字体与布局，做出不像「模板默认」的 UI。 |

### 📄 办公文档

| Skill | 什么时候用 |
|---|---|
| `docx` | 创建、读取、编辑 Word 文档（.docx/.dotx）：目录、页码、信头、图片、修订与批注。 |

### 🔄 工作流与协作

| Skill | 什么时候用 |
|---|---|
| `brainstorming` | 任何创作开始前必用：先把需求、意图和设计聊清楚，再动手实现，避免方向做错。 |
| `writing-plans` | 拿到多步任务的需求或规格后、动代码前，先写实施计划。 |
| `systematic-debugging` | 遇到任何 bug、测试失败或异常行为时，先系统排查根因，再提修复方案。 |

### 🤖 Claude Code 工具

| Skill | 什么时候用 |
|---|---|
| `graphify` | 把代码库、文档、图片等转成持久知识图谱，用于快速熟悉项目结构、查文件关系与架构。 |

### 👤 个人

| Skill | 什么时候用 |
|---|---|
| `skill-sync` | 从 GitHub 拉取并安装或更新我的个人 skills 合集（claude-skills 仓库）。 |
| `skills-hub` | 全部 skills 的总索引与路由：按任务场景列出所有 skill 及用途，帮你快速定位该加载哪一个（问「用哪个 skill」先查它）。 |

## 三、使用建议

1. 先查「速查表」，没有匹配再翻「分类表」；
2. 找到后用 `use_skill("<名称>")` 加载对应 skill（推荐：原生触发、含脚本/模板等附属资源）；
3. **只装本 skill 也能用**：同目录的 `ALL_SKILLS.md` 是全量合订本，包含所有 skill 的完整指令，按章节检索阅读即可（脚本/模板等附属资源仍需安装对应 skill）；
4. 复杂任务可组合多个 skill（例如：`brainstorming` 对齐需求 → `writing-plans` 出计划 → `test-driven-development` 实现 → `verification-before-completion` 验收）。
