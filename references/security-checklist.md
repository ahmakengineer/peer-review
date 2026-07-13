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
