# Peer Review

**A pre-merge code reviewer that checks your diff against the ticket it's supposed to fix — not just against a style guide.**

Every automated PR reviewer can tell you a variable is unused or a query looks unparameterized. Almost none of them know *why* the code changed in the first place. Peer Review reads the linked Jira ticket or GitHub Issue, pulls the actual reported root cause, and checks whether your diff addresses that — or just papered over the symptom. Then it hands you a severity-tagged list of findings you can dismiss or act on. It never blocks, merges, or approves anything on its own — you stay the decision-maker, it just makes sure you're deciding with full information.

---

## Why use it

**It catches the bug PR review usually misses.** A diff can be clean, well-tested, and well-styled — and still not actually fix the reported problem. Peer Review is built specifically to catch that gap: root-cause-vs-symptom mismatches, and resolutions that quietly drifted from what the ticket said would be done.

**It's not another SaaS reviewer bolted onto your pipeline.** No new vendor, no new place your code gets sent, no black-box scoring you have to reverse-engineer. It runs inside the Claude session you're already using, and every rule it follows is a plain-English file you can read and edit yourself.

**It's actually yours to tune.** Your team's real coding conventions — not a generic best-practices list — live in one editable file. Point it at your linter config and it'll defer to that instead of guessing at your house style.

**It leaves a trail, not just a chat message.** Findings can land as PR comments, a Jira comment, or a full review doc attached to the ticket — your call, asked every time. That's the difference between "an AI said something once" and "there's a dated record of what was flagged and why."

**It respects that you're the one who ships.** Every finding is dismissible. Nothing here holds a merge hostage. It's a second pair of eyes, not a gate — you make the call, it makes sure you're making it with the full picture.

---

## Features

| Feature | What it does |
|---|---|
| **Four-dimension review** | Security, logic, style, and ticket-alignment — scored independently so one nitpick can't drown out a real vulnerability |
| **Ticket grounding** | Auto-detects the linked Jira key or GitHub Issue from your PR title, description, or branch name — asks you if it can't find one |
| **Root-cause checking** | Compares your diff against the ticket's stated root cause, not just its title — flags fixes that only address the symptom |
| **Resolution-drift detection** | Flags when the shipped fix meaningfully differs from the ticket's stated fix approach |
| **Severity scoring** | Low / Medium / High / Critical, calibrated to avoid inflation — uncertain findings default to lower severity, not louder alarms |
| **Flexible delivery** | PR comments, Jira comment, Jira comment + attached review doc, or all three — you choose per run |
| **Local and PR modes** | Review your working branch before you even push, or review the live PR after — same engine, different diff source |
| **Project-aware style checks** | Reads your actual linter/formatter config before flagging style issues; falls back to generic conventions only when nothing exists, capped at Low severity |
| **Large-diff triage** | Prioritizes auth, data-access, network, and secrets files first on big diffs instead of reviewing everything with equal, shallow attention |
| **Zero autonomous action** | Never merges, force-pushes, changes branch protection, approves/requests-changes, or touches ticket status — findings only |

---

## How to use it

You don't invoke this with a command — just describe what you want in plain language, and it triggers automatically:

- *"Review my changes before I push"*
- *"Check this PR"*
- *"Does this fix PROJ-123?"*
- *"Can I merge this?"*
- *"Review my branch against JIRA-456"*

**Recommended workflow:**

1. **Before opening a PR** — run it locally against your working branch (*"review my changes"*). This is your private gut-check; findings show up in chat only.
2. **After opening the PR** — run it again (*"review this PR"*). Now it can post findings as PR comments and/or a Jira comment, since there's something to attach them to.
3. **Fix, dismiss, or ignore** each finding at your discretion — it's advisory, not a gate.

**Tip:** name the ticket explicitly when you ask ("review this against PROJ-456") to guarantee the skill triggers and skip auto-detection entirely.

**Not for:** running on every keystroke or tiny commit — pair it with a real linter/formatter for that. This is a pre-merge gut-check, not a save-time hook.

---

## Installation

Skills use a portable format (a folder with `SKILL.md` at its root), but *how* you install one differs by surface. Pick the one that matches where you work.

### Claude Code

Filesystem-based — no upload step, just drop the folder in place.

**Personal (available in every project on your machine):**
```bash
mkdir -p ~/.claude/skills
cp -r peer-review ~/.claude/skills/peer-review
```

**Project-scoped (committed to the repo, shared with your whole team):**
```bash
mkdir -p .claude/skills
cp -r peer-review .claude/skills/peer-review
```
Commit `.claude/skills/peer-review/` to git so teammates get it automatically when they pull.

**Verify it's picked up:**
```bash
claude skills list
```
or just ask Claude "what skills do you have available?" If it doesn't show up, restart Claude Code — new skills are picked up at session start.

