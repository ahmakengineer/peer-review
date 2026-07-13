# Auto-Install: peer-review

**For humans:** copy everything below this line and paste it as a message to your coding agent (Claude Code, Cursor, Windsurf, OpenCode, Codex CLI, Gemini CLI, or GitHub Copilot). The agent will install itself — no manual `mkdir`/`cp` needed.

---

You are being asked to install an Agent Skill called `peer-review` into your own skill-discovery path. Follow these steps exactly:

**Step 1 — Identify yourself.** Determine which agent you are currently running as (Claude Code, Cursor, Windsurf/Cascade, OpenCode, Codex CLI, Gemini CLI, or GitHub Copilot).

**Step 2 — Pick your install path** from this table. Prefer the personal/global path if one exists for you and the user hasn't specified a project-only preference; otherwise use the project path.

| Agent | Personal/global path | Project path |
|---|---|---|
| Claude Code | `~/.claude/skills/peer-review/` | `.claude/skills/peer-review/` |
| Cursor | *(none)* | `.cursor/skills/peer-review/` |
| Windsurf (Cascade) | *(none)* | `.windsurf/skills/peer-review/` |
| OpenCode | `~/.config/opencode/skills/peer-review/` | `.opencode/skills/peer-review/` |
| Codex CLI | `~/.agents/skills/peer-review/` | `.agents/skills/peer-review/` |
| Gemini CLI | `~/.gemini/skills/peer-review/` | `.gemini/skills/peer-review/` |
| GitHub Copilot | `~/.copilot/skills/peer-review/` | `.github/skills/peer-review/` |

If you can't confidently identify which agent you are, ask the user which path to use rather than guessing.

**Step 3 — Create the directory structure** at the chosen path:
```
peer-review/
├── SKILL.md
└── references/
    ├── security-checklist.md
    ├── logic-review.md
    ├── style-guidelines.md
    └── ticket-integration.md
```

**Step 4 — Write each file below with its exact content**, verbatim, into the path from Step 2. Do not paraphrase, reformat, or summarize — copy the content between each `FILE:` marker and the next one exactly as-is, including the YAML frontmatter.

**Step 5 — Verify.** After writing all five files, list the directory to confirm all files are present, then tell the user the skill is installed and where, and mention that a restart or reload command (`/skills reload`, `/reload-plugins`, "Reload Window," or a fresh session — whichever applies to you) may be needed before it's recognized.

---

=== FILE: SKILL.md ===
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

=== FILE: references/security-checklist.md ===
# Security Review Patterns

Only flag something here if the pattern is actually present in the changed lines — don't pad the report with checklist items that don't apply. Each pattern below includes what to look for and a default severity; adjust up/down one level based on actual exploitability in context (e.g. is the input truly user-controlled, is the code reachable pre-auth).

## Injection
- **SQL/NoSQL**: string concatenation or f-strings/template literals building queries from request data instead of parameterized queries/prepared statements. → High/Critical if pre-auth or admin-privileged.
- **Command injection**: user input passed into `subprocess`, `os.system`, `exec`, backticks, or shell=True without sanitization. → Critical.
- **Path traversal**: user-controlled input concatenated into file paths without normalization/allowlisting. → High.
- **SSRF**: user-supplied URLs/hosts fetched server-side without an allowlist. → High.

## Secrets and credentials
- Hardcoded API keys, passwords, tokens, or private keys added in the diff (not just referenced from env/secret manager). → Critical, regardless of whether it's a test file — test secrets get reused.
- Secrets logged (`print`, `console.log`, logger calls) even at debug level. → Medium/High depending on log destination.

## AuthN/AuthZ
- An existing auth check, permission check, or ownership check removed or weakened in the diff. → Critical — this is the single highest-value thing to catch.
- New endpoint/route/handler added without an auth decorator/middleware that sibling endpoints in the same file have. → High.
- Object/resource IDs taken directly from request params and used to fetch data without verifying the requester owns/can access that resource (IDOR). → High.

## Deserialization and parsing
- `pickle.loads`, `yaml.load` (not `safe_load`), PHP `unserialize`, Java `ObjectInputStream` on untrusted input. → Critical.
- XML parsing without disabling external entity resolution (XXE). → High.

