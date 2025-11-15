# BACKLOG Tasks – mdBook `json-2-mdtable` Plugin

This backlog enumerates all NON‑MVP tasks (deferred until after `v0.1.0`). Each task expands capabilities, improves robustness, or adds developer ergonomics beyond the minimal stable core.

---

## 1. Advanced Directive Features

- [ ] Attribute: `columns="col1,col2,col3"` (explicit ordering / subset)
- [ ] Attribute: `sort="column:asc"` (multi-key later: `col1:asc,col2:desc`)
- [ ] Attribute: `filter="key=value"` (exact match; future: operators)
- [ ] Attribute: `align="left,right,center"` (per-column; fallback left)
- [ ] Attribute: `style="compact|full"` (table density preset)
- [ ] Attribute: `truncate="N"` to limit displayed rows with a footnote
- [ ] Attribute: `caption="Readable Title"`
- [ ] Attribute conflict detection & warning
- [ ] Directive versioning attribute `schema="1"` (forward compatibility)
- [ ] Multi-table directive block (aggregate multiple JSON sources into one merged table)

## 2. Extended JSON Handling

- [ ] Support input where `rows` is an array of arrays (require `columns` explicitly)
- [ ] Auto-normalize nested objects: flatten keys with dot notation (`spec.cpu.cores`)
- [ ] Detect numeric columns vs string for alignment/formatting
- [ ] Large integer & float formatting (configurable precision)
- [ ] Optional pretty value shortening (e.g., truncate long strings with tooltip hint – future HTML mode)

## 3. Robust Directive Parsing Enhancements

- [ ] Replace ad-hoc attribute parsing with a small formal grammar (e.g., pest)
- [ ] Support quoted values with escaped quotes
- [ ] Provide explicit error messages for malformed attributes with line/column
- [ ] Cache directive parsing results (avoid reparse if content unchanged across incremental builds – future incremental mode)

## 4. Cross-Chapter / Aggregation Features

- [ ] `generate_summary = true` config option
- [ ] Summary chapter listing: table file path, row count, derived columns
- [ ] Aggregate metrics (e.g., total rows across all tables)
- [ ] Error summary section (list of directives that failed → quick reference)
- [ ] Configurable summary chapter title & insertion position (end vs before first appendix)

## 5. Synthetic Chapters & Content Insertion

- [ ] Insert index of all directive anchor points with internal links
- [ ] Generate “Tables Glossary” mapping column names → first-seen description (if provided via metadata)
- [ ] Add optional per-table anchors for cross-referencing

## 6. Multi-Renderer & Mode Support

- [ ] Conditional support matrix: HTML (yes), JSON renderer (pass-through), EPUB/PDF (validate)
- [ ] Renderer negotiation tests
- [ ] HTML renderer variant (custom table markup with classes for styling)
- [ ] Theming hooks (CSS class prefix config)

## 7. Performance & Scalability

- [ ] Benchmarks: N=1K, 10K, 100K rows (document thresholds)
- [ ] Streaming parser option (serde_json::Deserializer) for large row arrays
- [ ] Incremental build optimization: skip reprocessing if file + directive hash unchanged
- [ ] Parallel table generation (Rayon) with ordering preserved (investigate)
- [ ] Memory usage logging (opt-in profiling mode)

## 8. Error & Warning UX Improvements

- [ ] Structured warning emission (JSON to stderr behind flag)
- [ ] Configurable warning suppression list
- [ ] Severity levels: info / warn / error
- [ ] Suggest auto-fix guidance for common issues (e.g., empty rows)

## 9. Security & Hardening (Beyond MVP)

- [ ] Sandboxed path root override (`allowed_roots = []`)
- [ ] Enforce UTF‑8 normalisation (prevent spoofing via homoglyphs)
- [ ] Optional SHA256 checksum validation attribute (`sha256="..."`)
- [ ] JSON schema validation (user-supplied schema file)

## 10. Extensibility & Plugin API Surface

- [ ] Expose internal table rendering as a library API (`render_table_from_value`)
- [ ] Provide trait hooks for custom cell renderers
- [ ] Feature flag: `custom-render` enabling pluggable formatting functions
- [ ] Export stable internal directive AST type

## 11. Advanced Formatting & Styling

- [ ] Column width heuristics (truncate + ellipsis)
- [ ] Alignment inference (numeric → right)
- [ ] Optional zebra striping class (HTML mode)
- [ ] Markdown footnotes integration for truncated cells
- [ ] Multi-line cell content wrapping strategy (escape newlines)

## 12. Internationalization (i18n) Pipeline

- [ ] Configurable “(no data)” placeholder per locale
- [ ] Column name localization mapping (config)
- [ ] Add translation file ingestion (YAML/JSON) keyed by column

## 13. Distribution & Release Enhancements

- [ ] Prebuilt binaries via CI for major OS targets
- [ ] GPG sign release artifacts
- [ ] Supply container image (scratch / distroless) with plugin for reproducible builds
- [ ] Homebrew formula / Scoop manifest (optional)
- [ ] crates.io README badges (build, version, downloads, license)

