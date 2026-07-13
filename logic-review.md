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
