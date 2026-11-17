#!/bin/sh
#
# Build VLCKit (macOS) from source with the patches in patches/.
#
# This runs VLCKit's own build (buildVLCKit.sh) after copying patches/ into
# VLCKit's libvlc/patches/. The file names start with 9001- so that they are
# applied after VLCKit's own patches (0001-...).
#
# It builds libVLC and all of its contribs, which takes about 15 minutes on an
# Apple silicon Mac for the first time and uses about 10 GB in $WORK_DIR.
#
# The result is build/VLCKit.xcframework.zip. Upload it to a release and put
# its checksum in Package.swift.

set -eu

# VLCKit tag to build
VERSION=3.7.3
REPO=https://code.videolan.org/videolan/VLCKit.git

cd "$(dirname "$0")"
ROOT_DIR=$(pwd)
WORK_DIR=${WORK_DIR:-$ROOT_DIR/build}

if [ ! -d "$WORK_DIR/VLCKit" ]; then
    mkdir -p "$WORK_DIR"
    git clone --depth 1 --branch "$VERSION" "$REPO" "$WORK_DIR/VLCKit"
fi
cp patches/*.patch "$WORK_DIR/VLCKit/libvlc/patches/"
# VLCKit.xcodeproj targets macOS 10.9, which current Xcode no longer accepts
# (the minimum is 12.0).
sed -i '' 's/MACOSX_DEPLOYMENT_TARGET = 10\.[0-9]*;/MACOSX_DEPLOYMENT_TARGET = 12.0;/' \
    "$WORK_DIR/VLCKit/VLCKit.xcodeproj/project.pbxproj"

(cd "$WORK_DIR/VLCKit" && ./buildVLCKit.sh)

archive="$WORK_DIR/VLCKit.xcframework.zip"
rm -f "$archive"
(cd "$WORK_DIR/VLCKit/build" && ditto -c -k --keepParent VLCKit.xcframework "$archive")
echo "archive:  $archive"
echo "checksum: $(swift package compute-checksum "$archive")"
