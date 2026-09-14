# Contributing & Upload Rules

English | [简体中文](CONTRIBUTING.md)

This repo collects **Claude Code skills**. Every addition or change must go through the
process below — no exceptions.

## Upload flow (mandatory)

```
① Prepare the skill following the format
      ↓
② Run validation: ./validate.sh        ← must be all green
      ↓
③ AI code review                        ← manual pass: format & security
      ↓
④ ./upload.sh --push                    ← push directly to main
   or ./upload.sh --pr                  ← open a Pull Request (bilingual title & body)
```

Both `--push` and `--pr` **run `validate.sh` internally** — if validation fails, the commit
or the PR is aborted.

## Skill format

Every skill is a directory under `skills/<name>/`:

```
skills/<name>/
├── SKILL.md          ← required
├── references/       ← optional
├── scripts/          ← optional
└── templates/        ← optional
```

### SKILL.md requirements

```markdown
---
name: <name>              # must exactly match the directory name
description: <one-line>   # required
---

# Title

Body: when to use it, how to use it, caveats.
```

### Hard requirements (checked by validate.sh)

| Item | Requirement |
|---|---|
| Directory name | lowercase letters, digits and hyphens only (`a-z0-9-`) |
| `SKILL.md` | must exist |
| frontmatter | wrapped in `---`, containing `name` and `description` |
| `name` | must match the directory name |
| Chinese description | `descriptions.zh.json` must contain a non-empty entry for the skill |
| Security | no `.env`, `.pem`, `id_rsa*`, `.last-*`; no secrets (`sk-`, `ghp_`, `gho_`, …) |
| Misc | no `.DS_Store` |

### Chinese descriptions are mandatory

All descriptions live in a single file, `descriptions.zh.json`:

```json
{
  "skill-name": "one sentence explaining what this skill does"
}
```

- Must be **Chinese**, so the README, terminal output and commit messages stay consistent
- Add an entry whenever you add a skill, otherwise validation fails
- The script tells you which entries are missing

## Excluding a skill from upload

### Option 1: just tell the AI (recommended)

> don't upload add-tool-doc

The AI writes that skill into `.skillignore`; every later upload skips it automatically.
Say "upload xxx again" to remove it from the list.

### Option 2: pick interactively when uploading

```bash
./upload.sh --pick                 # asks for the language first (中文 / English)
./upload.sh --lang en --pick       # force the English interface, no prompt
```

- You pick the interface language first, then every local skill is listed for selection
- The chosen language drives all prompts; with English the commit message is English too
- With `fzf` installed → a multi-select UI (Tab to select, Enter to confirm);
  otherwise → type numbers separated by spaces, `a` = all
- Afterwards it asks whether unselected skills should be added to `.skillignore`

### Option 3: edit `.skillignore` manually

`.skillignore` is a **local private file and is never uploaded** (it is listed in `.gitignore`;
only `.skillignore.example` lives in the repo). One skill name per line, `#` starts a comment:

```
# skills not uploaded
add-tool-doc
```

On first use (or after cloning someone else's repo), copy the template:

```bash
cp .skillignore.example .skillignore
```

> `upload.sh` also initializes it from the template automatically when missing.

> ⚠️ Deleting a skill from the repo is **not enough** — the next `upload.sh` will
> bring it back from your machine. Add it to `.skillignore` to hide it for real.

## Pull Request flow

Two ways to submit:

| Way | Command | When |
|---|---|---|
| Direct push | `./upload.sh --push` | Solo maintenance, quick sync |
| Pull Request | `./upload.sh --pr` | Collaboration, review needed |

`--pr` automatically:

1. Creates a branch `sync/<date>-<time>`
2. Commits and pushes the branch
3. Opens a PR with a **bilingual title and body** (added / updated skills listed in both languages)
4. Switches back to `main`

When opening a PR manually on GitHub, `.github/PULL_REQUEST_TEMPLATE.md`
(a bilingual checklist) is applied automatically.

## Bilingual descriptions (synced automatically, no commands needed)

Each skill's description lives in two map files, **synced automatically on upload**:

| File | Language | Used for |
|---|---|---|
| `descriptions.zh.json` | Chinese | the 用途 column of `README.md` |
| `descriptions.en.json` | English | the "What it does" column of `README.en.md` |

Rules:

- You wrote only **Chinese** → AI translates it into English and adds it to `descriptions.en.json`
- You wrote only **English** → AI translates it into Chinese and adds it to `descriptions.zh.json`
- Both missing → falls back to the `SKILL.md` original and warns that it needs filling in

`upload.sh` **detects gaps in both directions** on every upload and lists the skills that
need translating; the AI fills them in before committing, and `scripts/gen-docs.py` regenerates
both READMEs so they stay in sync.

> **You never run a command** — uploading is enough; Chinese-then-English (or the reverse)
> is completed automatically.

## External contribution flow (main is protected)

The `main` branch is **protected** — nobody (including contributors) can push to it directly:

1. **Fork** this repo and prepare the skill in your fork following the format above
2. Open a **Pull Request** against `main`
   - First-time contributors: a maintainer must click "Approve and run workflows" before CI runs
3. **CI must be green** — GitHub Actions automatically runs:
   - `scripts/gen-docs.py` doc-sync check (fails if the READMEs are out of sync)
   - all 8 checks in `validate.sh`
4. Only after the **maintainer approves** can the PR be merged

In short: **all green + my approval = the only way into main**. Both are required.

> The maintainer (repo owner) keeps direct push rights (`enforce_admins = false`) for quick day-to-day sync.
> Contributors do not need to run validation locally — it runs automatically on the PR.

## Validation

```bash
./validate.sh
```

Six groups: structure, naming, frontmatter, Chinese descriptions, security scan, misc.
Only when it prints **all checks passed** may you submit.

## Code review checklist

Before submitting, the AI verifies:

- [ ] `SKILL.md` structure is complete; frontmatter `name` matches the directory name
- [ ] `descriptions.zh.json` has an accurate Chinese description
- [ ] README (and `README.en.md`) lists are updated, including the total count
- [ ] No keys, tokens or personal information
- [ ] No unrelated large files (dependencies, build artifacts)
- [ ] `./validate.sh` is all green
- [ ] Commit message is generated by the script (Chinese descriptions + date); never hand-written

## Additional notes

- Only **Claude Code** skills are collected — not CodeBuddy ones (`upload.sh` defaults to `--from claude`)
- Commit author is `BUTFL@users.noreply.github.com` (global git config is not modified)
- The repo is private; pulling requires `gh auth login`
- If push fails with `Failure when receiving data from the peer`, use `git -c http.version=HTTP/1.1 push`
- Regenerate **both** READMEs with `python3 scripts/gen-docs.py` (runs automatically on upload)
