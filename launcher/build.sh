#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
APP_NAME="86BB Launcher"
APP_BUNDLE="$PROJECT_ROOT/$APP_NAME.app"

# Homebrew Python (requires: brew install python-tk@3.14)
PYTHON="$(which python3)"

# ---- create .app bundle structure ------------------------------------------
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# ---- Info.plist ------------------------------------------------------------
cat > "$APP_BUNDLE/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>86BB Launcher</string>
  <key>CFBundleIdentifier</key>
  <string>org.86bb.launcher</string>
  <key>CFBundleVersion</key>
  <string>0.1.0</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleExecutable</key>
  <string>launch</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSUIElement</key>
  <false/>
</dict>
</plist>
PLIST

# ---- executable (thin shell wrapper) ---------------------------------------
cat > "$APP_BUNDLE/Contents/MacOS/launch" << LAUNCHER
#!/usr/bin/env bash
exec "$PYTHON" "$SCRIPT_DIR/launcher.py"
LAUNCHER
chmod +x "$APP_BUNDLE/Contents/MacOS/launch"

# ---- strip quarantine ------------------------------------------------------
xattr -cr "$APP_BUNDLE" 2>/dev/null || true

echo ""
echo "Done!  $APP_NAME.app is at:"
echo "  $APP_BUNDLE"
echo ""
echo "Double-click it in Finder to launch."
