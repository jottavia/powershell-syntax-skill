# PowerShell Syntax Skill for Claude Code

A Claude Code skill providing verified PowerShell syntax patterns that compile and run correctly. Prevents common parse errors with arrays, hashtables, operators, conditionals, and more.

**Current version:** 1.3

## Install

Copy the skill directory to your project:

```bash
# Project scope (this project only)
cp -r powershell-syntax .claude/skills/

# Personal scope (all projects)
cp -r powershell-syntax ~/.claude/skills/
```

## Usage

Invoke manually:

```
/powershell-syntax
```

Set `disable-model-invocation: true` (default) to prevent auto-loading on every PowerShell file edit. Remove that line if you want Claude to load it automatically when writing `.ps1` files.

## What's Covered

- ASCII-only output enforcement (no em-dashes, en-dashes, curly quotes, ellipsis, right arrow, non-breaking spaces, zero-width spaces) with verification command
- Script headers and CmdletBinding
- Admin elevation pattern
- Variables, arrays (`@()`), hashtables (`@{}`)
- String expansion and interpolation
- Conditionals with correct operators (`-eq`, `-ne`, `-and`, not `==`, `!=`)
- Loops (foreach, ForEach-Object, for, while)
- Functions with param blocks and splatting
- Error handling (try/catch/finally)
- File and path operations
- **Encoding and BOM safety**: no-BOM UTF-8 writes for files consumed by Node, Electron, jq, browsers, Claude Desktop session JSON. Includes a `Write-JsonUtf8` helper (shipped at `scripts/write-json-utf8.ps1`) with post-write byte-level verification
- Registry operations
- Service and process management
- String manipulation
- Collections and pipeline
- Date formatting
- Common mistakes to avoid
- **Compress-Archive directory structure pitfall**: most common cause of broken zip releases

## Context Cost

- **With `disable-model-invocation: true`:** ~30 tokens (description only, loaded when you type `/powershell-syntax`)
- **Without:** ~400 lines loaded every time Claude writes PowerShell

## Changelog

### v1.3
- **File I/O - encoding and BOM safety**: new section warning against `Out-File -Encoding UTF8` and `Set-Content -Encoding UTF8` on Windows PowerShell 5.x for files consumed by strict parsers (Node, Electron `JSON.parse`, jq, browsers, Claude Desktop). PowerShell's own `ConvertFrom-Json` silently strips BOMs, so producer-side self-verification cannot catch the bug. Provides safe no-BOM patterns (`[IO.File]::WriteAllText` with `UTF8Encoding::new($false)`, `StreamWriter`, PS 7+ `utf8NoBOM`), a self-contained `Write-JsonUtf8` function readers can paste in, and a byte-level no-BOM verifier. Ships an executable copy at `powershell-syntax/scripts/write-json-utf8.ps1`. Motivated by a real session-recovery incident where Claude Desktop rejected a BOM-prefixed JSON file written by the previously-recommended `Set-Content -Encoding UTF8` pattern.
- ASCII-only table: added `U+2192` (right arrow `->`) and `U+200B` (zero-width space, delete) rows. Carried over from local pre-v1.3 edits.
- Frontmatter `description` extended to mention encoding/BOM safety so the skill description still matches when the topic comes up.

### v1.2
- Added ASCII-only section near top: documents Unicode-punctuation pitfalls (em-dashes, en-dashes, curly quotes, ellipsis, non-breaking spaces, zero-width spaces) and provides a `Select-String` verification command for `.ps1`/`.psm1` files. Aligns with framework's Tenet 10 (ASCII Only). Em-dashes scrubbed from skill doc headings.

### v1.1
- Added `Compress-Archive` directory structure section: documents the flatten-paths pitfall, shows correct staging pattern, and verification step

### v1.0
- Initial release with core syntax patterns

## License

MIT
