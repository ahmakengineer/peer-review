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

## Setup

1. Place the `peer-review/` folder wherever your environment loads skills from.
2. Connect the **Jira** MCP connector if you want ticket-grounded reviews on Jira tickets (GitHub Issues work via the `gh` CLI, no extra connector needed).
3. Open `references/style-guidelines.md` and swap in your team's actual conventions once you've run it a few times and know what keeps coming up.
4. Make sure `gh` (GitHub CLI) is installed and authenticated for PR-mode reviews.

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
