# Senior Engineering Standards (all code projects)

Applies to every task that writes, edits or reviews code, by the main agent and by subagents (executors, reviewers, QA). Reviewers must audit against this list. Project-level `CLAUDE.md` overrides on conflict. Framework conventions (Odoo models, WordPress/WooCommerce hooks, React, etc.) override the style rules below: follow the framework idiom, apply the principles inside it.

Precedence with Ponytail/YAGNI: these are quality rules for code that gets written, not a license to add structure. Do not split modules, add dataclasses or build abstractions "because the standard says so" when a small function does the job. Split by responsibility only when file size or complexity actually demands it.

## 1. Clean code (any language)

- **Explicit names.** No one-letter or cryptic abbreviations (`i`, `c`, `r`, `res`, `dur`, `f`, `s`) for loop vars, accumulators, rows or API responses. Use `index`, `order`, `row`, `result`, `duration_ms`, `csv_file`. Exceptions: idiomatic math/coordinates, and `i` in a trivial counter loop.
- **Narrow scope.** Declare a variable where it is used. Do not hoist temporaries that one block consumes.
- **One statement per line.** No `;` chaining (`print(...); sys.exit(1)`).
- **Errors never pass silently.** No bare `except:` / empty `catch`. Catch the narrowest type, log or re-raise with context. Define explicit exception classes for business and transport failures (`ApiRequestError`, `OrderAlreadySyncedError`). Map idempotent outcomes (e.g. "already exists" HTTP 400/409) to business success explicitly, without masking real failures.
- **Typed data over loose dicts.** Use `@dataclass` (Python), interfaces/types (TS), typed structs elsewhere. Full type hints on public functions. Prefer flat over nested structures.
- **Functional core, thin shell.** Business logic, transformations and validation as pure functions (explicit params, return new values, no side effects). Classes are for structured data, or where the framework requires them. I/O (network, disk, DB) at the edges, orchestrated by `main()`/handlers.
- **No mutable global state.** No `global`. `SCREAMING_SNAKE_CASE` only for truly immutable module constants (`frozenset`, `tuple`, numbers, strings). Mutable state never lives at module level.
- **Lookup tables loaded once.** JSON/CSV rule tables are read at startup and converted to native in-memory structures; no repeated disk I/O per iteration or validation.
- **Single responsibility.** When a script or module outgrows one concern, split by role (models/DTOs, tables, pure helpers, validators, scenarios/fixtures, `main()` as pipeline orchestration). Standalone one-off utility scripts may stay a single file (even ~1000 lines) if they otherwise follow this list.
- **Limits.** Line length 120. Cyclomatic complexity < 10 (ruff `C901`); extract single-purpose functions instead of nesting.
- **Imports.** One module per line, stdlib first, blank line, then third-party, then local (PEP 8 / isort grouping).
- **Comments** explain why, not what. No dead code, no commented-out blocks.

## 2. Security and secrets (non-negotiable)

- Never hardcode credentials, tokens, API keys, connection strings. Read from environment (`~/.secrets`, project `.env` that is gitignored). Use placeholders in templates.
- Validate input at trust boundaries (HTTP handlers, webhooks, CLI args, files). Parameterized queries only. No `eval`/shell string interpolation of external data.
- No real PII (CPF, names, emails, phones) or real tokens in fixtures, test data, logs or docs. Synthetic data only. Mask sensitive values in logs.

## 3. Network resilience and integrations

- **Consistency over speed.** Do not burst. A pipeline that never gets blocked beats a fast one that gets the IP banned by a WAF or circuit breaker.
- **Adaptive throughput (AIMD)** for batch jobs against external APIs: small additive speed-up after N consecutive successes, halve on HTTP 429.
- **429/5xx are transport signals, not item failures.** Keep the request in memory, exponential backoff with jitter, honour `Retry-After`, retry the exact same request before moving on. No skipped records, no silent drops.
- **Timeouts on every request.** Bounded retries (`--max-retries`), then fail loudly with context.
- **Idempotency.** Webhooks, syncs and imports must be safe to replay: stable external IDs, upsert semantics, dedupe keys.
- **Measure latency with a monotonic clock** (`time.perf_counter()` in Python), never wall-clock differences.
- **Incremental persistence.** Batch output written row by row with an immediate `flush()`, so interruptions keep progress. Resumable via an `--index`/cursor: write mode `"w"` on a fresh run (header once), `"a"` on resume (no duplicate header). CSVs for Excel users: `utf-8-sig`.
- **Money is never float.** Use `Decimal` / integer cents. Currency and rounding rules explicit.

## 4. Scripts and automation (Python)

- Standalone scripts carry PEP 723 inline metadata (`# /// script` with `requires-python` and `dependencies`) so `uv run script.py` works with no manual venv.
- Standard library first; add a dependency only when stdlib clearly falls short and the project does not already ship one. Follow the HTTP client the project already uses. Gotcha: `urllib.request` rewrites header names to Title-Case, which some gateways reject (HTTP 502) when they require lowercase (`x-api-key`); use `http.client` or the project's client with explicit header casing in that case.
- `argparse` with consistent flags across scripts: `--dry-run`, `--limit`, `--index`, `--out`, `--rps`, `--max-rps`, `--max-retries`. `--limit` takes precedence over any `--test` flag.
- Any script with side effects (writes, API mutations, deletes) has `--dry-run`: offline simulation that exercises parsing, sanitization and file integrity without network or credentials.

## 5. Tests and verification

- Non-trivial logic (branches, parsers, money, security, sync) ships with at least one runnable check that fails if the logic breaks. Smallest thing that works: an `assert` self-check or one `test_*.py`.
- Run the check before declaring done. Report failures with the real output; never claim success unverified.
- Fix root causes, not symptoms: grep all callers of what you change.

## 6. Review checklist (for reviewer/QA agents)

Fail the review on: cryptic names, bare/silent excepts, secrets or real PII in files, mutable globals, float money, retries without backoff, non-idempotent replayable handlers, missing timeouts, side-effect script without `--dry-run`, untested non-trivial logic, complexity > 10, lines > 120. Also flag over-engineering (unrequested abstractions, premature module splits).