## Cryptography
- Weak/broken algorithms introduced (MD5/SHA1 for passwords, ECB mode, DES). → High.
- Hardcoded IV, salt, or nonce; reused nonce for AEAD ciphers. → High.
- Passwords stored/compared without a proper KDF (bcrypt/scrypt/argon2) — plain hash or plaintext. → Critical.

## Input validation
- Request body/query/header data used without type or bounds checking where it flows into something sensitive (a query, a file op, a size-based allocation). → Medium, escalate if it flows into one of the categories above.

## Web-specific (only if diff touches frontend/template rendering)
- User content rendered without escaping (XSS) — raw HTML insertion, `dangerouslySetInnerHTML`, unescaped template output. → High.
- New state-changing endpoint without CSRF protection where the app otherwise uses it. → Medium/High.

## What NOT to flag
- Generic "consider adding rate limiting" or "consider a WAF" style commentary with no basis in the actual diff — that's noise, not a finding.
- Dependency version numbers, unless the diff itself changes a lockfile to a version with a known issue you can name specifically.

=== FILE: references/logic-review.md ===
# Logic Review Approach

Logic bugs can't be judged from the diff lines alone — you need to know what the code is *supposed* to do. Before flagging anything, spend a moment gathering context:

1. **Read the stated intent.** PR description, commit message, or linked ticket if available (`gh pr view --json body,title`). If none exists, infer intent from the function/variable names and surrounding code — but say so explicitly if a finding rests on inferred rather than stated intent.
2. **Check callers.** For any changed function signature or return value, grep for call sites. A logic bug is often not in the changed function but in a caller that now receives something different (changed error type, changed null-handling, changed ordering).
3. **Check existing tests.** Do tests cover the changed path? If tests were changed in the same diff to match new (possibly wrong) behavior, that's worth a note — tests changed alongside logic can mask a regression rather than catch it.

## Patterns to look for

- **Off-by-one / boundary conditions**: loop bounds, slice/array indexing, pagination offsets changed without corresponding test coverage.
- **Null/None/undefined handling**: a new code path that doesn't handle a value the type system or surrounding code implies could be absent.
- **Error handling swallowed**: broad `except:`/`catch` blocks added that suppress errors without logging or re-raising; changed error types that no longer match what callers check for.
- **Race conditions / concurrency**: shared state (cache, counter, file) mutated without a lock/transaction where the surrounding code otherwise uses one; check-then-act patterns on shared resources.
- **Resource leaks**: opened file handles, DB connections, or network sockets without a corresponding close/context manager, especially on early-return or exception paths.
- **State mutation surprises**: a function that used to be pure now mutates an argument in place, or vice versa — check if callers assume the old behavior.
- **Changed defaults**: a default parameter value or config default changed in a way that alters behavior for existing callers who don't pass that argument explicitly.
- **Inverted or reversed conditionals**: easy to introduce during refactors — worth a close read on any boolean logic that was touched, not just added.

## Confidence calibration

If you're inferring intent rather than reading it, phrase the finding as a question rather than an assertion: "This assumes X, but I don't see where X is guaranteed — is that intentional?" rather than "This is a bug." That distinction should be visible in Step 4's severity/description, not just in your own reasoning.

=== FILE: references/style-guidelines.md ===
# Style / Coding Guidelines

Style is project-specific — don't apply a generic house style as if it were objective. Follow this priority order:

1. **Look for the project's own config first**, in this rough order of precedence:
   - Linter/formatter configs: `.eslintrc*`, `.prettierrc*`, `pyproject.toml` (`[tool.ruff]`/`[tool.black]`), `.flake8`, `.rubocop.yml`, `.golangci.yml`, `checkstyle.xml`, `.editorconfig`
   - A `CONTRIBUTING.md` or `STYLE.md` if present
   - An existing `.github/pull_request_template.md` that lists review criteria
