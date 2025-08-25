#!/usr/bin/env bash
set -euo pipefail

# Remove stale DMG staging directory
rm -rf publish/dmg_temp

# Initial cleanup of resource forks and attributes

# Initial cleanup of resource forks and attributes
if command -v dot_clean >/dev/null 2>&1; then
  dot_clean -f -m publish/BlinkApp.app 2>/dev/null || true
  dot_clean -f -m publish/dmg_temp/BlinkApp.app 2>/dev/null || true
  xattr -cr publish/BlinkApp.app publish/dmg_temp/BlinkApp.app 2>/dev/null || true
fi

# Path to csproj
CSPROJ="BlinkApp/BlinkApp.csproj"
# Code signing identity for macOS from environment
if [ -z "${CODESIGN_ID:-}" ]; then
  echo "Error: CODESIGN_ID environment variable not set."
  echo "Set CODESIGN_ID to your macOS code signing identity (e.g., security find-identity)."
  exit 1
fi

# Extract current version
current=$(sed -n 's/.*<Version>\([0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}\)<\/Version>.*/\1/p' "$CSPROJ")
IFS='.' read -r major minor patch <<< "$current"

# Increment patch
patch=$((patch + 1))
new="$major.$minor.$patch"

echo "Bumping version: $current → $new"

# Update csproj version
perl -pi -e "s|<Version>$current</Version>|<Version>$new</Version>|" "$CSPROJ"

# Commit & tag
git add "$CSPROJ"
git commit -m "chore: bump version to v$new"
git tag "v$new"

# Build directories
rm -rf publish/win-x64 publish/osx-x64
discardable="publish"

# Publish self-contained builds
dotnet publish BlinkApp/BlinkApp.csproj -c Release -r win-x64 --self-contained true -o publish/win-x64
dotnet publish BlinkApp/BlinkApp.csproj -c Release -r osx-x64 --self-contained true -o publish/osx-x64
# Clean metadata from macOS publish folder
xattr -rc publish/osx-x64
find publish/osx-x64 -name '._*' -delete
# Verify Windows build output
if [ ! -d "publish/win-x64" ]; then
  echo "Error: publish/win-x64 directory not found. Windows build failed." >&2
  exit 1
fi
# Create macOS .app bundle at top-level publish directory

APP_BUNDLE=publish/BlinkApp.app
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
# Copy all published files into the app bundle, excluding the .app itself
# Copy macOS binaries without resource forks
# ditto avoids copying Finder metadata
# Copy macOS binaries without metadata
# Copy binaries without metadata
# ditto avoids resource forks and quarantine flags
ditto --norsrc --noextattr --noqtn publish/osx-x64 "$APP_BUNDLE/Contents/MacOS/"
# Strip extended attributes
xattr -rc "$APP_BUNDLE"
# Remove extended attributes and AppleDouble files from app bundle
xattr -rc "$APP_BUNDLE"
find "$APP_BUNDLE" -name '._*' -delete
# Deep strip extended attributes from all files
find "$APP_BUNDLE" -exec xattr -c {} +
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>BlinkApp</string>
  <key>CFBundleIdentifier</key><string>com.yourcompany.blinkapp</string>
  <key>CFBundleVersion</key><string>$new</string>
  <key>CFBundleExecutable</key><string>BlinkApp</string>
  <key>CFBundlePackageType</key><string>APPL</key>
  <key>LSMinimumSystemVersion</key><string>10.13</string>
</dict>
</plist>
EOF

# Validate Info.plist format
plutil -lint "$APP_BUNDLE/Contents/Info.plist"

# Package builds (installer for Windows, DMG for macOS)
ZIP_WIN=publish/BlinkApp-win-x64-v$new.zip
WIN_INSTALLER=publish/BlinkApp-win-x64-installer-v$new.exe
DMG_OSX=publish/BlinkApp-osx-x64-v$new.dmg
rm -f "$ZIP_WIN" "$WIN_INSTALLER" "$DMG_OSX"
# Ensure 7z is available
if ! command -v 7z >/dev/null 2>&1; then
  echo "Error: 7z not found. Install p7zip via 'brew install p7zip'"
  exit 1
