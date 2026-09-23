#!/usr/bin/env bash
set -euo pipefail
[[ "$(uname -s)" == Darwin ]] || { echo "This script requires macOS and Xcode/Command Line Tools." >&2; exit 2; }
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
rm -rf dist .build/x86_64-apple-macosx
swift build -c release --triple x86_64-apple-macosx13.0
APP="dist/Mac File Search.app"; mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/x86_64-apple-macosx/release/MacFileSearch "$APP/Contents/MacOS/MacFileSearch"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>MacFileSearch</string><key>CFBundleIdentifier</key><string>local.macfilesearch.app</string>
<key>CFBundleName</key><string>Mac File Search</string><key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string><key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --deep --sign - "$APP"
ditto -c -k --keepParent "$APP" dist/Mac-File-Search-macOS-x86_64.zip
file "$APP/Contents/MacOS/MacFileSearch"; codesign --verify --deep --strict "$APP"
echo "Created $APP and dist/Mac-File-Search-macOS-x86_64.zip"
