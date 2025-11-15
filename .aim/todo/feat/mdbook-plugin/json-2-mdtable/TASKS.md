# Tasks

This checklist expands the development tasks required to implement the recommendations in `scratch.md` for the `json-2-mdtable` mdBook plugin specialization.

## Instruction Development

### Fill Conceptual Gaps

- Plugin Taxonomy
  - [ ] Research existing mdBook plugins and categorize (preprocessors, renderers, theme modifiers, link-checkers, exporters, utility helpers).
  - [ ] Document differences between preprocessors vs renderers (execution phase, input/output expectations).
  - [ ] Document role of link-checkers and how they interact with rendered HTML vs source markdown.
  - [ ] Document “alternative backends” (e.g., EPUB/PDF generators) and how renderer support checks work.
  - [ ] Describe theme customization vs functional plugins (CSS/JS layering vs content mutation).
  - [ ] Summarize execution order of multiple preprocessors (ordering in `book.toml`).
  - [ ] Define when a plugin should be a preprocessor vs external build script.
  - [ ] Create a reference table mapping common plugin names to taxonomy categories.

- Lifecycle & Data Flow
  - [ ] Diagram full build lifecycle: load → preprocessors → renderers → post-processing (if any) → output.
  - [ ] Clarify idempotency expectations (plugins should not introduce non-deterministic mutations).
  - [ ] Document side-effects to avoid (network calls, random ordering, time stamps unless explicitly desired).
  - [ ] Provide guidance on multi-pass preprocessors (discourage unless necessary).

- Input/Output JSON Schema Evolution
  - [ ] Capture mdBook version from `PreprocessorContext` and document strategy for compatibility.
  - [ ] Establish semver policy for plugin aligned with mdBook versions.
  - [ ] Define fallback behavior if unsupported schema fields appear.
  - [ ] Add section on pinning mdBook dependency vs using a version range.

- Configuration Design
  - [ ] Show how to read `[preprocessor.json-table]` config from `book.toml`.
  - [ ] Define required vs optional configuration keys.
  - [ ] Provide default values and validation strategy (error vs warning).
  - [ ] Document namespacing recommendations for future options (e.g., `columns`, `sort`, `style`).
  - [ ] Add example of advanced configuration (multi-table directives mapping).

- Directive Parsing Robustness
  - [ ] Implement a pulldown-cmark based directive detector (avoid naive substring search).
  - [ ] Add test for ignoring directives inside fenced code blocks.
  - [ ] Handle multiple directives in one chapter.
  - [ ] Specify escaping strategy or error if malformed directive syntax found.
  - [ ] Document reserved attribute names (`path`, `columns`, `sort`, `filter`).

- Performance & Memory Considerations
  - [ ] Benchmark transformation with large JSON (N rows × M columns).
  - [ ] Provide guidance for streaming read vs full file load (choose full file now; document alternative).
  - [ ] Implement minimal caching (skip re-read if same path used repeatedly within one chapter).
  - [ ] Add notes on memory usage of large table generation.
  - [ ] Document time complexity and recommended size limits.

- Error Handling & Logging
  - [ ] Define fatal vs recoverable errors (missing file = recoverable with warning).
  - [ ] Standardize error messaging format (prefix `[json-table]`).
  - [ ] Ensure stdout contains only final Book JSON; write diagnostics to stderr.
  - [ ] Implement fallback rendering (warning table if JSON invalid).
  - [ ] Add exit code mapping (0 success, non-zero fatal).
  - [ ] Provide examples of user-facing error messages.

- Testing Strategy
  - [ ] Unit test directive parsing (single, multiple, malformed).
  - [ ] Unit test JSON loading (valid, invalid path, malformed JSON).
  - [ ] Unit test column filtering logic (if optional attribute added).
  - [ ] Integration test: simulate mdBook stdin → plugin → stdout comparison.
  - [ ] Golden file test for generated markdown table.
  - [ ] Performance test (time threshold for large dataset).
  - [ ] Matrix CI test (multiple mdBook versions).
  - [ ] Document test harness approach.

- Security / Safety
  - [ ] Implement path sanitation (disallow absolute paths and `..` traversal).
  - [ ] Enforce maximum JSON size (configurable limit).
  - [ ] Disallow network fetch directives (explicitly state scope).
  - [ ] Document handling of untrusted JSON (escape pipes, markdown control chars).
  - [ ] Add unit tests for path rejection cases.
  - [ ] Document security considerations for future HTML renderer extensions.

