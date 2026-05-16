---
name: powershell-syntax
description: Proven PowerShell syntax patterns that compile and run correctly. Use this skill whenever writing, editing, or reviewing PowerShell (.ps1, .psm1) scripts, Windows automation, admin scripts, registry/service/process code, or any code block tagged `powershell`. Consult before writing PowerShell to avoid common syntax errors (array/hashtable `@`, `if ()` parens, operator form `-eq`/`-and`, try/catch, splatting), ASCII-only output enforcement, and encoding/BOM safety for files consumed by strict parsers (Node, Electron, jq, browsers).
disable-model-invocation: true
version: "1.3"
---

# PowerShell Syntax Reference

Verified patterns. Use these verbatim; deviations below cause parse or runtime errors.

## ASCII only - no em-dashes anywhere

Claude must not emit em-dashes, en-dashes, curly quotes, ellipsis, non-breaking spaces, or any non-ASCII punctuation. This is a global output rule (see framework `CLAUDE.md`); PowerShell makes it especially load-bearing because Unicode in `.ps1`/`.psm1` files causes:

- Parse errors when the file is saved without a BOM
- Inconsistent behavior across PowerShell 5.1 vs 7.x
- Silent breakage of string comparisons that look identical but are not byte-identical

| Wrong (Unicode) | Right (ASCII) |
|:--|:--|
| em-dash `U+2014` | ` - ` or `--` |
| en-dash `U+2013` | `-` |
| curly quotes `U+201C` `U+201D` `U+2018` `U+2019` | `"` `'` |
| ellipsis `U+2026` | `...` |
| right arrow `U+2192` | `->` |
| non-breaking space `U+00A0` | regular space |
| zero-width space `U+200B` | (delete) |

Verify a file is clean:

```powershell
Get-Content .\script.ps1 | Select-String -Pattern '[^\x00-\x7F]'  # empty = clean
```

## Script header
```powershell
<#
.SYNOPSIS  Brief
.DESCRIPTION  Detail
.NOTES  Version
#>
[CmdletBinding()]
param(
    [string[]]$ArrayParam = @(),
    [string]$StringParam = 'Default'
)
```

## Admin elevation
```powershell
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $MyInvocation.MyCommand.Path)
    exit
}
```

## Variables, arrays, hashtables
```powershell
$s = "text"; $n = 123; $b = $true; $x = $null
$arr = @("a","b","c")            # MUST use @() for arrays
$empty = @()
$list = [System.Collections.ArrayList]@()
$h = @{ Key1 = "v"; Key2 = 2 }   # MUST use @{} for hashtables
$nested = @{ Outer = @{ Inner = "v" }; Arr = @("a","b") }

# String expansion
"Hello $name, $(Get-Date)"        # double quotes expand
"Result: $($obj.Property)"        # subexpression for member access
'Literal $var'                    # single quotes do NOT expand
```

## Conditionals
```powershell
if ($c -eq $true) { } elseif ($c2) { } else { }
if (($a -eq "x") -and ($b -gt 10)) { }
if (Test-Path $p) { }
if (-not (Test-Path $p)) { }
```

Operators (word form only, never `==`/`!=`/`>`/`<`):
`-eq -ne -gt -lt -ge -le -like -match -contains -in -and -or -not`

## Loops
```powershell
foreach ($item in $coll) { }
foreach ($k in $h.Keys) { $v = $h[$k] }
$coll | ForEach-Object { $_ }
for ($i = 0; $i -lt $arr.Count; $i++) { }
while ($c) { }
```

## Functions
```powershell
function Verb-Noun {
    param(
        [Parameter(Mandatory=$true)][string]$Required,
        [int]$Optional = 10,
        [switch]$Flag
    )
    try { return $result } catch { Write-Error "Failed: $_"; throw }
}

# Splatting
$p = @{ Required = "v"; Optional = 20 }
Verb-Noun @p
```

## Error handling
```powershell
try {
    Some-Command -ErrorAction Stop
} catch [System.IO.FileNotFoundException] {
    # typed catch (optional)
} catch {
    Write-Error "Failed: $_"        # or $($_.Exception.Message)
} finally {
    # cleanup
}
```

## Files and paths
```powershell
$full = Join-Path $base $name
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

Copy-Item -Path $src -Destination $dst -Force
Remove-Item -Path $p -Recurse -Force
```

For reads, writes, and JSON, see the next section. Do NOT use `Out-File -Encoding UTF8` or `Set-Content -Encoding UTF8` for files another process will parse.

## File I/O - encoding and BOM safety