2. **If a config exists**, only flag violations of *that* config — run the linter/formatter directly if available (`eslint`, `ruff`, `black --check`, etc.) rather than eyeballing it, and report its actual output. This is more reliable than guessing.
3. **If no config exists**, fall back to general, widely-agreed conventions only, and cap all findings from this fallback at **Low** severity:
   - Naming consistency within the file/module (don't demand a project-wide convention if one isn't established)
   - Function/method length and obvious duplication introduced by this diff specifically (not pre-existing code you happen to be looking at)
   - Dead code, unused imports/variables introduced in the diff
   - Missing or misleading comments only where the logic is genuinely non-obvious — don't ask for comments on self-explanatory code

## What NOT to flag

- Formatting that a project's own formatter would auto-fix (trailing whitespace, quote style, import ordering) — if a formatter config exists, just say "run `<formatter>`" once rather than listing each instance.
- Pre-existing style issues in code adjacent to the diff but not actually changed by it.
- Personal style preferences not backed by the project's config or a stated convention (e.g. tabs vs spaces when no `.editorconfig` exists) — note it as a Low "worth establishing a convention" item at most, not a violation.

## To customize this file for your project

Replace this section with your team's actual conventions once you've run this skill a few times and have a sense of what keeps coming up — e.g. specific naming patterns, preferred error-handling idioms, required docstring formats, or forbidden patterns specific to your codebase.

=== FILE: references/ticket-integration.md ===
# Ticket Integration (Jira / GitHub Issues)

## Ticket ID patterns

- **Jira**: `[A-Z][A-Z0-9]+-\d+` (e.g. `PROJ-123`, `ABC2-45`). Project key is always uppercase letters/digits, followed by a dash and a number.
- **GitHub Issues**: `#\d+` in text, or a bare number when the user names it directly. Also recognize the auto-link phrases GitHub itself treats as issue references: `Fixes #123`, `Closes #123`, `Resolves #123`.

Don't guess a ticket ID from something that merely looks numeric (e.g. a version number or port number) — require the `#` prefix or the letters-dash-number Jira shape.

## Fetching — Jira

Use the Jira MCP connector's tools if connected. Typical fields to pull (names vary by instance/config, so check what's actually returned rather than assuming a fixed schema):
- `summary` / `description` — what the ticket is about
- **Root cause**: often a custom field (`Root Cause`, `RCA`), or embedded in the description/a linked postmortem — if there's no dedicated field, search the description and comments for a root-cause-style statement before concluding it's absent.
- **Resolution / fix approach**: `Resolution` field if set, or the most recent comment describing the intended fix, or a linked design doc.
- `acceptanceCriteria` custom field, or a checklist embedded in the description.
- `status`, `priority`, `labels` — useful context, not required for the review itself.

If the connector isn't connected, don't fail silently — flag it (`search_mcp_registry` for `["jira"]`, then `suggest_connectors`) so the user can connect it, since ticket grounding is the whole point of this skill. If they decline, proceed with a code-only review and say explicitly that ticket alignment wasn't checked.

## Fetching — GitHub Issues

```
gh issue view <number> --json title,body,state,labels,comments
```
GitHub issues rarely have structured root-cause/resolution fields — treat the `body` as free text and look for headers or phrases like "Root cause:", "Fix:", "Resolution:" if the team uses a template (`.github/ISSUE_TEMPLATE/`). If the issue template has no such structure, use the plain description as the intent baseline and skip root-cause-specific comparison — don't force a structured comparison onto unstructured text.

## Comparing diff to ticket

- **Root cause match**: does the diff's actual code change plausibly address the mechanism described as the root cause, or only the symptom the user originally reported? These are often different things — a reported symptom ("page crashes") can have a root cause ("unhandled null from a race condition") that a shallow fix ("add a try/catch around the crash") doesn't actually resolve.
- **Resolution drift**: if the ticket states a specific fix approach and the diff does something materially different, that's not automatically wrong (plans change) — but it's worth surfacing so the ticket can be updated to match reality, especially for audit trail purposes.
- **Confidence**: if the ticket is thin (one-line description, no root cause recorded), say so and lower confidence on ticket-alignment findings accordingly — don't manufacture a root-cause comparison from a ticket that never stated one.

=== END ===