## 14. Documentation Enhancements

- [ ] Animated GIF or screenshot of before/after build
- [ ] “Playground” example repository template
- [ ] FAQ expansions (performance tuning, debugging)
- [ ] Compare “pre-build script vs plugin” in decision log with pros/cons table
- [ ] Add architecture diagram (data flow from mdBook → plugin → output)

## 15. Testing & Quality Expansion

- [ ] Property-based tests (arbitrary JSON tables)
- [ ] Fuzz tests on directive parser
- [ ] Snapshot test suite for multiple directive permutations
- [ ] Stress test: many small directives in a single chapter
- [ ] Cross-platform path edge cases (Windows drive letters, UNC)

## 16. Telemetry / Instrumentation

- [ ] `JSON_TABLE_PROFILE=1` → emit processing time per directive
- [ ] Aggregate metrics chapter (optional)
- [ ] Structured JSON metrics output to file (path configurable)
- [ ] Add privacy note & disable by default

## 17. Migration Path & Deprecations

- [ ] Provide migration guide from script-based solution (diff examples)
- [ ] Deprecation warnings for old directive attribute names (if renamed)
- [ ] Versioned directive spec document (v1 → v2 change log)

## 18. Edge Case Handling Beyond MVP

- [ ] Mixed row key sets → optional mode to show union vs intersection
- [ ] Detect and warn about >N columns (suggest split)
- [ ] Handle extremely wide tables by splitting horizontally (multi-table output)
- [ ] Automatic numeric formatting (thousands separators, decimals)
- [ ] Optional CSV ingestion (auto convert to JSON structure internally)

## 19. Alternative Input Sources

- [ ] Allow `.yaml` if `allow_yaml=true` (convert to JSON structure)
- [ ] Allow directory glob merging (e.g., `path="data/*.json"`)
- [ ] Optional “inline JSON” directive fallback (embed JSON directly under directive fenced code)
- [ ] Support remote fetch (disabled by default; explicit `allow_remote=true` config)

## 20. HTML Renderer Variant (Future)

- [ ] Output `<table>` with `<thead>/<tbody>`
- [ ] Add `data-*` attributes for tooling
- [ ] Collapsible long tables (expand/collapse control)
- [ ] Column sort interaction (static JS resource injection)
- [ ] Accessibility audit (headers, scope, roles)

## 21. Backward Compatibility Policy

- [ ] Publish policy document (guarantees for directive syntax stability)
- [ ] Deprecation schedule (announce in CHANGELOG, remove after two minor versions)
- [ ] Introduce feature flags gating experimental attributes

## 22. Developer Tooling

- [ ] `make dev` or `just dev` script: rebuild + run test fixture book
- [ ] Live reloader for doc examples (optional)
- [ ] Lint for directive misuse in project docs
- [ ] Pre-commit hook (format, clippy, tests for critical paths)

## 23. Community & Support

- [ ] CONTRIBUTING.md with PR guidelines
- [ ] ISSUE_TEMPLATE for bug reports (ask for sample JSON + directive)
- [ ] Feature request template
- [ ] Code of Conduct inclusion

## 24. Risk & Mitigation Tracking

- [ ] Large JSON OOM risk → document limits + size guard
- [ ] Directive misuse (typos) → improved diagnostics
- [ ] Table rendering regressions → snapshot test baseline
- [ ] Unintended directory traversal → path sanitizer existing; extend tests
- [ ] Unicode normalization issues → add normalization option

## 25. Experimental / Stretch Ideas

- [ ] WASM build for browser-based pre-render preview
- [ ] Inline interactive filtering (HTML + JS)
- [ ] Merge with search index generation
- [ ] Content hash annotation for downstream caching
- [ ] AI-assisted column description generation stub (external tool hook)
- [ ] Markdown → JSON reverse export (generate JSON from markdown table)

---

## Backlog Triage Labels (Suggested)

| Label            | Meaning                                  |
|------------------|-------------------------------------------|
| feat-core        | Core functional enhancement              |
| feat-format      | Formatting / styling                     |
| feat-perf        | Performance / scalability                |
| feat-security    | Security / validation                    |
| docs             | Documentation                            |
| test             | Testing / QA                             |
| dist             | Release & distribution                   |
| ux               | User experience                          |
| experimental     | Not guaranteed for stability             |
| deferred         | Low priority / long-term                 |

---

## Proposed Post-MVP Ordering (High-Level)

1. Sorting / columns / filter (feat-core)
2. Summary chapter + synthetic index (feat-core)
3. Performance optimizations & caching (feat-perf)
4. Advanced parsing grammar (feat-core / test)
5. HTML renderer variant (feat-format / ux)
6. YAML & glob ingestion (feat-core)
7. Security hardening (checksum, sandbox roots) (feat-security)
8. Telemetry (experimental)
9. Interactive HTML enhancements (experimental)
10. Internationalization (i18n) support (feat-format)

---

## Completion Tracking

Create separate issues referencing the checkbox line verbatim for easy automation. Move completed items to a DONE log or tag them with `done` label in your tracking system.

---

End of BACKLOG file.
