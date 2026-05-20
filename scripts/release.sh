#!/bin/bash

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: ./scripts/release.sh <version>"
  exit 1
fi

RELEASE_VERSION="$1"
VERSION="${RELEASE_VERSION#v}"
TAG="v$VERSION"
APPLE_SILICON_DMG="Cometrans-${VERSION}-apple-silicon.dmg"
INTEL_DMG="Cometrans-${VERSION}-intel.dmg"

./scripts/test_coverage.sh
VERSION="$VERSION" BUILD_ARCH=arm64 ARTIFACT_SUFFIX=-apple-silicon ./build_dmg.sh
VERSION="$VERSION" BUILD_ARCH=x86_64 ARTIFACT_SUFFIX=-intel ./build_dmg.sh

if [[ ! -f "$APPLE_SILICON_DMG" || ! -f "$INTEL_DMG" ]]; then
  echo "Missing release artifacts."
  exit 1
fi

git tag -a "$TAG" -m "Release $VERSION"
git push origin "$TAG"

if command -v gh >/dev/null 2>&1; then
  gh release create "$TAG" \
    "$APPLE_SILICON_DMG" "$APPLE_SILICON_DMG.sha256" \
    "$INTEL_DMG" "$INTEL_DMG.sha256" \
    --title "Cometrans $VERSION" \
    --generate-notes
else
  echo "Tag pushed. Create the GitHub release manually and upload:"
  echo "  $APPLE_SILICON_DMG"
  echo "  $APPLE_SILICON_DMG.sha256"
  echo "  $INTEL_DMG"
  echo "  $INTEL_DMG.sha256"
fi
