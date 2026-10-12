#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
task_flutter_version="$(node -p "require('./toolchain.json').flutterVersion")"
task_flutter_revision="$(node -p "require('./toolchain.json').flutterRevision")"
task_sdk="$PWD/.tools/flutter"

if [[ ! -d "$task_sdk" ]]; then
  mkdir -p .tools
  git clone --depth 1 --branch "$task_flutter_version" \
    https://github.com/flutter/flutter.git "$task_sdk"
fi

if [[ "$(git -C "$task_sdk" rev-parse HEAD)" != "$task_flutter_revision" ]]; then
  echo 'Flutter SDK does not match toolchain.json.' >&2
  exit 1
fi

export PATH="$task_sdk/bin:$PATH"
export PUB_CACHE="$PWD/.tools/pub-cache"
export FLUTTER_SUPPRESS_ANALYTICS=true

flutter --version
flutter pub get --enforce-lockfile
dart run tool/build_web.dart
