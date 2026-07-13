# Peer Review

**A pre-merge code reviewer that checks your diff against the ticket it's supposed to fix — not just against a style guide.**

---

## Why use it

It catches the bug PR review usually misses. A diff can be clean, well-tested, and well-styled — and still not actually fix the reported problem. Peer Review is built to catch that gap: root-cause-vs-symptom mismatches, and resolutions that drifted from what the ticket said would be done. No new vendor, no black-box scoring — every rule is a plain-English file you can read and edit.

Your team's real conventions live in one editable file. Point it at your linter config and it defers to that instead of guessing at your house style. Findings land as PR comments, a Jira comment, or both — your call, asked every time. Every finding is dismissible. It's a second pair of eyes, not a gate.

## Features

| Feature | What it does |
|---|---|
| **Four-dimension review** | Security, logic, style, and ticket-alignment — scored independently |
| **Ticket grounding** | Auto-detects the linked Jira key or GitHub Issue from your PR title, description, or branch name |
| **Root-cause checking** | Flags fixes that only address the symptom, not the stated root cause |
| **Resolution-drift detection** | Flags when the shipped fix differs from the ticket's stated approach |
| **Severity scoring** | Low / Medium / High / Critical, calibrated against inflation |
| **Flexible delivery** | PR comments, Jira comment, attached doc, or all three |
| **Local and PR modes** | Review your working branch or the live PR — same engine |
| **Project-aware style checks** | Reads your linter/formatter config before flagging style issues |
| **Large-diff triage** | Prioritizes auth, data-access, network, and secrets files first |
| **Zero autonomous action** | Never merges, approves, or changes ticket status — findings only |

## How to use it

- *"Review my changes before I push"* / *"Check this PR"* / *"Does this fix PROJ-123?"*

1. **Before opening a PR** — run locally against your working branch (findings in chat only).
2. **After opening the PR** — run again to post findings as PR/Jira comments.
3. **Fix, dismiss, or ignore** each finding — advisory, not a gate.

## Installation

Copy the `peer-review` folder into your agent's skills directory:

| Agent | Path |
|---|---|
| Claude Code | `.claude/skills/peer-review/` or `~/.claude/skills/peer-review/` |
| OpenCode | `.opencode/skills/peer-review/` or `~/.config/opencode/skills/peer-review/` |
| Cursor | `.cursor/skills/peer-review/` |
| Windsurf | `.windsurf/skills/peer-review/` |
| Codex CLI | `.agents/skills/peer-review/` or `~/.agents/skills/peer-review/` |
| Gemini CLI | `.gemini/skills/peer-review/` or `~/.gemini/skills/peer-review/` |
| GitHub Copilot | `.github/skills/peer-review/` or `~/.copilot/skills/peer-review/` |

Then restart your agent or reload its skills.

### Claude.ai / Claude Cowork

Zip the folder and upload via **Customize → Skills → +** (requires Pro/Max/Team/Enterprise).

### Setup checklist

- [ ] Jira connector configured (for Jira-grounded reviews)
- [ ] `gh` CLI installed and authenticated (`gh auth status`)
- [ ] `references/style-guidelines.md` customized to your team's conventions

## What's inside

```
peer-review/
├── README.md
├── SKILL.md
├── LICENSE
├── package.json
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── .opencode/
│   └── plugins/
│       └── peer-review.mjs
└── references/
    ├── security-checklist.md
    ├── logic-review.md
    ├── style-guidelines.md
    └── ticket-integration.md
```

## What it will never do

Merge, force-push, approve, change PR status, edit Jira issues, or silently fix issues. It flags — you decide.
