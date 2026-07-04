#!/bin/bash
set -e

APP_NAME="ControlFreek"
BINARY_NAME="stompbox_scanner"
BUNDLE_DIR="build/linux/x64/release/bundle"
APPDIR="build/AppDir"
APPIMAGE_TOOL="build/appimagetool-x86_64.AppImage"
OUTPUT="build/${APP_NAME}-x86_64.AppImage"

echo "==> Building Flutter Linux release..."
flutter build linux --release

echo "==> Creating AppDir..."
rm -rf "$APPDIR"
mkdir -p "$APPDIR"

# Copy the Flutter bundle into AppDir root (preserves relative lib/ and data/ paths)
cp -r "$BUNDLE_DIR/"* "$APPDIR/"

# AppRun launches the binary from its own directory so relative paths resolve
cat > "$APPDIR/AppRun" << 'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
exec "$HERE/stompbox_scanner" "$@"
EOF
chmod +x "$APPDIR/AppRun"

# Icon and desktop entry (required by AppImage spec)
cp linux/icon.png "$APPDIR/${APP_NAME}.png"

cat > "$APPDIR/${APP_NAME}.desktop" << EOF
[Desktop Entry]
Name=${APP_NAME}
Exec=${BINARY_NAME}
Icon=${APP_NAME}
Type=Application
Categories=AudioVideo;Audio;
EOF

echo "==> Fetching appimagetool (if needed)..."
if [ ! -f "$APPIMAGE_TOOL" ]; then
    TOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    if command -v curl &>/dev/null; then
        curl -L --progress-bar "$TOOL_URL" -o "$APPIMAGE_TOOL"
    else
        wget -q --show-progress "$TOOL_URL" -o "$APPIMAGE_TOOL"
    fi
    chmod +x "$APPIMAGE_TOOL"
fi

echo "==> Packaging AppImage..."
# APPIMAGE_EXTRACT_AND_RUN avoids needing libfuse2 on the build machine
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$APPIMAGE_TOOL" "$APPDIR" "$OUTPUT"

echo ""
echo "Done: $OUTPUT"
echo "Note: end users need libfuse2 installed to run the AppImage."
echo "      Ubuntu 22+ / Mint 21+: sudo apt install libfuse2"