fi
# Create Windows self-extracting installer
if [ -z "${SFX_MODULE:-}" ]; then
  echo "Error: SFX_MODULE not set. Run 'export SFX_MODULE=$(find \"$(brew --prefix p7zip)\" -name 7z.sfx)'"
  exit 1
fi
7z a -r -sfx"$SFX_MODULE" "$WIN_INSTALLER" publish/win-x64
# (optional) fallback ZIP
if [ -d publish/win-x64 ]; then
  zip -r "$ZIP_WIN" publish/win-x64
else
  echo "Skipping zip: publish/win-x64 directory not found."
fi
# Remove extended attributes and resource forks
# Strip quarantine, all attrs, and delete AppleDouble files
xattr -dr com.apple.quarantine "$APP_BUNDLE"
xattr -rc "$APP_BUNDLE"
find "$APP_BUNDLE" -name '._*' -delete
xattr -rc "$APP_BUNDLE"
find "$APP_BUNDLE" -name '._*' -delete
# Deep strip extended attributes from all files
find "$APP_BUNDLE" -exec xattr -c {} +
xattr -rc "$APP_BUNDLE"
# Code-sign macOS executable
codesign --options runtime --deep --force --timestamp --sign "$CODESIGN_ID" "$APP_BUNDLE"
# Create staged DMG with Applications link
DMG_TEMP=publish/dmg_temp
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"
# Remove residual resource forks using dot_clean
if command -v dot_clean >/dev/null 2>&1; then
  dot_clean -f -m publish/BlinkApp.app
fi
# Copy app bundle without resource forks or metadata
# ditto --norsrc strips resource forks and Finder metadata
# Remove residual resource forks in source
if command -v dot_clean >/dev/null 2>&1; then
  dot_clean -f -m publish/BlinkApp.app
fi
# Copy app bundle without resource forks or metadata
ditto --norsrc --noextattr --noqtn publish/BlinkApp.app "$DMG_TEMP/BlinkApp.app"
# Clean any residual resource forks in staged app
# Extra cleanup to remove metadata before codesigning DMG staging
if command -v dot_clean >/dev/null 2>&1; then
  dot_clean -f -m "$DMG_TEMP/BlinkApp.app" 2>/dev/null || true
  dot_clean -f -m "$DMG_TEMP" 2>/dev/null || true
fi
xattr -cr "$DMG_TEMP/BlinkApp.app" 2>/dev/null || true
xattr -cr "$DMG_TEMP" 2>/dev/null || true
find "$DMG_TEMP" -exec xattr -c {} +
# Extra cleanup before final codesign
if command -v dot_clean >/dev/null 2>&1; then
  dot_clean -f -m "$DMG_TEMP/BlinkApp.app" 2>/dev/null || true
  dot_clean -f -m "$DMG_TEMP" 2>/dev/null || true
fi
xattr -cr "$DMG_TEMP/BlinkApp.app" 2>/dev/null || true
xattr -cr "$DMG_TEMP" 2>/dev/null || true
find "$DMG_TEMP" -name '._*' -delete
find "$DMG_TEMP" -name '._*' -delete
# Ensure no resource forks in DMG staging before creation
if command -v dot_clean >/dev/null 2>&1; then
  dot_clean -f -m "$DMG_TEMP/BlinkApp.app" 2>/dev/null || true
  dot_clean -f -m "$DMG_TEMP" 2>/dev/null || true
fi
xattr -cr "$DMG_TEMP" 2>/dev/null || true
find "$DMG_TEMP" -name '._*' -delete
if command -v dot_clean >/dev/null 2>&1; then
  dot_clean -f -m "$DMG_TEMP/BlinkApp.app"
