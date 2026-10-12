$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskPin = Get-Content -LiteralPath (Join-Path $taskRoot 'toolchain.json') -Raw | ConvertFrom-Json
$taskSdk = Join-Path $taskRoot '.tools/flutter'
if (-not (Test-Path -LiteralPath $taskSdk)) {
    New-Item -ItemType Directory -Force (Join-Path $taskRoot '.tools') | Out-Null
    & git -c core.longpaths=true clone --depth 1 --branch $taskPin.flutterVersion https://github.com/flutter/flutter.git $taskSdk
    if ($LASTEXITCODE -ne 0) { throw 'Flutter SDK checkout failed.' }
}
$taskRevision = & git -C $taskSdk rev-parse HEAD
if ($LASTEXITCODE -ne 0 -or $taskRevision -ne $taskPin.flutterRevision) {
    throw 'The local Flutter SDK does not match toolchain.json. Keep the pinned SDK or update the pin deliberately.'
}
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:PUB_CACHE = Join-Path $taskRoot '.tools/pub-cache'
& (Join-Path $taskSdk 'bin/flutter.bat') --version
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Push-Location $taskRoot
try {
    & (Join-Path $taskSdk 'bin/flutter.bat') pub get
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally { Pop-Location }
