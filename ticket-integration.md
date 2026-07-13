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