PowerShell on Windows has default patterns that write a UTF-8 BOM (bytes `0xEF 0xBB 0xBF`). Strict consumers reject a leading BOM: Claude Desktop session JSON (Electron `JSON.parse`), Node, browsers fetching JSON, `jq`, most line-oriented parsers. PowerShell's own `ConvertFrom-Json` silently strips BOMs, so producer-side self-verification CANNOT catch this bug. You must verify at the byte level or with the actual consumer.

### Reads (no encoding problem)
```powershell
$content = Get-Content $path -Raw                # default; OK for most reads
$content = Get-Content $path -Raw -Encoding UTF8 # explicit; OK
$bytes   = [System.IO.File]::ReadAllBytes($path) # for byte-level inspection
$obj     = Get-Content $path -Raw | ConvertFrom-Json   # silently strips BOM; do not rely on this for verification
```

### Writes: BOM-introducing patterns to AVOID on PowerShell 5.x
```powershell
# DO NOT use these for files another process will parse:
$data    | Out-File $path -Encoding UTF8                  # writes BOM
$data    | ConvertTo-Json | Out-File $path -Encoding UTF8 # writes BOM
$content | Set-Content $path -Encoding UTF8               # writes BOM
$content | Add-Content $path -Encoding UTF8               # may write BOM on first write
$data > $path                                             # depends on $OutputEncoding; default profile often UTF-16
```

### Writes: safe no-BOM patterns
```powershell
# Pattern A: .NET WriteAllText with explicit no-BOM UTF-8 (works on PS 5.1 and 7.x)
[System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))

# Pattern B: StreamWriter for line-by-line or streaming writes (works on PS 5.1 and 7.x)
$writer = [System.IO.StreamWriter]::new($path, $false, [System.Text.UTF8Encoding]::new($false))
try {
    foreach ($line in $lines) { $writer.WriteLine($line) }
} finally { $writer.Close() }

# Pattern C: PowerShell 7+ only - explicit no-BOM
$data    | Out-File   -FilePath $path -Encoding utf8NoBOM
$content | Set-Content -Path    $path -Encoding utf8NoBOM
```

### JSON-write helper (self-contained)

Paste this function into your script. It is also shipped alongside this skill at `scripts/write-json-utf8.ps1`:

```powershell
function Write-JsonUtf8 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] $Object,
        [Parameter(Mandatory=$true)] [string]$Path,
        [int]$Depth = 20,
        [switch]$Compress
    )
    $json = if ($Compress) { $Object | ConvertTo-Json -Depth $Depth -Compress }
            else           { $Object | ConvertTo-Json -Depth $Depth }
    [System.IO.File]::WriteAllText($Path, $json, [System.Text.UTF8Encoding]::new($false))
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        throw "Write-JsonUtf8: BOM appeared in $Path despite explicit no-BOM encoding. Investigate."
    }
}

Write-JsonUtf8 -Object $data -Path $path -Depth 20
```

### Verifying a file has no BOM
```powershell
$bytes = [System.IO.File]::ReadAllBytes($path)
$hasBom = ($bytes.Length -ge 3) -and ($bytes[0] -eq 0xEF) -and ($bytes[1] -eq 0xBB) -and ($bytes[2] -eq 0xBF)
# $hasBom -eq $false means safe
```

### When to use which encoding

| Target consumer | Safe encoding | Why |
|:--|:--|:--|
| Claude Desktop session JSON | UTF-8 no BOM | Electron `JSON.parse` rejects BOM |
| `.ps1` script for re-execution with non-ASCII | UTF-8 with BOM (or pure ASCII; prefer ASCII per framework Tenet 10) | PS 5.1 mis-parses non-ASCII without BOM |
| `.md` / `.txt` for humans | UTF-8 no BOM | Modern editors prefer no BOM |
| `.jsonl` for Node / jq | UTF-8 no BOM | Strict line-parsers reject BOM |
| `.csv` for Excel | UTF-8 with BOM | Excel uses BOM to detect UTF-8 |
| Any file Claude Code or other Node tooling reads | UTF-8 no BOM | Node JSON parsers reject BOM |

### Rule of thumb

If another process will parse the file: **no BOM**. PowerShell as a writer needs to be told explicitly.

## Registry
```powershell
$rp = "HKLM:\SOFTWARE\Path"
if (-not (Test-Path $rp)) { New-Item -Path $rp -Force | Out-Null }
Set-ItemProperty -Path $rp -Name "N" -Value "v" -Type String
Set-ItemProperty -Path $rp -Name "N" -Value 1 -Type DWord
Set-ItemProperty -Path $rp -Name "N" -Value ([byte[]](1,2,3)) -Type Binary
Set-ItemProperty -Path $rp -Name "N" -Value @("a","b") -Type MultiString
$v = Get-ItemProperty -Path $rp -Name "N" -ErrorAction SilentlyContinue
```