### Claude.ai (Chat) and Claude Cowork

These share one personal skill library, so installing here makes it available in both.

1. Zip the skill folder (must contain `SKILL.md` at the top level, e.g. `references/` alongside it — not nested one level deeper):
   ```bash
   cd peer-review && zip -r ../peer-review.zip . && cd ..
   ```
2. In Claude, open **Customize** in the left sidebar → **Skills** tab → click the **+** button → upload the zip.
3. Requires Pro, Max, Team, or Enterprise with **Code execution and file creation** enabled (Settings → Capabilities, or Organization settings on Team/Enterprise).
4. The skill is enabled by default after upload — toggle it off in Customize > Skills if you ever want to disable it without deleting it.

**Team/Enterprise organization-wide rollout:** an org owner can upload it once under **Organization settings > Skills** to provision it for everyone, instead of each person uploading their own copy.

### Claude for Excel / PowerPoint / Word / Outlook

No separate install — any skill enabled in your Claude Chat/Cowork settings (via the step above) is automatically available in these add-ins too.

### Other major agents

`peer-review` uses only the two universal frontmatter fields (`name`, `description`) — no Claude-specific extensions — so it's portable to every agent that implements the open Agent Skills standard. Same folder, just copied to a different path.

| Agent | Personal/global path | Project path | Notes |
|---|---|---|---|
| **Cursor** | *(none — project-scoped only)* | `.cursor/skills/peer-review/` | Reload window (`Cmd/Ctrl+Shift+P` → "Developer: Reload Window") to pick it up |
| **Windsurf (Cascade)** | *(none — project-scoped only)* | `.windsurf/skills/peer-review/` | Reads `.claude/skills/` too if Claude Code config reading is enabled |
| **OpenCode** | `~/.config/opencode/skills/peer-review/` | `.opencode/skills/peer-review/` | Also auto-reads `.claude/skills/` and `.agents/skills/` — no copy needed if either already exists |
| **Codex CLI** (OpenAI) | `~/.agents/skills/peer-review/` or `~/.codex/skills/peer-review/` | `.agents/skills/peer-review/` (scans up to repo root) | Restart Codex, or it should auto-detect |
| **Gemini CLI** | `~/.gemini/skills/peer-review/` | `.gemini/skills/peer-review/` | `.agents/skills/` alias also works; run `/skills reload` to pick it up without restarting |
| **GitHub Copilot** (VS Code, CLI, cloud agent) | `~/.copilot/skills/peer-review/` | `.github/skills/peer-review/` | Also reads `.claude/skills/` automatically. For Copilot code review specifically, keeping "review" in the directory name (as here) helps it auto-apply during PR reviews |

**Generic steps for any of the above:**
```bash
mkdir -p <target-skills-path>
cp -r peer-review <target-skills-path>/peer-review
```
Then restart the agent, or use its reload command (`/skills reload`, `/reload-plugins`, "Reload Window," etc. — varies by tool, see the Notes column).

**Cross-agent tip:** several of these tools (OpenCode, Codex CLI, Gemini CLI, GitHub Copilot) natively fall back to reading `.claude/skills/` or `.agents/skills/` if present. If you're using more than one of these agents on the same repo, committing the skill to `.claude/skills/peer-review/` or `.agents/skills/peer-review/` once may cover several tools simultaneously — check the Notes column above before duplicating it into every agent-specific folder.

### Setup checklist (all surfaces)

- [ ] **Jira connector** — connect it if you want ticket-grounded reviews for Jira tickets. GitHub Issues need no extra connector; the skill uses the `gh` CLI directly.
- [ ] **`gh` CLI** — installed and authenticated (`gh auth status`), required for PR-mode reviews and posting PR comments.
- [ ] **`references/style-guidelines.md`** — swap in your team's actual conventions once you've run it a few times and know what keeps coming up. Skills installed from a shared directory are view-only; if you installed via the directory rather than uploading your own copy, download it, edit, and re-upload as your own to customize this file.

---

## What's inside

```
peer-review/
├── README.md                       — this file
├── SKILL.md                        — orchestration logic (the skill itself)
└── references/
    ├── security-checklist.md       — pattern-based security review rules
    ├── logic-review.md             — context-gathering approach for logic bugs
    ├── style-guidelines.md         — project style rules (customize this one)
    └── ticket-integration.md       — Jira/GitHub Issues field mapping & fetch logic
```

---

## What it will never do

- Merge, force-push, or change branch protection
- Approve or request-changes on a PR
- Change a Jira ticket's status, priority, or assignee
- Silently fix issues it finds — it flags, you decide
- Treat its own findings as final if you push back with new context