fi
# Strip all extended attributes and AppleDouble files
xattr -rc "$DMG_TEMP/BlinkApp.app"
find "$DMG_TEMP/BlinkApp.app" -name '._*' -delete
# Code-sign app bundle in DMG staging
codesign --options runtime --deep --force --timestamp --sign "$CODESIGN_ID" "$DMG_TEMP/BlinkApp.app"
# Link Applications folder
ln -s /Applications "$DMG_TEMP/Applications"
# Create compressed DMG
hdiutil create -volname "BlinkApp" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -srcfolder "$DMG_TEMP" -format UDZO -ov "$DMG_OSX"
# Validate DMG
MNT=$(mktemp -d)
hdiutil attach "$DMG_OSX" -mountpoint "$MNT" -nobrowse -readonly
codesign --verify --deep --strict "$MNT/BlinkApp.app" && spctl -avvv "$MNT/BlinkApp.app"
RESULT=$?
hdiutil detach "$MNT"
if [ $RESULT -ne 0 ]; then
  echo "DMG validation failed"; exit 1
ditto --norsrc --noextattr --noqtn publish/BlinkApp.app "$DMG_TEMP/BlinkApp.app"
# Clean up staging
rm -rf "$DMG_TEMP"
DMG_TEMP=publish/dmg_temp
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"
# Copy app bundle without metadata
# Copy app bundle without metadata
ditto --norsrc --noextattr --noqtn publish/BlinkApp.app "$DMG_TEMP/BlinkApp.app"
# Strip extended attributes
xattr -rc "$DMG_TEMP/BlinkApp.app"
# Clean metadata
xattr -rc "$DMG_TEMP"
find "$DMG_TEMP" -name '._*' -delete
# Deep strip extended attributes from DMG staging
find "$DMG_TEMP" -exec xattr -c {} +
# Extra cleanup before final codesign
if command -v dot_clean >/dev/null 2>&1; then
  dot_clean -f -m "$DMG_TEMP/BlinkApp.app" 2>/dev/null || true
  dot_clean -f -m "$DMG_TEMP" 2>/dev/null || true
fi
xattr -cr "$DMG_TEMP/BlinkApp.app" 2>/dev/null || true
xattr -cr "$DMG_TEMP" 2>/dev/null || true
find "$DMG_TEMP" -name '._*' -delete
# Code-sign app bundle in DMG staging
codesign --options runtime --deep --force --timestamp --sign "$CODESIGN_ID" "$DMG_TEMP/BlinkApp.app"
# Final cleanup of extended attributes
xattr -rc "$DMG_TEMP/BlinkApp.app"
# Remove quarantine flag
xattr -dr com.apple.quarantine "$DMG_TEMP"
ln -s /Applications "$DMG_TEMP/Applications"
# Build compressed DMG
# Cleanup staging folder
if command -v dot_clean >/dev/null 2>&1; then
  dot_clean -f -m "$DMG_TEMP" 2>/dev/null || true
fi
xattr -cr "$DMG_TEMP" 2>/dev/null || true
hdiutil create -volname "BlinkApp" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -srcfolder "$DMG_TEMP" -format UDZO -ov "$DMG_OSX"
# Validate DMG
MNT=$(mktemp -d)
hdiutil attach "$DMG_OSX" -mountpoint "$MNT" -nobrowse -readonly
codesign --verify --deep --strict "$MNT/BlinkApp.app" && spctl -avvv "$MNT/BlinkApp.app"
RESULT=$?
hdiutil detach "$MNT"
if [ $RESULT -ne 0 ]; then
  echo "DMG validation failed"; exit 1
fi
rm -rf "$DMG_TEMP"

# Push changes and tags
git push origin && git push origin "v$new"

# Create or update GitHub release
if gh release view "v$new" > /dev/null 2>&1; then
  echo "Release v$new exists. Uploading assets..."
else
  echo "Creating release v$new..."
  gh release create "v$new" --title "v$new" --notes "Release v$new"
fi

# Upload zip assets
echo "Uploading archives..."
gh release upload "v$new" --clobber "$WIN_INSTALLER" "$DMG_OSX"

echo "Release v$new done."