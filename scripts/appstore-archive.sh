#!/usr/bin/env bash
# Archive Pocket Price Reader (Release) and export a signed .ipa for App Store Connect.
# Usage:
#   scripts/appstore-archive.sh [marketingVersion] [buildNumber]
# e.g. scripts/appstore-archive.sh 1.0 1
#
# Then upload the .ipa with EITHER:
#   - the Transporter app (drag in build/export/*.ipa), OR
#   - Xcode Organizer (Window ▸ Organizer ▸ Distribute App), OR
#   - the CLI below (needs an App Store Connect API key):
#       xcrun altool --upload-app -f build/export/*.ipa -t ios \
#         --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
#
# Requires: a paid Apple Developer Program membership (team KRV2243NRM) so Xcode can
# create the Apple Distribution cert + App Store provisioning profile automatically.
set -euo pipefail

cd "$(dirname "$0")/.."

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
TEAM=KRV2243NRM
SCHEME=PocketPriceReader
PROJECT=PocketPriceReader.xcodeproj
ARCHIVE=build/PocketPriceReader.xcarchive
EXPORT=build/export

MARKETING_VERSION="${1:-}"
BUILD_NUMBER="${2:-}"

echo "▸ Regenerating project…"
xcodegen generate >/dev/null

VER_ARGS=()
[ -n "$MARKETING_VERSION" ] && VER_ARGS+=("MARKETING_VERSION=$MARKETING_VERSION")
[ -n "$BUILD_NUMBER" ] && VER_ARGS+=("CURRENT_PROJECT_VERSION=$BUILD_NUMBER")

echo "▸ Archiving (Release)…"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$TEAM" "${VER_ARGS[@]}" \
  archive

echo "▸ Exporting signed .ipa for App Store…"
rm -rf "$EXPORT"
xcodebuild -exportArchive -archivePath "$ARCHIVE" \
  -exportOptionsPlist ExportOptions.plist -exportPath "$EXPORT" \
  -allowProvisioningUpdates

echo "✓ Done. Upload this to App Store Connect:"
ls -1 "$EXPORT"/*.ipa
