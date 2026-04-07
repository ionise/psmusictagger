# Markdown Style Guide

When producing Markdown documents follow this guide.

This document defines the markdown formatting rules enforced in this project via [markdownlint](https://github.com/DavidAnson/markdownlint).

## Configuration

Rules are configured in `.markdownlint.json` at the repository root.

## Enabled Rules

The following rules are enforced:

| Rule | Alias | Description |
|------|-------|-------------|
| MD001 | heading-increment | Heading levels should only increment by one level at a time |
| MD003 | heading-style | Heading style should be consistent (ATX style with `#`) |
| MD004 | ul-style | Unordered list style should be consistent (use `-`) |
| MD005 | list-indent | Consistent indentation for list items at the same level |
| MD007 | ul-indent | Unordered list indentation |
| MD009 | no-trailing-spaces | No trailing spaces at end of lines |
| MD010 | no-hard-tabs | No hard tabs (use spaces) |
| MD011 | no-reversed-links | No reversed link syntax `(text)[url]` |
| MD012 | no-multiple-blanks | No multiple consecutive blank lines |
| MD014 | commands-show-output | Dollar signs used before commands without showing output |
| MD018 | no-missing-space-atx | Space required after hash on ATX style heading |
| MD019 | no-multiple-space-atx | No multiple spaces after hash on ATX style heading |
| MD022 | blanks-around-headings | Headings should be surrounded by blank lines |
| MD023 | heading-start-left | Headings must start at the beginning of the line |
| MD024 | no-duplicate-heading | No multiple headings with the same content |
| MD025 | single-title | Single top-level heading (H1) per document |
| MD026 | no-trailing-punctuation | No trailing punctuation in headings |
| MD027 | no-multiple-space-blockquote | No multiple spaces after blockquote symbol |
| MD028 | no-blanks-blockquote | No blank line inside blockquote |
| MD029 | ol-prefix | Ordered list item prefix should be consistent |
| MD030 | list-marker-space | Spaces after list markers |
| MD031 | blanks-around-fences | Fenced code blocks should be surrounded by blank lines |
| MD032 | blanks-around-lists | Lists should be surrounded by blank lines |
| MD034 | no-bare-urls | No bare URLs (use `<url>` or `[text](url)`) |
| MD035 | hr-style | Horizontal rule style should be consistent |
| MD036 | no-emphasis-as-heading | No emphasis used instead of a heading |
| MD037 | no-space-in-emphasis | No spaces inside emphasis markers |
| MD038 | no-space-in-code | No spaces inside code span elements |
| MD039 | no-space-in-links | No spaces inside link text |
| MD040 | fenced-code-language | Fenced code blocks should have a language specified |
| MD041 | first-line-heading | First line should be a top-level heading |
| MD042 | no-empty-links | No empty links |
| MD044 | proper-names | Proper names should have correct capitalization |
| MD045 | no-alt-text | Images should have alternate text |
| MD046 | code-block-style | Code block style should be consistent |
| MD047 | single-trailing-newline | Files should end with a single newline character |
| MD048 | code-fence-style | Code fence style should be consistent |
| MD049 | emphasis-style | Emphasis style should be consistent |
| MD050 | strong-style | Strong style should be consistent |
| MD051 | link-fragments | Link fragments should be valid |
| MD052 | reference-links-images | Reference links and images should use defined labels |
| MD053 | link-image-reference-definitions | Link and image reference definitions should be needed |
| MD054 | link-image-style | Link and image style |
| MD055 | table-pipe-style | Table pipe style |
| MD056 | table-column-count | Table column count |
| MD058 | blanks-around-tables | Tables should be surrounded by blank lines |

## Disabled Rules

The following rules are disabled in `.markdownlint.json`:

| Rule | Alias | Reason |
|------|-------|--------|
| MD013 | line-length | 80-character limit is too restrictive for documentation prose |
| MD033 | no-inline-html | HTML is occasionally needed for advanced formatting |
| MD060 | table-column-style | Compact table formatting is acceptable |

## Common Patterns

### Code Blocks

Always specify a language for fenced code blocks:

````markdown
```powershell
Get-BeatportArtist -ArtistId 123
```
````

For ASCII diagrams or plain text output, use `text`:

````markdown
```text
┌─────────────────┐
│  Architecture   │
└─────────────────┘
```
````

### Lists

Always include a blank line before and after lists:

```markdown
Some introductory text.

- Item one
- Item two
- Item three

Following paragraph.
```

### Headings

Always include a blank line after headings:

```markdown
## Section Title

Content goes here.
```

Headings should increment by one level only:

```markdown
# Title
## Section
### Subsection
```

Not:

```markdown
# Title
### Skipped to H3 (wrong!)
```

## Running the Linter

```bash
# Check all markdown files
npx markdownlint-cli2 "**/*.md" "#node_modules"

# Check specific file
npx markdownlint-cli2 "README.md"
```

## References

- [markdownlint Rules Documentation](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md)
- [markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2)
