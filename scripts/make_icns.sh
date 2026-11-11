#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RESOURCES_DIR="$PROJECT_DIR/Resources"
SOURCE_PNG="$RESOURCES_DIR/AppIcon_1024.png"
OUTPUT_ICNS="$RESOURCES_DIR/AppIcon.icns"
ICONSET_DIR="/tmp/MonitorMonster.iconset"

if [ ! -f "$SOURCE_PNG" ]; then
    echo "Source PNG not found at $SOURCE_PNG"
    exit 1
fi

echo "==> Slicing 1024x1024 PNG into macOS iconset with 32-bit RGBA..."
cat << 'SWIFT_EOF' > /tmp/gen_iconset.swift
import AppKit

guard let sourceImage = NSImage(contentsOfFile: CommandLine.arguments[1]) else {
    print("Error: Could not load source image")
    exit(1)
}

let iconsetPath = CommandLine.arguments[2]
try? FileManager.default.removeItem(atPath: iconsetPath)
try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

func savePNG(_ image: NSImage, size: CGFloat, filename: String) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size),
        pixelsHigh: Int(size),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size), from: .zero, operation: .copy, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()
    
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(filename)"))
}

savePNG(sourceImage, size: 16, filename: "icon_16x16.png")
savePNG(sourceImage, size: 32, filename: "icon_16x16@2x.png")
savePNG(sourceImage, size: 32, filename: "icon_32x32.png")
savePNG(sourceImage, size: 64, filename: "icon_32x32@2x.png")
savePNG(sourceImage, size: 128, filename: "icon_128x128.png")
savePNG(sourceImage, size: 256, filename: "icon_128x128@2x.png")
savePNG(sourceImage, size: 256, filename: "icon_256x256.png")
savePNG(sourceImage, size: 512, filename: "icon_256x256@2x.png")
savePNG(sourceImage, size: 512, filename: "icon_512x512.png")
savePNG(sourceImage, size: 1024, filename: "icon_512x512@2x.png")
SWIFT_EOF

swiftc -module-cache-path /tmp/swift-cache /tmp/gen_iconset.swift -o /tmp/gen_iconset
/tmp/gen_iconset "$SOURCE_PNG" "$ICONSET_DIR"
rm -f /tmp/gen_iconset.swift /tmp/gen_iconset

echo "==> Converting iconset to AppIcon.icns..."
iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICNS"
rm -rf "$ICONSET_DIR"

echo "==> AppIcon.icns ready at $OUTPUT_ICNS"
