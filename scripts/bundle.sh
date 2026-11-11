#!/bin/bash
# Builds build/ezread.app from a release compile.
set -euo pipefail

cd "$(dirname "$0")/.."

# Homebrew builds inside its own sandbox, and SwiftPM's sandbox cannot nest in it.
swift build -c release --disable-sandbox
BIN="$(swift build -c release --disable-sandbox --show-bin-path)"

APP=build/ezread.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/web"

cp "$BIN/EzreadApp" "$APP/Contents/MacOS/EzreadApp"
cp "$BIN/ezread-cli" "$APP/Contents/MacOS/ezread"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/ezread.icns "$APP/Contents/Resources/ezread.icns"
cp Resources/page.html Resources/reader.css Resources/reader.js "$APP/Contents/Resources/web/"
cp -R Resources/vendor "$APP/Contents/Resources/web/vendor"

strip -x "$APP/Contents/MacOS/EzreadApp" "$APP/Contents/MacOS/ezread"
codesign --force --deep --sign - "$APP"

echo "$APP"
