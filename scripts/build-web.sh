#!/bin/bash

# Quick web build script (without deploying)
# Usage: ./scripts/build-web.sh

set -e

BUILD_DIR="builds/web"
GODOT_EXPORT_TEMPLATE="HTML5"

echo "🔨 Building web version..."

# Create build directory
mkdir -p "$BUILD_DIR"

# Export with Godot (headless)
if command -v godot &> /dev/null; then
    godot --headless --export-release "$GODOT_EXPORT_TEMPLATE" "$BUILD_DIR/index.html"
elif command -v godot4 &> /dev/null; then
    godot4 --headless --export-release "$GODOT_EXPORT_TEMPLATE" "$BUILD_DIR/index.html"
else
    echo "❌ Godot not found in PATH. Please export manually."
    echo "Manual export: Project > Export > HTML5 > Export Project"
    exit 1
fi

# Check if export was successful
if [ ! -f "$BUILD_DIR/index.html" ]; then
    echo "❌ Export failed - index.html not found"
    exit 1
fi

echo "✅ Web build complete!"
echo "📁 Build location: $BUILD_DIR/"
echo "🌐 Test locally: cd $BUILD_DIR && python -m http.server 8000"