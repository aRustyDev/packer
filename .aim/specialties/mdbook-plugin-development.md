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

```rust
// nop-preprocessors.rs

use crate::nop_lib::Nop;
use clap::{App, Arg, ArgMatches};
use mdbook::book::Book;
use mdbook::errors::Error;
use mdbook::preprocess::{CmdPreprocessor, Preprocessor, PreprocessorContext};
use semver::{Version, VersionReq};
use std::io;
use std::process;

pub fn make_app() -> App<'static> {
    App::new("nop-preprocessor")
        .about("A mdbook preprocessor which does precisely nothing")
        .subcommand(
            App::new("supports")
                .arg(Arg::new("renderer").required(true))
                .about("Check whether a renderer is supported by this preprocessor"),
        )
}

fn main() {
    let matches = make_app().get_matches();

    // Users will want to construct their own preprocessor here
    let preprocessor = Nop::new();

    if let Some(sub_args) = matches.subcommand_matches("supports") {
        handle_supports(&preprocessor, sub_args);
    } else if let Err(e) = handle_preprocessing(&preprocessor) {
        eprintln!("{}", e);
        process::exit(1);
    }
}

fn handle_preprocessing(pre: &dyn Preprocessor) -> Result<(), Error> {
    let (ctx, book) = CmdPreprocessor::parse_input(io::stdin())?;

    let book_version = Version::parse(&ctx.mdbook_version)?;
    let version_req = VersionReq::parse(mdbook::MDBOOK_VERSION)?;

    if !version_req.matches(&book_version) {
        eprintln!(
            "Warning: The {} plugin was built against version {} of mdbook, \
             but we're being called from version {}",
            pre.name(),
            mdbook::MDBOOK_VERSION,
            ctx.mdbook_version
        );
    }

    let processed_book = pre.run(&ctx, book)?;
    serde_json::to_writer(io::stdout(), &processed_book)?;

    Ok(())
}

fn handle_supports(pre: &dyn Preprocessor, sub_args: &ArgMatches) -> ! {
    let renderer = sub_args.value_of("renderer").expect("Required argument");
    let supported = pre.supports_renderer(renderer);

    // Signal whether the renderer is supported by exiting with 1 or 0.
    if supported {
        process::exit(0);
    } else {
        process::exit(1);
    }
}

/// The actual implementation of the `Nop` preprocessor. This would usually go
/// in your main `lib.rs` file.
mod nop_lib {
    use super::*;

    /// A no-op preprocessor.
    pub struct Nop;

    impl Nop {
        pub fn new() -> Nop {
            Nop
        }
    }

    impl Preprocessor for Nop {
        fn name(&self) -> &str {
            "nop-preprocessor"
        }

        fn run(&self, ctx: &PreprocessorContext, book: Book) -> Result<Book, Error> {
            // In testing we want to tell the preprocessor to blow up by setting a
            // particular config value
            if let Some(nop_cfg) = ctx.config.get_preprocessor(self.name()) {
                if nop_cfg.contains_key("blow-up") {
                    anyhow::bail!("Boom!!1!");
                }
            }

            // we *are* a no-op preprocessor after all
            Ok(book)
        }

        fn supports_renderer(&self, renderer: &str) -> bool {
            renderer != "not-supported"
        }
    }

    #[cfg(test)]
    mod test {
        use super::*;

        #[test]
        fn nop_preprocessor_run() {
            let input_json = r##"[
                {
                    "root": "/path/to/book",
                    "config": {
                        "book": {
                            "authors": ["AUTHOR"],
                            "language": "en",
                            "multilingual": false,
                            "src": "src",
                            "title": "TITLE"
                        },
                        "preprocessor": {
                            "nop": {}
                        }
                    },
                    "renderer": "html",
                    "mdbook_version": "0.4.21"
                },
                {
                    "sections": [
                        {
                            "Chapter": {
                                "name": "Chapter 1",
                                "content": "# Chapter 1\n",
                                "number": [1],
                                "sub_items": [],
                                "path": "chapter_1.md",
                                "source_path": "chapter_1.md",
                                "parent_names": []
                            }
                        }
                    ],
                    "__non_exhaustive": null
                }
            ]"##;
            let input_json = input_json.as_bytes();

            let (ctx, book) = mdbook::preprocess::CmdPreprocessor::parse_input(input_json).unwrap();
            let expected_book = book.clone();
            let result = Nop::new().run(&ctx, book);
            assert!(result.is_ok());

            // The nop-preprocessor should not have made any changes to the book content.
            let actual_book = result.unwrap();
            assert_eq!(actual_book, expected_book);
        }
    }
}
```

### Hints For Implementing A Preprocessor

By pulling in mdbook as a library, preprocessors can have access to the existing infrastructure for dealing with books.

For example, a custom preprocessor could use the [`CmdPreprocessor::parse_input()`](https://docs.rs/mdbook/latest/mdbook/preprocess/trait.Preprocessor.html#method.parse_input) function to deserialize the JSON written to stdin. Then each chapter of the Book can be mutated in-place via Book::for_each_mut(), and then written to stdout with the serde_json crate.

Chapters can be accessed either directly (by recursively iterating over chapters) or via the [`Book::for_each_mut()`](https://docs.rs/mdbook/latest/mdbook/book/struct.Book.html#method.for_each_mut) convenience method.

The chapter.content is just a string which happens to be markdown. While it’s entirely possible to use regular expressions or do a manual find & replace, you’ll probably want to process the input into something more computer-friendly. The [pulldown-cmark](https://crates.io/crates/pulldown-cmark) crate implements a production-quality event-based Markdown parser, with the [pulldown-cmark-to-cmark](https://crates.io/crates/pulldown-cmark-to-cmark) crate allowing you to translate events back into markdown text.

The following code block shows how to remove all emphasis from markdown, without accidentally breaking the document.

```rust
fn remove_emphasis(
num_removed_items: &mut usize,
chapter: &mut Chapter,
) -> Result<String> {
let mut buf = String::with_capacity(chapter.content.len());

    let events = Parser::new(&chapter.content).filter(|e| {
        let should_keep = match *e {
            Event::Start(Tag::Emphasis)
            | Event::Start(Tag::Strong)
            | Event::End(Tag::Emphasis)
            | Event::End(Tag::Strong) => false,
            _ => true,
        };
        if !should_keep {
            *num_removed_items += 1;
        }
        should_keep
    });

    cmark(events, &mut buf, None).map(|_| buf).map_err(|err| {
        Error::from(format!("Markdown serialization failed: {}", err))
    })

}
```

For everything else, have a look at [the complete example](https://github.com/rust-lang/mdBook/blob/master/examples/nop-preprocessor.rs).

### Implementing a preprocessor with a different language

The fact that mdBook utilizes stdin and stdout to communicate with the preprocessors makes it easy to implement them in a language other than Rust. The following code shows how to implement a simple preprocessor in Python, which will modify the content of the first chapter. The example below follows the configuration shown above with `preprocessor.foo.command` actually pointing to a Python script.

```python
import json
import sys

if **name** == '**main**':
if len(sys.argv) > 1: # we check if we received any argument
if sys.argv[1] == "supports": # then we are good to return an exit status code of 0, since the other argument will just be the renderer's name
sys.exit(0)

    # load both the context and the book representations from stdin
    context, book = json.load(sys.stdin)
    # and now, we can just modify the content of the first chapter
    book['sections'][0]['Chapter']['content'] = '# Hello'
    # we are done with the book's modification, we can just print it to stdout,
    print(json.dumps(book))

```