Types: `String`, `DWord`, `Binary`, `MultiString`, `ExpandString`, `QWord`.

## Services and processes
```powershell
$svc = Get-Service -Name "N" -ErrorAction SilentlyContinue
if ($svc -and $svc.Status -eq 'Running') { }
Start-Service -Name "N" -ErrorAction SilentlyContinue
Stop-Service -Name "N" -Force -ErrorAction SilentlyContinue
Set-Service -Name "N" -StartupType Disabled

$proc = Start-Process -FilePath "p.exe" -ArgumentList "/silent" -Wait -PassThru
if ($proc.ExitCode -eq 0) { }
Stop-Process -Name "N" -Force -ErrorAction SilentlyContinue
```

## Strings
```powershell
"{0} = {1}" -f $a, $b
$s -replace "old","new"
$s -split ","                  # or $s.Split(",")
$arr -join ","
$s.Trim(); $s.ToUpper(); $s.ToLower()
```

## Collections / pipeline
```powershell
$coll | Select-Object Name, Value
$coll | Where-Object { $_.Prop -eq "v" }
$coll | Where-Object Prop -eq "v"
$coll | Sort-Object Name -Descending
$coll | Group-Object Name
($coll | Measure-Object).Count
($coll | Measure-Object -Property N -Sum).Sum

$list = [System.Collections.ArrayList]@()
$list.Add("x") | Out-Null         # suppress index return
$arr += "x"                       # creates new array (slow in loops)
$arr[0]; $arr[-1]; $arr[1..3]
```

## Dates
```powershell
Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'    # filename-safe
(Get-Date).AddDays(-7)
```

## Output
```powershell
Write-Host "msg" -ForegroundColor Green    # console only, not pipeline
Write-Output $data                          # pipeline
Write-Error "e"; Write-Warning "w"; Write-Verbose "v"

$here = @"
multi-line
$variable expands
"@
```

## Do not do this
```powershell
$a = ("x","y")          # WRONG - missing @, becomes a scalar string in some contexts
$h = { K = "v" }        # WRONG - this is a scriptblock, not a hashtable
if $c { }               # WRONG - condition needs parens
$a == $b                # WRONG - use -eq
$a != $b                # WRONG - use -ne
"$var+text"             # ambiguous - use "${var}+text" or "$var text"
Get-ChildItem /Path     # prefer named params: -Path
```

## Param style
Always hyphenated named parameters (`-Path`, `-Recurse`). Splat hashtables for 3+ params:
```powershell
$p = @{ Path = "C:\"; Filter = "*.txt"; Recurse = $true }
Get-ChildItem @p
```

## Compress-Archive: directory structure pitfall

`Compress-Archive` FLATTENS paths when given a file list. This is the single most common source of broken zips.

### Wrong - produces a flat zip
```powershell
# Files end up at zip root with NO directory structure
Compress-Archive -Path "CLAUDE.md", ".claude/settings.json", ".claude/skills/foo/SKILL.md" `
                 -DestinationPath out.zip
```

When extracted, the user sees `CLAUDE.md`, `settings.json`, `SKILL.md` all in one flat directory. The `.claude/skills/foo/` hierarchy is GONE.

### Right - stage first, then compress
```powershell
$staging = Join-Path $env:TEMP "stage-$(Get-Random)"
New-Item -ItemType Directory -Path $staging -Force | Out-Null

# Recreate the directory structure inside staging
foreach ($file in $fileList) {
    $dest = Join-Path $staging $file
    $destDir = Split-Path $dest -Parent
    if (!(Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    Copy-Item $file $dest
}

# Compress the staging dir - paths preserved
Compress-Archive -Path "$staging\*" -DestinationPath out.zip -Force

# Cleanup
Remove-Item $staging -Recurse -Force
```

### Verify before shipping
```powershell
# Always check structure after building
Expand-Archive -Path out.zip -DestinationPath verify-tmp -Force
Get-ChildItem verify-tmp -Recurse -Name | Sort-Object
Remove-Item verify-tmp -Recurse -Force
```

If you see `SKILL.md` at the root instead of `.claude/skills/foo/SKILL.md`, you flattened.

**Alternative - use tar (Windows 10+):** `tar -cf out.zip --format=zip ...` preserves paths natively, but its archive flag semantics differ from Compress-Archive. Use `Compress-Archive` with proper staging for portability.
