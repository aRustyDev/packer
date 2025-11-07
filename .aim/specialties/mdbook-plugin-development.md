# Developing an mdBook Plugin

1. Identify the Problem
2. Identify possible Solutions
3. Identify possible Approaches to implement the Solution
4. Create a recommended Path, based on the identified Approaches
5. Get Buy in / approval from Stakeholders on the recommended Path
6. Create or Identify Example Code snippets for the recommended Path
7.

## Identify the Problem

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
- If you need dynamic filtering/sorting in the rendered docs, later add a custom preprocessor.

### Example Code

- .aim/example/snippets/mdbook-plugin-preprocessor.rs

### Integration Steps

1. Build plugin: `cargo build --release`
2. Add to `book.toml`:
   ```
   [preprocessor.json-table]
   command = "target/release/json-table"
   ```
3. Use directive in markdown:
   ```
   {{json-table path="data/virtual-disk-feature-matrix.json"}}
   ```

### Plugin Naming Convention

- Suggested name: `mdbook-<plugin-name>`

### Document Plugin

- Required `book.toml` configuration.
- Option `book.toml` configuration.
- Example Input
  - Json data
  - File tree
  - Markdown snippet with directive
- Example Output
  - Rendered Markdown table
- Screen capture of rendered table in mdBook output
- Install instructions
  - ex: `cargo install mdbook-foobar`
- Usage instructions
  - ie: How to define the directive in markdown

## Preprocessors

A preprocessor is simply a bit of code which gets run immediately after the book is loaded and before it gets rendered, allowing you to update and mutate the book. Possible use cases are:

- Creating custom helpers like `{{#include /path/to/file.md}}`
- Substituting in latex-style expressions `($$ \frac{1}{3} $$)` with their mathjax equivalents

> See [Configuring Preprocessors](https://mdbook-guide.irust.net/en-us/format/configuration/preprocessors.html) for more information about using preprocessors.

### Hooking Into MDBook

MDBook uses a fairly simple mechanism for discovering third party plugins. A new table is added to book.toml (e.g. `[preprocessor.foo]` for the foo preprocessor) and then mdbook will try to invoke the mdbook-foo program as part of the build process.

Once the preprocessor has been defined and the build process starts, mdBook executes the command defined in the preprocessor.foo.command key twice. The first time it runs the preprocessor to determine if it supports the given renderer. mdBook passes two arguments to the process: the first argument is the string supports and the second argument is the renderer name. The preprocessor should exit with a status code 0 if it supports the given renderer, or return a non-zero exit code if it does not.

If the preprocessor supports the renderer, then mdbook runs it a second time, passing JSON data into stdin. The JSON consists of an array of `[context, book]` where context is the serialized object [PreprocessorContext](https://docs.rs/mdbook/latest/mdbook/preprocess/struct.PreprocessorContext.html) and book is a [Book](https://docs.rs/mdbook/latest/mdbook/book/struct.Book.html) object containing the content of the book.

The preprocessor should return the JSON format of the [Book](https://docs.rs/mdbook/latest/mdbook/book/struct.Book.html) object to stdout, with any modifications it wishes to perform.

The easiest way to get started is by creating your own implementation of the Preprocessor trait (e.g. in lib.rs) and then creating a shell binary which translates inputs to the correct Preprocessor method. For convenience, there is [an example no-op preprocessor](https://github.com/rust-lang/mdBook/blob/master/examples/nop-preprocessor.rs) in the examples/ directory which can easily be adapted for other preprocessors.
Example no-op preprocessor

### Example no-op preprocessor

- .aim/example/snippets/mdbook-plugin-nop-preprocessor.rs

### Hints For Implementing A Preprocessor

By pulling in mdbook as a library, preprocessors can have access to the existing infrastructure for dealing with books.

For example, a custom preprocessor could use the [`CmdPreprocessor::parse_input()`](https://docs.rs/mdbook/latest/mdbook/preprocess/trait.Preprocessor.html#method.parse_input) function to deserialize the JSON written to stdin. Then each chapter of the Book can be mutated in-place via Book::for_each_mut(), and then written to stdout with the serde_json crate.

Chapters can be accessed either directly (by recursively iterating over chapters) or via the [`Book::for_each_mut()`](https://docs.rs/mdbook/latest/mdbook/book/struct.Book.html#method.for_each_mut) convenience method.

The chapter.content is just a string which happens to be markdown. While it’s entirely possible to use regular expressions or do a manual find & replace, you’ll probably want to process the input into something more computer-friendly. The [pulldown-cmark](https://crates.io/crates/pulldown-cmark) crate implements a production-quality event-based Markdown parser, with the [pulldown-cmark-to-cmark](https://crates.io/crates/pulldown-cmark-to-cmark) crate allowing you to translate events back into markdown text.

The following code block shows how to remove all emphasis from markdown, without accidentally breaking the document.

- .aim/example/snippets/mdbook-plugin-fn-remove_emphasis.rs

For everything else, have a look at [the complete example](https://github.com/rust-lang/mdBook/blob/master/examples/nop-preprocessor.rs).

### Implementing a preprocessor with a different language

The fact that mdBook utilizes stdin and stdout to communicate with the preprocessors makes it easy to implement them in a language other than Rust. The following code shows how to implement a simple preprocessor in Python, which will modify the content of the first chapter. The example below follows the configuration shown above with `preprocessor.foo.command` actually pointing to a Python script.

- .aim/example/snippets/mdbook-plugin-preprocessor.py
