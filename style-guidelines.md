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
