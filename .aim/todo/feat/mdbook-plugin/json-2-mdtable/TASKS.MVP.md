# MVP Tasks – mdBook `json-2-mdtable` Plugin

This file enumerates the minimum viable product (MVP) tasks required to ship a functional, reliable first version of the `json-2-mdtable` mdBook preprocessor. Focus is on correctness, safety, testability, and clear developer/User documentation. Non‑essential enhancements (sorting, filtering, telemetry, synthetic chapters, pagination, styling) are explicitly excluded here and deferred to backlog.

---

## 1. Core Functionality

- [ ] Implement minimal Rust preprocessor binary:
  - Reads `(PreprocessorContext, Book)` JSON from stdin.
  - Traverses chapters, detects directive(s), replaces with table markdown.
  - Writes updated `Book` JSON to stdout.
- [ ] Define directive syntax (initial):
  - `{{json-table path="relative/path/to/data.json"}}`
  - Reject unknown attributes (warn, ignore) – future attributes reserved.
- [ ] Implement JSON loader:
  - Validate file exists & is readable.
  - Parse JSON expecting `{ "columns": [...], "rows": [ {...}, ... ] }`.
  - If `columns` missing, derive from union of keys across rows (deterministic order: sorted alphabetically).
  - If `rows` empty, render placeholder `(no data)`.

## 2. Directive Parsing Robustness

- [ ] Use `pulldown-cmark` event stream to detect directive tokens.
- [ ] Ignore occurrences inside fenced code blocks, inline code, HTML comments.
- [ ] Support multiple directives per chapter.
- [ ] Provide helper function `find_directives(chapter_content) -> Vec<Directive>` (parsed attributes).
- [ ] Unit tests:
  - Single directive.
  - Multiple directives.
  - Directive in code fence (ignored).
  - Malformed directive (emit warning, skip).

## 3. Configuration Basics

- [ ] Read `[preprocessor.json-table]` section from `book.toml`:
  - Keys: `fail_on_error` (bool, default `false`), `max_json_bytes` (int, default `1048576`).
  - Document defaults in README.
- [ ] Implement size check (abort or warn based on `fail_on_error`).
- [ ] Expose configuration via internal `Config` struct with validation.
- [ ] Unit tests for config parsing (missing section, partial section, invalid values).

## 4. Security & Path Validation