- Extensibility & Future-proofing
  - [ ] Define directive attribute grammar (key="value" pairs).
  - [ ] Plan reserved attribute names for future features (pagination, style, sort).
  - [ ] Create versioned directive spec documentation.
  - [ ] Add compatibility warning if unknown attributes encountered (non-fatal).
  - [ ] Provide extension points in code (modular functions for transform stages).

- Multi-Renderer Support
  - [ ] Implement `supports_renderer` logic (return true for `html`, false for others initially).
  - [ ] Document how to extend to `linkcheck`.
  - [ ] Add tests for support negotiation phase.
  - [ ] Provide user guidance when plugin is skipped due to renderer mismatch.

- Cross-Chapter Transformations
  - [ ] Add example: generating an index chapter summarizing all tables processed.
  - [ ] Implement optional config key `generate_summary = true`.
  - [ ] Insert synthetic chapter at end (`Summary: Tables`).
  - [ ] Unit test synthetic chapter insertion.

- Example Diversity
  - [ ] Inline minimal Rust plugin example (already outlined; integrate).
  - [ ] Inline Python minimal preprocessor version.
  - [ ] Provide attribute-rich directive example (`{{json-table path="..." columns="name,size" sort="size:desc"}}`).
  - [ ] Example for error fallback (missing file).
  - [ ] Example for adding synthetic chapter.
  - [ ] Example for multi-table reuse with caching.
  - [ ] Example demonstrating column alignment and escaping.

- Distribution & Release
  - [ ] Define crate metadata (license, repository, keywords).
  - [ ] Add README with usage, configuration, examples.
  - [ ] Implement semantic version tags in Git.
  - [ ] Provide `cargo install mdbook-json-table` instructions.
  - [ ] Add CHANGELOG policy.
  - [ ] Define minimal supported mdBook version.
  - [ ] Automate release build (CI binary artifact).

- Tooling Integration
  - [ ] Evaluate optional features (`pulldown-cmark`, `serde_json` features).
  - [ ] Add feature flags (e.g., `extended` for sorting/filtering).
  - [ ] Integrate logging crate (or keep simple eprintln; decide and document).
  - [ ] Provide example of enabling feature in `Cargo.toml`.
  - [ ] Add `cargo fmt` and `clippy` CI steps.

- Telemetry / Instrumentation (Optional)
  - [ ] Add timing measurement (enabled via env var `JSON_TABLE_PROFILE=1`).
  - [ ] Log number of directives processed.
  - [ ] Document privacy considerations (no content logging).
  - [ ] Decide if telemetry compiled behind feature flag.

- Migration Path
  - [ ] Document converting pre-build script approach → plugin.
  - [ ] Create checklist (directive spec freeze, config introduction, tests).
  - [ ] Provide diff examples (before/after transformation).
  - [ ] Establish deprecation notice for script usage once plugin matures.

- Handling Edge Cases
  - [ ] Empty rows → render “(no data)” row or omit.
  - [ ] Empty columns array → derive columns from first row keys.
  - [ ] Very wide tables → recommendation for horizontal scrolling (doc note).
  - [ ] Unicode characters → ensure proper escaping.
  - [ ] Deterministic ordering (sort columns/rows if unspecified).
  - [ ] Rows missing some columns → render blank cells.
  - [ ] JSON values that are arrays/objects → serialize safely.

- Book Mutation Best Practices
  - [ ] Document guidelines: modify chapter content vs create new chapters.
  - [ ] Avoid altering chapter order unless explicitly configured.
  - [ ] Ensure synthetic chapters have unique identifiers.
  - [ ] Provide rollback strategy (no irreversible mutations).
  - [ ] Unit test that original chapter count matches expected after transform (unless summary enabled).

- Style & Accessibility
  - [ ] Add optional column alignment directive (`align="left,right,center"`).
  - [ ] Document guidelines for accessible table headers.
  - [ ] Plan for future HTML renderer: ARIA roles (note placeholder).
  - [ ] Ensure markdown table output is compatible with screen readers (header row semantics).
  - [ ] Escape pipe characters `|` inside cell content.

### Structural Improvements

- [ ] Replace initial numbered list (1–7) with a complete, finalized workflow section.
- [ ] Add “Overview / Goals” section at top.
- [ ] Separate generic plugin architecture from JSON use case.
- [ ] Add “Glossary” section (Directive, Chapter, Renderer, Book, PreprocessorContext).
- [ ] Add “Decision Log” section (script first → plugin rationale).
- [ ] Reorganize “Document Plugin” bullets into subsections (Configuration, Input, Output, Installation, Usage).
- [ ] End document with “Summary & Next Steps”.
- [ ] Ensure consistent heading levels (avoid skipping levels).
- [ ] Add cross-links between sections (Configuration ↔ Directive attributes).

