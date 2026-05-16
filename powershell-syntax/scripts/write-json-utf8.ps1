<#
.SYNOPSIS
    Write an object as UTF-8 JSON with no BOM. Safe for strict consumers.
.DESCRIPTION
    Wraps ConvertTo-Json with .NET WriteAllText using no-BOM UTF-8 encoding.
    Throws if the on-disk file has a BOM after the write (sanity check).

    Strict consumers that reject a leading UTF-8 BOM (0xEF 0xBB 0xBF):
      - Claude Desktop session JSON (Electron JSON.parse)
      - Node, browsers fetching JSON
      - jq, most line-oriented parsers

    PowerShell's own ConvertFrom-Json silently strips BOMs, so producer-side
    self-verification cannot catch this bug. Verify at the byte level (this
    function does) or with the actual consumer.

    Works on Windows PowerShell 5.1 and PowerShell 7.x.
.PARAMETER Object
    The object to serialize.
.PARAMETER Path
    Output file path (created or overwritten). Relative paths resolve
    against the current location.
.PARAMETER Depth
    ConvertTo-Json depth. Default 20.
.PARAMETER Compress
    Use compact JSON instead of indented.
.EXAMPLE
    Write-JsonUtf8 -Object @{ name = "test"; value = 1 } -Path .\out.json
.EXAMPLE
    Write-JsonUtf8 -Object $data -Path $path -Depth 30 -Compress
.NOTES
    Skill: powershell-syntax v1.3
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)] $Object,
    [Parameter(Mandatory=$true)] [string]$Path,
    [int]$Depth = 20,
    [switch]$Compress
)

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

    # Resolve to absolute path so .NET writes to the expected location
    $resolved = if ([System.IO.Path]::IsPathRooted($Path)) { $Path }
                else { Join-Path (Get-Location).Path $Path }

    [System.IO.File]::WriteAllText($resolved, $json, [System.Text.UTF8Encoding]::new($false))

    # Post-write sanity verify: no BOM on disk
    $bytes = [System.IO.File]::ReadAllBytes($resolved)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        throw "Write-JsonUtf8: BOM appeared in $resolved despite explicit no-BOM encoding. Investigate."
    }
}

# When invoked as a script (not dot-sourced), execute the bound parameters.
# When dot-sourced, only define the function for callers to use.
if ($MyInvocation.InvocationName -ne '.') {
    Write-JsonUtf8 -Object $Object -Path $Path -Depth $Depth -Compress:$Compress
}
