---
name: skill-sync
description: 从 GitHub 拉取并安装/更新我的个人 skills 合集（claude-skills 仓库）。当用户说“同步 skills”“安装我的 skills”“更新 skills”“恢复 skills”“一键装回 skills”时使用。
---

# Skill Sync

把 `BUTFL/claude-skills`（公开仓库）里的 skills 安装或更新到本地（支持 Claude Code / Codex / CodeBuddy）。

## 使用流程

1. **确定安装目标**
   - 用户在 Claude Code 里 → `claude`（装到 `~/.claude/skills`）
   - 用户在 Codex 里 → `codex`（装到 `~/.codex/skills`）
   - 用户在 CodeBuddy 里 → `codebuddy`（装到 `~/.codebuddy/skills`）
   - 用户说 Claude + Codex 都要 → `both`
   - 三个都要 / 不确定 → `all`

2. **执行安装**

   仓库是公开的，免 clone 一键安装：

   ```bash
   curl -fsSL https://raw.githubusercontent.com/BUTFL/claude-skills/main/install.sh | bash -s -- --target <claude|codex|codebuddy|both|all>
   ```

   更新已存在的 skill（覆盖旧版本）时追加 `--force`：

   ```bash
   curl -fsSL https://raw.githubusercontent.com/BUTFL/claude-skills/main/install.sh | bash -s -- --target <...> --force
   ```

   网络受限时可先克隆再安装：

   ```bash
   git clone --depth 1 https://github.com/BUTFL/claude-skills.git /tmp/claude-skills \
     && /tmp/claude-skills/install.sh --target <...> [--force]
   ```

3. **报告结果**：装了几个、跳过几个（跳过 = 本地已存在）。

4. **提醒用户**：重启对应工具后，新 skill 才会出现在可用列表里。

## 注意事项

- 默认**跳过已存在**的 skill，不会删除用户本地其他 skill；只有加 `--force` 才覆盖。
- 安装前目标目录不存在会自动创建（`mkdir -p`）。
- 不要把用户本地的其他 skill 目录清空——本 skill 只负责从仓库复制。
