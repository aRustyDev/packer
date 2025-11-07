---
title: mdBook JSON-to-Table Integration
id: B73E581A-17F3-49DD-97AB-47B76075E258
---

# mdBook JSON-to-Table Integration

## Problem

Existing widely-used mdBook preprocessors do not (as of current publicly documented ecosystem) provide a generic “load arbitrary JSON and render a table” feature out of the box.

Common plugins (mdbook-mermaid, mdbook-plantuml, mdbook-include, mdbook-admonish, mdbook-toc, etc.) focus on diagrams, includes, admonitions, and ToC—not dynamic JSON tabulation.

## Solution

Create a custom mdBook preprocessor plugin that:

- Detects a special directive in markdown files (e.g., `{{json-table path="data/virtual-disk-feature-matrix.json"}}`).
- Loads the specified JSON file at build time.
- Parses the JSON into a structured format.
- Generates a Markdown table representation of the JSON data.
- Replaces the directive in the markdown with the generated table before rendering.

## Possible Approaches

1. Custom Preprocessor Plugin (Rust)
   - Implement the mdBook Preprocessor trait.
   - Scan markdown for a directive (e.g., {{json-table path="data/virtual-disk-feature-matrix.json"}}).
   - Load JSON, generate a Markdown table, replace directive before rendering.
   - Advantage: Static site output (no client-side JS required).
   - Disadvantage: Requires building & distributing your plugin binary.

2. Convert JSON to Markdown table via script (pre-build step)
   - A build script (Python/Go/Rust) reads JSON and writes a .md partial.
   - Use mdbook-include (or standard Markdown link) to include the generated file.
   - Simplest approach—no plugin code needed.

Recommended Path:

- Start with pre-build script approach (lowest friction).
- If you need dynamic filtering/sorting in the rendered docs, later add a custom preprocessor
