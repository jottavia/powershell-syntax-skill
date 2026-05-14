# PowerShell Syntax Skill for Claude Code

A Claude Code skill providing verified PowerShell syntax patterns that compile and run correctly. Prevents common parse errors with arrays, hashtables, operators, conditionals, and more.

**Current version:** 1.2

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

- ASCII-only output enforcement (no em-dashes, en-dashes, curly quotes, ellipsis, non-breaking spaces) with verification command
- Script headers and CmdletBinding
- Admin elevation pattern
- Variables, arrays (`@()`), hashtables (`@{}`)
- String expansion and interpolation
- Conditionals with correct operators (`-eq`, `-ne`, `-and`, not `==`, `!=`)
- Loops (foreach, ForEach-Object, for, while)
- Functions with param blocks and splatting
- Error handling (try/catch/finally)
- File and path operations
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

### v1.2
- Added ASCII-only section near top: documents Unicode-punctuation pitfalls (em-dashes, en-dashes, curly quotes, ellipsis, non-breaking spaces, zero-width spaces) and provides a `Select-String` verification command for `.ps1`/`.psm1` files. Aligns with framework's Tenet 10 (ASCII Only). Em-dashes scrubbed from skill doc headings.

### v1.1
- Added `Compress-Archive` directory structure section: documents the flatten-paths pitfall, shows correct staging pattern, and verification step

### v1.0
- Initial release with core syntax patterns

## License

MIT