- [ ] Reject absolute paths (`/`, drive letters, UNC).
- [ ] Reject traversal (`..` components).
- [ ] Enforce path is relative to book root (context root).
- [ ] Escape table cell content:
  - Pipes `|`, backticks `` ` ``, and leading colons (avoid alignment ambiguity).
- [ ] Unit tests:
  - Valid relative path.
  - Attempted traversal.
  - Absolute path.
  - Escaping special characters.

## 5. Error Handling & Fallback

- [ ] Standardize stderr messages with prefix `[json-table]`.
- [ ] Distinguish:
  - Recoverable (missing file, malformed JSON): insert warning table + continue (unless `fail_on_error`).
  - Fatal (I/O read failure with `fail_on_error=true`, JSON > max size with `fail_on_error=true`): exit non‑zero.
- [ ] Implement fallback rendering:
  ```
  | Error |
  |-------|
  | Failed to render table: <message> |
  ```
- [ ] Unit tests for:
  - Missing file (fallback).
  - Malformed JSON (fallback).
  - Oversized JSON (warn or fail based on config).
  - Fatal exit when `fail_on_error=true`.

## 6. Table Rendering

- [ ] Render header row from `columns`.
- [ ] Render separator row using `---`.
- [ ] Render each row preserving column order; blank cell if key absent.
- [ ] Consistent deterministic output (alphabetical columns if derived).
- [ ] Unit test golden output (snapshot test).
- [ ] Ensure trailing newline at end of table.

## 7. Integration Tests

- [ ] Simulate mdBook stdin input with:
  - Minimal `Book` containing one chapter plus directive.
  - Process through binary; capture stdout; assert JSON mutated.
- [ ] Multi-directive chapter test (two tables).
- [ ] Chapter with no directives (identity transform).
- [ ] Performance sanity test (large synthetic JSON ≤ max size).
- [ ] Validate JSON output remains valid after transformation.

## 8. Distribution Metadata (Release Prep)

- [ ] Create `Cargo.toml` metadata:
  - `name = "mdbook-json-table"`
  - `license`, `repository`, `categories = ["command-line-utilities", "development-tools"]`
  - `keywords = ["mdbook", "preprocessor", "json", "table"]`
- [ ] Add README:
  - Overview, directive syntax, config keys, examples, error handling.
- [ ] Add minimal CHANGELOG (Unreleased + 0.1.0).
- [ ] Add `LICENSE` file.
- [ ] Provide install command: `cargo install mdbook-json-table`.
- [ ] Verify binary name matches preprocessor section requirement.

## 9. CI Essentials

- [ ] Workflow:
  - Build + test (`cargo test --all`).
  - Lint: `cargo clippy -- -D warnings`.
  - Format check: `cargo fmt -- --check`.
  - Security audit: `cargo audit` (allow failure optional).
- [ ] Cache dependencies.
- [ ] Badge readiness (optional, add later).
- [ ] Matrix for Rust stable + msrv (if defined).

## 10. Documentation Enhancements (MVP scope only)

- [ ] Add “Glossary” (Directive, Chapter, PreprocessorContext, Book).
- [ ] Add “Decision Log” entry: chose plugin over pre-build script for static site guarantee + extensibility.
- [ ] Add “Troubleshooting” section:
  - Missing file
  - Malformed JSON
  - Oversized JSON
  - No directives found
- [ ] Provide one inline full Rust example (annotated).
- [ ] Provide minimal JSON example (columns + rows).
- [ ] Document fallback behavior & config overrides.

## 11. Quality Gates Before 0.1.0 Release

- [ ] All MVP unit tests pass.
- [ ] Integration tests verified.
- [ ] README accurate & complete.
- [ ] No clippy warnings.
- [ ] Git tag `v0.1.0` planned (do after publish).
- [ ] Dry run `cargo publish --dry-run` succeeds.

## 12. Post-Release TODO Placeholder (Not Implemented in MVP)

(Do NOT implement yet; list for clarity)
- Sorting/filtering attributes.
- Column alignment options.
- Synthetic summary chapter.
- Python reference implementation.
- Telemetry/metrics.
- Pagination for large tables.
- HTML renderer variant.

---

## Suggested Branch Workflow (MVP)

1. `feat/mvp-core-preprocessor` – implement minimal run + directive detection.
2. `feat/mvp-table-render` – table renderer & escaping.
3. `feat/mvp-config` – configuration parsing + validation.
4. `feat/mvp-security` – path validation & size limits.
5. `feat/mvp-error-fallback` – fallback logic & stderr formatting.
6. `feat/mvp-tests` – unit & integration tests.
7. `feat/mvp-ci-docs` – CI setup, README, CHANGELOG, license.
8. `release/v0.1.0` – final polish, version bump, tag.

---

## Progress Tracking (Update with [x])

- [ ] Core preprocessor implemented
- [ ] Directive parser robust (pulldown-cmark)
- [ ] Config parsing + defaults
- [ ] Path security validation
- [ ] Fallback error table
- [ ] Unit tests passing
- [ ] Integration tests passing
- [ ] Table renderer deterministic
- [ ] CI pipeline active
- [ ] README + Glossary + Decision Log
- [ ] License + CHANGELOG added
- [ ] Publish dry-run success
- [ ] Ready for `v0.1.0` tag

---

## Acceptance Criteria for MVP

- Running mdBook with `[preprocessor.json-table]` configured transforms directives into valid markdown tables.
- No crash on malformed or missing JSON; behavior matches config (warn vs fail).
- Path traversal attempts are safely rejected.
- Output markdown tables render correctly in generated book.
- Tests cover directive parsing, error handling, table rendering, config logic.
- Installable via `cargo install mdbook-json-table`.
- Clear documentation for users to integrate quickly.

---

End of MVP task list. All backlog items remain in the main TASKS.md file for future iterations.
