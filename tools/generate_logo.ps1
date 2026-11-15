# Asks for the OpenAI key without showing it, keeps it in this process only and makes
# logo candidates with generate_logo.py (see docs/ARTWORK.md). The key is never written
# to disk and is removed from the environment when the script ends.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\generate_logo.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\generate_logo.ps1 -Count 2 -Variants grid
param(
    [int]$Count = 4,
    [string[]]$Variants = @('grid', 'orbit'),
    [string]$Model = ''
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$hadKey = [bool]$env:OPENAI_API_KEY

if (-not $hadKey) {
    $secure = Read-Host -AsSecureString 'OpenAI API key (input stays hidden)'
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { $env:OPENAI_API_KEY = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
    if (-not $env:OPENAI_API_KEY) { throw 'No key entered.' }
}

try {
    foreach ($variant in $Variants) {
        Write-Host "Making $Count '$variant' candidates ..."
        $pyArgs = @("$root\tools\generate_logo.py", '--variant', $variant, '--count', "$Count")
        if ($Model) { $pyArgs += @('--model', $Model) }
        & python @pyArgs
        if ($LASTEXITCODE -ne 0) { throw "generate_logo.py stopped on '$variant'." }
    }
    Write-Host 'Done. The candidates are in dist\logo.'
}
finally {
    if (-not $hadKey) { Remove-Item Env:\OPENAI_API_KEY -ErrorAction SilentlyContinue }
}