### Reference Enhancements

- [ ] Inline minimal Rust preprocessor example instead of only path reference.
- [ ] Inline Python preprocessor example.
- [ ] Link external advanced examples explicitly (with short description).
- [ ] Add references to mdBook docs: PreprocessorContext, Book, CmdPreprocessor.
- [ ] Include link or citation for pulldown-cmark crate and to-cmark crate.
- [ ] Add link to semantic versioning specification (semver.org).
- [ ] Provide link to security best practices (Rust secure coding guidelines).

### Example Expansion

#### Add Missing Example Categories

- [ ] Robust directive parsing with pulldown-cmark events.
- [ ] Attribute-rich directive usage.
- [ ] Error fallback (file missing).
- [ ] Security path rejection example.
- [ ] Synthetic chapter insertion example.
- [ ] Sorting/filtering table example (future feature).
- [ ] Performance benchmarking script snippet.
- [ ] Configuration-driven style (alignment) example.
- [ ] Multi-table summary aggregation.
- [ ] Python minimal plugin variant.

#### Additional Inline Examples

- [ ] Inline Rust function for path validation.
- [ ] Inline Rust test for directive parsing.
- [ ] Inline Rust test for table rendering (golden output).
- [ ] Inline Rust example for synthetic chapter addition.
- [ ] Inline Rust code demonstrating configuration parsing.
- [ ] Inline Rust code for fallback warning rendering.
- [ ] Inline test harness simulating stdin JSON input.

### Testing & CI

- [ ] Set up CI pipeline (GitHub Actions or similar).
- [ ] Add matrix for mdBook versions (latest, previous minor).
- [ ] Add coverage reporting (optional).
- [ ] Add performance threshold test (warn if exceeds).
- [ ] Add lint (clippy) job.
- [ ] Add formatting check (cargo fmt --check).
- [ ] Add security audit (cargo audit).
- [ ] Add release workflow (tag push triggers build).

### Release Management

- [ ] Draft CHANGELOG template.
- [ ] Define release checklist (tests pass, docs updated, version bumped).
- [ ] Automate `cargo publish` dry-run.
- [ ] Tag repository with semver tags.
- [ ] Provide upgrade guide for breaking changes.

### Documentation Quality Checks

- [ ] Validate all code snippets compile (Rust examples).
- [ ] Provide runnable snippet harness instructions.
- [ ] Add doc section on troubleshooting common errors.
- [ ] Include FAQ (Why not use script? How to handle very large JSON?).
- [ ] Spell-check and run markdown link checker.

### Security Review

- [ ] Threat model (malicious JSON, path injection).
- [ ] Document mitigations.
- [ ] Review dependencies for known CVEs.
- [ ] Add guidance for running in restricted environments.

### Future Enhancements (Backlog)

- [ ] JSON filtering attributes (`filter="key=value"`).
- [ ] Column reordering attribute (`columns="a,b,c"`).
- [ ] Sort attribute (`sort="col:asc"`).
- [ ] Style attribute (minimal theming).
- [ ] Pagination (large tables).
- [ ] Alternative output mode (CSV export).
- [ ] HTML renderer plugin variant.

## Progress Tracking

- [ ] Create a progress board grouping tasks by status (Not Started / In Progress / Done).
- [ ] Assign owners to high-priority tasks.
- [ ] Set initial milestone (MVP: minimal plugin with inline example, path validation, tests).
- [ ] Define secondary milestone (Extended attributes, summary chapter).
- [ ] Define tertiary milestone (Performance tuning, telemetry).

## Prioritization (Initial Ordering)

1. Minimal plugin inline example (Rust).
2. Directive parsing robustness.
3. Configuration parsing basics.
4. Path validation + security.
5. Error fallback & logging.
6. Testing (unit + integration).
7. Distribution metadata & release workflow.
8. Extended features (attributes).
9. Synthetic chapter generation.
10. Performance optimizations.
11. Documentation restructuring.
12. Glossary + Decision Log.
13. Advanced examples (Python, aggregation).
14. Telemetry (optional).

---

Use this checklist to drive incremental commits. Update each `[ ]` to `[x]` as tasks complete. Group related tasks into branches named with a concise descriptor (e.g., `feat/mdbook-plugin/config-support`, `feat/mdbook-plugin/directive-parser`).
