# 贡献与上传规范

[English](CONTRIBUTING.en.md) | 简体中文

本仓库收录的是 **Claude Code 的 skills**。为了保证一致性与安全，任何新增或修改都必须走完下面的流程，缺一不可。

## 上传流程（强制）

```
① 按格式准备 skill
      ↓
② 跑校验：./validate.sh        ← 必须全绿
      ↓
③ AI code review               ← 我人工过一遍，确认规范与安全
      ↓
④ ./upload.sh --push           ← 直接推送到 main
   或 ./upload.sh --pr          ← 走 Pull Request（标题与描述自动中英双语）
```

`upload.sh --push` / `--pr` **都内置了 `validate.sh`**，校验不通过会直接中止，不会提交也不会建 PR。

## Skill 格式规范

每个 skill 是 `skills/<name>/` 下的一个目录：

```
skills/<name>/
├── SKILL.md          ← 必需
├── references/       ← 可选：参考资料
├── scripts/          ← 可选：脚本
└── templates/        ← 可选：模板
```

### SKILL.md 要求

```markdown
---
name: <name>              # 必须与目录名完全一致
description: <一句话用途>   # 必填
---

# 标题

正文：什么时候用、怎么用、注意事项。
```

### 硬性要求（validate.sh 会逐项检查）

| 项 | 要求 |
|---|---|
| 目录名 | 只允许小写字母、数字、连字符（`a-z0-9-`） |
| `SKILL.md` | 必须存在 |
| frontmatter | 必须用 `---` 包裹，且包含 `name` 与 `description` |
| `name` | 必须与目录名一致 |
| 中文说明 | `descriptions.zh.json` 必须有该 skill 的中文用途说明（非空） |
| 安全 | 不得包含 `.env`、`.pem`、`id_rsa*`、`.last-*`；不得含疑似密钥（`sk-`/`ghp_`/`gho_` 等） |
| 杂项 | 不得有 `.DS_Store` |

### 中文说明是强制项

所有 skill 的说明统一维护在 `descriptions.zh.json`：

```json
{
  "skill-name": "一句话说明这个 skill 是干什么的"
}
```

- **必须中文**，保证 README、终端输出、提交信息全部是中文
- 新增 skill 时同步加一条，否则校验不通过
- 缺失时脚本会提示补充

## 不想上传某个 skill

### 方式一：直接告诉 AI（推荐）

> 不用上传 add-tool-doc

我会把该 skill 写进 `.skillignore`，之后每次上传都自动跳过，你不用再记。
同样地，说「恢复上传 xxx」就能把它从名单里移除。

### 方式二：上传时交互选择

```bash
./upload.sh --pick                 # 会先让你选语言（中文 / English）
./upload.sh --lang en --pick       # 直接指定英文界面，不再询问
```

- 先选界面语言（照顾国外用户），再列出本机全部 skill 供你勾选
- 界面语言决定所有提示文案；选 English 时提交信息也用英文
- 装了 `fzf` → 直接是多选界面（Tab 选择、回车确认）；没装 → 输入编号，空格分隔，`a` = 全部
- 选完后会问：未选中的要不要一并加入 `.skillignore`，加了以后就自动跳过

### 方式三：手动编辑 `.skillignore`

`.skillignore` 是**本地私有文件，不会上传到仓库**（已在 `.gitignore` 中，仓库里只保留 `.skillignore.example` 模板）。
每行一个 skill 名，`#` 开头为注释：

```
# 不上传的 skill
add-tool-doc
```

首次使用（或克隆别人的仓库后），从示例复制一份即可：

```bash
cp .skillignore.example .skillignore
```

> `upload.sh` 检测到本地没有 `.skillignore` 时，也会自动从模板初始化。

> ⚠️ 注意：只在仓库里删掉某个 skill 是**没用的** —— 下次 `upload.sh` 还会从本机把它收回来。
> 必须写进 `.skillignore`（或用上面两种方式）才会真正隐藏。

## Pull Request 流程

两种提交方式：

| 方式 | 命令 | 适用 |
|---|---|---|
| 直接推送 | `./upload.sh --push` | 自己维护、快速同步 |
| Pull Request | `./upload.sh --pr` | 多人协作、需要 review |

`--pr` 会自动完成：

