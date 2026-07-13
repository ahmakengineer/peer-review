---
name: peer-review
description: Review git changes for security issues, logic bugs, and coding-guideline violations before a merge — grounded against the linked Jira ticket or GitHub Issue so findings check whether the diff actually addresses the reported root cause, not just whether the code looks clean. Use whenever the user asks to "review my changes," "check this PR," "review this diff," "is this safe to merge," or "does this fix the ticket" — even without those exact words (e.g. "can I merge this", "check my branch against JIRA-123"). Produces severity-tagged findings (Low/Medium/High/Critical) as dismissible comments on the PR, the ticket, or both — never blocks or takes merge/ticket-status action itself.
---

# Peer Review

You're acting as a second pair of eyes before code ships — not a gatekeeper. Your output is a set of findings the human triages themselves. You never merge, block, approve, reject, or change ticket status. You report; they decide.

## Step 0: Resolve the linked ticket

Before reviewing code, find out what this diff is supposed to fix — a review that only checks code quality but never checks it against the reported root cause misses the thing corporate reviewers actually care about.

**Ticket ID detection, in this order — stop at first match:**
1. **PR title** — look for a Jira-style key (`[A-Z]+-\d+`, e.g. `PROJ-123`) or a GitHub issue reference (`#123`).
2. **PR description** — same patterns; GitHub also auto-links `Fixes #123` / `Closes #123` style phrases, which double as strong signals.
3. **Branch name** — same patterns (e.g. `feature/PROJ-123-fix-race-condition`).
4. **If none found** — ask the user directly via `ask_user_input_v0` whether there's a ticket to link (give an explicit "no ticket / skip ticket-grounded checks" option). Don't guess or silently skip this — a missing ticket is itself a data point.

**Fetch the ticket:**
- Jira key format (`ABC-123`) → use the Jira MCP connector if available. If not connected, check via `search_mcp_registry` / `suggest_connectors` rather than failing silently — ticket grounding is the point of this skill, worth a beat to connect.
- GitHub issue (`#123` or bare number with no letter prefix) → `gh issue view <number> --json title,body,state,labels`.
- Pull whatever fields exist for: **description/summary**, **root cause**, **resolution / fix approach**, **acceptance criteria**. Not all tickets have all of these — use what's there, note what's missing rather than inventing it.
- See `references/ticket-integration.md` for field-name variants and fetch specifics per system.

If the ticket can't be fetched (permissions, not found, connector unavailable), say so plainly and proceed with a code-only review — don't block the whole review over a missing ticket.

## Step 1: Detect mode and diff scope

**Mode** — check what's available:
- If `gh` CLI is authenticated and the current branch has an open PR (`gh pr view` succeeds), or the user names a specific PR/number → **GitHub mode**.
- Otherwise → **Local mode**.

**Diff scope** (auto-detected, don't ask unless ambiguous):
- **GitHub mode**: `gh pr diff <number>` for the exact PR diff; base branch via `gh pr view --json baseRefName`.
- **Local mode**: diff current branch against the repo's default branch:
  ```
  git symbolic-ref refs/remotes/origin/HEAD --short 2>/dev/null | sed 's@^origin/@@'
  ```
  Fall back to `main`, then `master`. Then `git diff <default-branch>...HEAD`.
- No diff found → say so and stop, don't invent findings.

For large diffs (roughly >800 changed lines), triage: files touching auth, data access, network calls, secrets/config, and payment/PII first; batch remaining low-risk files (pure tests, generated code, lockfiles) with a lighter pass.

## Step 2: Run the four sub-reviews

Independent passes — don't let a style nit and a SQL injection collapse into one verdict.

1. **Security** — `references/security-checklist.md`. Only flag patterns actually present in the diff.
2. **Logic** — `references/logic-review.md`. Needs context beyond the diff: callers of changed functions, existing test coverage, stated intent.
3. **Style/guidelines** — `references/style-guidelines.md`. Project's own linter config first; generic fallback capped at Low.
4. **Ticket alignment** (only if a ticket was resolved in Step 0) — `references/ticket-integration.md`. Specifically checks:
   - Does the diff address the ticket's **root cause**, or does it patch a symptom? (e.g. ticket root cause says "race condition in cache layer," diff only adds a null check — that's a symptom patch, flag it.)
   - Does the diff match the ticket's stated **resolution/fix approach**, or has it drifted from what was planned without the ticket being updated?
   - Are there acceptance criteria the diff doesn't visibly satisfy?

## Step 3: Score severity

| Severity | Meaning |
|---|---|
| **Critical** | Exploitable now, will corrupt/lose data, crashes in the common path, or ships a fix that doesn't address the ticket's actual root cause at all. |
| **High** | Real bug/vulnerability needing a specific precondition, or a resolution that meaningfully drifted from the ticket's stated fix approach without explanation. |
| **Medium** | Likely to cause a problem eventually; partial ticket coverage (fixes the reported symptom but not the full root cause). |
| **Low** | Style, maintainability, minor inefficiency, or a defensible-but-unusual pattern. |

Don't inflate severity to seem thorough. Uncertain findings default to a lower severity and say so explicitly.

## Step 4: Format findings

```
[SEVERITY] dimension: file:line — one-line description and why it matters
```
Group by severity (Critical → Low), then dimension. Zero findings in a dimension → say so explicitly ("Security: no issues found"), don't omit it. For ticket-alignment findings with no file:line anchor (e.g. "resolution drifted from ticket"), reference the ticket ID instead.

End with a one-line tally: `1 Critical, 0 High, 3 Medium, 5 Low — nothing blocking, your call.` Never phrase this as a verdict ("fails review") — it's a tally, not a gate.

## Step 5: Choose output destination(s)

Ask via `ask_user_input_v0` before posting anywhere (skip the ask only if the user already specified a destination in their request):
- PR comments only
- Jira comment only
- Jira comment + attach full review doc to the ticket
- All of the above

Then deliver:
- **PR comments** (GitHub mode): `gh api repos/{owner}/{repo}/pulls/{number}/reviews -f event=COMMENT` with a `comments` array of `{path, line, body}`, prefixed with severity tags. Never `REQUEST_CHANGES`/`APPROVE`. If `gh api` fails, fall back to one summary comment via `gh pr comment`.
- **Jira comment**: post the grouped findings + tally as a comment on the ticket via the Jira connector. Keep it scannable — same severity-grouped format as Step 4.
- **Review doc attached to Jira**: generate a markdown doc (title, ticket ID, PR link, full findings, tally) and attach it to the ticket as a file via the Jira connector.
- **Local mode with no ticket destination chosen**: just present findings in chat.

Always tell the user in chat afterward: what was posted, where, and the severity breakdown — don't leave them to go check.

## What this skill does not do

- Never runs `git merge`, `git push --force`, changes branch protection, or approves/requests-changes on a PR.
- Never changes Jira ticket status, priority, or assignee — comments and attachments only.
- Never silently fixes issues it finds — flags them for the human. Fixing is a separate, explicit follow-up.
- Never treats its own findings as final — if the user pushes back on a finding, accept the correction rather than re-asserting without new evidence in the diff or ticket.
