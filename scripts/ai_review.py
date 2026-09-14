#!/usr/bin/env python3
"""AI 自动审核 Pull Request + 身份检查，并把结果作为评论发布到 PR。

由 .github/workflows/ai-review.yml 在 PR 上自动调用。

需要的环境变量：
  AI_API_BASE   —— OpenAI 兼容端点，如 https://api.lmuai.com
  AI_API_KEY    —— API key（存放在仓库 Secrets 中，绝不出现在代码里）
  AI_API_MODEL  —— 模型名，如 gpt-5.6-luna
  GH_TOKEN      —— GitHub token（Actions 自动提供）
  PR_NUMBER / REPO

设计原则：
  - AI 审核只给「建议」，任何 AI 故障都不阻塞 PR
  - 身份检查要求每个 commit 由 **提交者本人的 GitHub 账号** 提交；
    与 PR 作者不一致的会在评论中醒目标注（GitHub 的 PR 作者信息无法伪造）
"""
import json
import os
import subprocess
import sys
import urllib.request

API_BASE = os.environ.get("AI_API_BASE", "").rstrip("/")
API_KEY = os.environ.get("AI_API_KEY", "")
API_MODEL = os.environ.get("AI_API_MODEL", "gpt-4o")
PR_NUMBER = os.environ.get("PR_NUMBER", "")
REPO = os.environ.get("REPO", "")

MAX_DIFF = 60000

RULES = """仓库规范（逐条检查）：
1. 每个 skill 是 skills/<name>/ 目录，必须包含 SKILL.md（文件名全大写——Linux 大小写敏感）
2. SKILL.md 的 frontmatter 必须含 name 与 description，且 name 必须与目录名完全一致
3. 目录名只允许小写字母、数字、连字符（a-z0-9-）
4. 中英双语说明：descriptions.zh.json（中文）与 descriptions.en.json（英文）都必须有该 skill
5. 不得包含密钥、token、个人信息或工作敏感内容
6. README.md / README.en.md 由 scripts/gen-docs.py 自动生成，不应手改
7. 不应提交无关的大文件（依赖、构建产物、二进制）
8. 不应包含 .DS_Store、.env、.pem、.last-* 等杂项/敏感文件"""


def gh(args):
    r = subprocess.run(["gh"] + args, capture_output=True, text=True)
    if r.returncode != 0:
        print(f"gh {' '.join(args)} 失败：{r.stderr}", file=sys.stderr)
    return r.stdout


def check_identity():
    """身份检查：每个 commit 的归属账户必须与 PR 作者一致（防冒用他人身份）。

    返回 (pr_author, [不一致的说明]).
    """
    pr_author = gh(["pr", "view", PR_NUMBER, "--repo", REPO,
                    "--json", "author", "--jq", ".author.login"]).strip()
    raw = gh(["api", f"repos/{REPO}/pulls/{PR_NUMBER}/commits",
              "--jq",
              '.[] | (.author.login // "na") + "|" + .commit.author.name + "|" + .commit.author.email'])
    warns = []
    for line in raw.strip().splitlines():
        line = line.strip()
        if not line:
            continue
        parts = line.split("|")
        login = parts[0] if len(parts) > 0 else "na"
        name = parts[1] if len(parts) > 1 else ""
        email = parts[2] if len(parts) > 2 else ""
        if login in ("", "na") or (pr_author and login != pr_author):
            warns.append(f"`{name} <{email}>` → 归属账户 `{login}`，与 PR 作者 `{pr_author or '未知'}` 不一致")
    return pr_author, warns


def call_llm(prompt: str) -> str:
    url = f"{API_BASE}/v1/chat/completions"
    body = json.dumps({
        "model": API_MODEL,
        "messages": [
            {"role": "system", "content": "你是一位严格但务实的代码审查员，输出简洁、可执行。"},
            {"role": "user", "content": prompt},
        ],
        "temperature": 0.2,
    }).encode()
    req = urllib.request.Request(url, data=body, headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}",
    })
    with urllib.request.urlopen(req, timeout=180) as resp:
        data = json.load(resp)
    return data["choices"][0]["message"]["content"]


def main() -> int:
    if not (API_BASE and API_KEY and PR_NUMBER and REPO):
        print("缺少配置（AI_API_BASE / AI_API_KEY / PR_NUMBER / REPO），跳过 AI 审核。")
        return 0

    print("→ 身份检查（commit 归属 vs PR 作者）…")
    pr_author, identity_warns = check_identity()
    if identity_warns:
        print("⚠️ 身份检查发现问题：")
        for w in identity_warns:
            print(f"   {w}")
    else:
        print(f"✓ 全部提交均归属 PR 作者 {pr_author}")

    print(f"→ 获取 PR #{PR_NUMBER} 的改动…")
    diff = gh(["pr", "diff", PR_NUMBER, "--repo", REPO])
    if not diff.strip():
        print("diff 为空，跳过。")
        return 0
    if len(diff) > MAX_DIFF:
        diff = diff[:MAX_DIFF] + "\n\n...(diff 过长已截断)"

    prompt = f"""请审核下面这个 Pull Request 的改动。

{RULES}

请严格按以下格式输出（中文，简洁，不要客套）：

## 审核结论
PASS 或 FAIL（存在必须修复的问题就 FAIL）

## 问题清单
- [严重] 文件/位置 + 问题 + 修复建议
- [一般] …
- [建议] …

## 一句话总评
…

改动（git diff）：

{diff}
"""

    print("→ 调用 AI 审核…")
    try:
        review = call_llm(prompt)
    except Exception as e:
        print(f"AI 调用失败：{e}", file=sys.stderr)
        review = "（AI 审核调用失败，未生成评审意见）"

    if identity_warns:
        identity_block = (
            "\n\n---\n\n### ⚠️ 身份检查未通过\n\n"
            "要求：**每个提交都必须使用提交者本人的 GitHub 账号**。"
            "以下提交的归属账户与 PR 作者不一致（可能冒用了他人的身份/邮箱）：\n\n"
            + "\n".join(f"- {w}" for w in identity_warns)
        )
    else:
        identity_block = f"\n\n---\n\n### ✓ 身份检查通过\n\n全部提交归属 PR 作者 `{pr_author}`。" if pr_author else ""

    body = f"""## 🤖 AI 自动审核

{review}
{identity_block}

---
<sub>由 `scripts/ai_review.py` 自动生成，**仅供参考**；最终以维护者的人工审核与 Approve 为准。</sub>
"""
    print("→ 发布审核评论…")
    gh(["pr", "comment", PR_NUMBER, "--repo", REPO, "--body", body])
    print("✓ 审核评论已发布")
    return 0


if __name__ == "__main__":
    sys.exit(main())
