use mdbook::book::{Book, BookItem};
use mdbook::errors::Error;
use mdbook::preprocess::{Preprocessor, PreprocessorContext};
use serde::Deserialize;
use std::fs;

#[derive(Deserialize)]
struct JsonTable {
    columns: Vec<String>,
    rows: Vec<serde_json::Value>,
}

pub struct JsonTablePre;

impl Preprocessor for JsonTablePre {
    fn name(&self) -> &str { "json-table-pre" }

    fn run(&self, _ctx: &PreprocessorContext, mut book: Book) -> Result<Book, Error> {
        for section in &mut book.sections {
            if let BookItem::Chapter(ch) = section {
                if ch.content.contains("{{json-table") {
                    // Extract path (simple parse, improve with regex)
                    if let Some(start) = ch.content.find("path=\"") {
                        let end = ch.content[start+6..].find('"').unwrap() + start + 6;
                        let path = &ch.content[start+6..end];
                        let raw = fs::read_to_string(path)?;
                        let parsed: JsonTable = serde_json::from_str(&raw)?;
                        let mut table = String::new();
                        // Build Markdown table
                        table.push('|');
                        for c in &parsed.columns { table.push_str(c); table.push('|'); }
                        table.push('\n');
                        table.push('|');
                        for _ in &parsed.columns { table.push_str("---|"); }
                        table.push('\n');
                        for row in parsed.rows.iter() {
                            table.push('|');
                            for c in &parsed.columns {
                                let cell = row.get(c).map(|v| v.to_string()).unwrap_or("".into());
                                table.push_str(&cell.trim_matches('"'));
                                table.push('|');
                            }
                            table.push('\n');
                        }
                        ch.content = ch.content.replace(
                            &format!("{{{{json-table path=\"{}\"}}}}", path),
                            &table
                        );
                    }
                }
            }
        }
        Ok(book)
    }

    fn supports_renderer(&self, _name: &str) -> bool { true }
}

fn main() {
    let pre = JsonTablePre;
    mdbook::preprocess::main(pre).unwrap();
}