1. 新建分支 `sync/日期-时间`
2. 提交并推送该分支
3. 创建 PR，**标题与描述自动中英双语**（分别列出新增 / 更新的 skill 及用途）
4. 切回 `main`

在 GitHub 网页手动开 PR 时，会自动套用 `.github/PULL_REQUEST_TEMPLATE.md`（中英双语检查清单）。

## 提交信息写清「改了什么、为什么」（--note）

提交信息除了自动列出 skill 变更与文件清单，还支持补充**变更原因**：

```bash
./upload.sh --push \
  --note "提交信息补齐「其他改动」清单：原先只列 skill 变更，改脚本时提交信息为空" \
  --note "规避 macOS bash 3.2 在 \$( ) 内解析 case 的语法坑"
```

- `--note` 可重复传入，会写进**提交信息**和 **PR 描述**（中英双语位置都有）
- 说明由 **AI 在提交时代为撰写** —— 它能读懂改动意图，你不需要手写
- 不传 `--note` 时行为不变（仍会列出 skill 与文件清单）

> 为什么需要人工/AI 说明：脚本能自动列出"改了哪些文件"，但**"为什么改"只有人（或 AI）知道**。

## 双语说明（自动同步，无需打命令）

每个 skill 的说明维护在两份映射文件中，**上传时自动同步**：

| 文件 | 语言 | 用于 |
|---|---|---|
| `descriptions.zh.json` | 中文 | `README.md` 的「用途」列 |
| `descriptions.en.json` | 英文 | `README.en.md` 的 What it does 列 |

规则：

- 你只写了**中文** → 英文由 AI 自动翻译，补进 `descriptions.en.json`
- 你只写了**英文** → 中文由 AI 自动翻译，补进 `descriptions.zh.json`
- 两边都缺 → 先回退 `SKILL.md` 原文，同时提示需要补齐

`upload.sh` 上传时会**自动检测双向缺口**并列出待翻译的 skill，AI 补齐后再提交；两份 README 由 `scripts/gen-docs.py` 重新生成，始终保持一致。

> **你不需要运行任何命令** —— 上传即同步，中文在前、英文在后（或反之）都会自动补全。

## 外部贡献流程（main 受保护，不能直推）

`main` 分支已开启**分支保护**，任何人（包括贡献者）都**不能直接推送**：

1. **Fork** 本仓库，在 fork 里按上面的格式与规范准备好 skill
2. 向 `main` **开 Pull Request**
   - 首次贡献者需要维护者点一次「Approve and run workflows」，CI 才会跑
3. **CI 必须全绿** —— GitHub Actions 会自动执行：
   - `scripts/gen-docs.py` 文档同步检查（README 没同步就红）
   - `validate.sh` 全部 8 项校验
4. **维护者 Approve** 后，PR 才能合并

也就是说：**全绿 + 我同意 = 才能进主分支**，缺一不可。

> 维护者（仓库所有者）保留直接推送权限（`enforce_admins = false`），用于日常快速同步。
> 贡献者不需要在本地手动跑校验 —— PR 上会自动跑，红了按提示修即可。

## 校验命令

```bash
./validate.sh
```

检查 6 大类：目录结构、命名规范、frontmatter、中文说明、安全扫描、杂项。
输出全绿（`✅ 全部检查通过`）才允许提交。

## Code Review 清单

提交前我会逐条核对：

- [ ] `SKILL.md` 结构完整，frontmatter 的 `name` 与目录名一致
- [ ] `descriptions.zh.json` 有对应的中文说明，表述准确
- [ ] README 清单已同步（新增 skill 要加进对应分类，更新总数）
- [ ] 没有密钥、token、个人信息等敏感内容
- [ ] 没有无关的大文件（如依赖、构建产物）
- [ ] `./validate.sh` 全绿
- [ ] 提交信息由脚本自动生成（含中文用途与日期），无需手写

## 补充说明

- 只收录 **Claude Code 的 skill**，不收录 CodeBuddy 的（`upload.sh` 默认 `--from claude`）
- 提交作者统一用 `BUTFL@users.noreply.github.com`（不改动全局 git 配置）
- 仓库为私有，拉取需 `gh auth login`
- 遇到 push 报 `Failure when receiving data from the peer`，用 `git -c http.version=HTTP/1.1 push`
