#!/bin/bash
# Builds build/zread.app from a release compile.
set -euo pipefail

cd "$(dirname "$0")/.."

# Homebrew builds inside its own sandbox, and SwiftPM's sandbox cannot nest in it.
swift build -c release --disable-sandbox
BIN="$(swift build -c release --disable-sandbox --show-bin-path)"

APP=build/zread.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/web"

cp "$BIN/ZreadApp" "$APP/Contents/MacOS/ZreadApp"
cp "$BIN/zread-cli" "$APP/Contents/MacOS/zread"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/zread.icns "$APP/Contents/Resources/zread.icns"
cp Resources/page.html Resources/reader.css Resources/reader.js "$APP/Contents/Resources/web/"
cp -R Resources/vendor "$APP/Contents/Resources/web/vendor"

strip -x "$APP/Contents/MacOS/ZreadApp" "$APP/Contents/MacOS/zread"
codesign --force --deep --sign - "$APP"

echo "$APP"
