$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskFlutter = Join-Path $taskRoot '.tools/flutter/bin/flutter.bat'
if (-not (Test-Path -LiteralPath $taskFlutter)) {
    $taskInstalled = Get-Command flutter -ErrorAction SilentlyContinue
    if (-not $taskInstalled) { throw 'Run tool/bootstrap.ps1 or install the pinned Flutter SDK first.' }
    $taskFlutter = $taskInstalled.Source
}
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:PUB_CACHE = Join-Path $taskRoot '.tools/pub-cache'
& $taskFlutter @args
exit $LASTEXITCODE
