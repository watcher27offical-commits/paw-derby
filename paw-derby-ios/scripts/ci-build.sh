#!/usr/bin/env bash
# Builds the iOS app and uploads it to App Store Connect / TestFlight.
# Runs on a GitHub Actions Mac. Needs these environment variables:
#   APPLE_TEAM_ID, ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH, BUILD_NUMBER, APP_VERSION
set -euo pipefail
cd "$(dirname "$0")/.."

: "${APPLE_TEAM_ID:?missing}" "${ASC_KEY_ID:?missing}" "${ASC_ISSUER_ID:?missing}" "${ASC_KEY_PATH:?missing}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
APP_VERSION="${APP_VERSION:-1.0.0}"

APP_DIR=ios/App
PLIST=$APP_DIR/App/Info.plist
PBX=$APP_DIR/App.xcodeproj/project.pbxproj
OUT=build
mkdir -p "$OUT"

# --- app settings: no export-compliance prompt, version numbers, team ---
/usr/libexec/PlistBuddy -c "Add :ITSAppUsesNonExemptEncryption bool false" "$PLIST" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Set :ITSAppUsesNonExemptEncryption false" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Paw Derby" "$PLIST" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string Paw Derby" "$PLIST"
sed -i '' -E "s/CURRENT_PROJECT_VERSION = [^;]+;/CURRENT_PROJECT_VERSION = ${BUILD_NUMBER};/g" "$PBX"
sed -i '' -E "s/MARKETING_VERSION = [^;]+;/MARKETING_VERSION = ${APP_VERSION};/g" "$PBX"
sed -i '' -E "/DEVELOPMENT_TEAM = /d" "$PBX"
sed -i '' -E "s#(INFOPLIST_FILE = App/Info.plist;)#\1 DEVELOPMENT_TEAM = ${APPLE_TEAM_ID}; CODE_SIGN_STYLE = Automatic;#g" "$PBX"

# Capacitor 7 uses CocoaPods (workspace); newer versions may use Swift Package Manager (project only).
if [ -d "$APP_DIR/App.xcworkspace" ]; then CONTAINER=(-workspace "$APP_DIR/App.xcworkspace"); else CONTAINER=(-project "$APP_DIR/App.xcodeproj"); fi
AUTH=(-allowProvisioningUpdates -authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")

cat > "$OUT/ExportOptions.plist" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyLists-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>upload</string>
  <key>signingStyle</key><string>automatic</string>
  <key>teamID</key><string>${APPLE_TEAM_ID}</string>
  <key>uploadSymbols</key><true/>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict></plist>
PL

archive() { # $@ = extra build settings
  rm -rf "$OUT/App.xcarchive"
  xcodebuild "${CONTAINER[@]}" -scheme App -configuration Release \
    -destination 'generic/platform=iOS' -archivePath "$OUT/App.xcarchive" \
    "${AUTH[@]}" archive "$@" | tee "$OUT/archive.log" | grep -E "error:|warning: .*sign|ARCHIVE (SUCCEEDED|FAILED)" || true
  [ -d "$OUT/App.xcarchive" ] || { echo "Archive failed - see build/archive.log"; tail -50 "$OUT/archive.log"; return 1; }
}
export_upload() {
  xcodebuild -exportArchive -archivePath "$OUT/App.xcarchive" -exportOptionsPlist "$OUT/ExportOptions.plist" \
    -exportPath "$OUT/export" "${AUTH[@]}" 2>&1 | tee "$OUT/export.log"
  grep -qE "EXPORT SUCCEEDED|Upload succeeded|Uploaded" "$OUT/export.log"
}

# 1st try: unsigned archive, Apple signs it in the cloud during upload (no certificates to manage).
echo "== Archiving (cloud signing) =="
archive CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""
if export_upload; then echo "== Uploaded build ${APP_VERSION} (${BUILD_NUMBER}) to App Store Connect =="; exit 0; fi

# 2nd try: normal signed archive (Xcode creates what it needs using the API key).
echo "== Retrying with a signed archive =="
archive
export_upload
echo "== Uploaded build ${APP_VERSION} (${BUILD_NUMBER}) to App Store Connect =="
