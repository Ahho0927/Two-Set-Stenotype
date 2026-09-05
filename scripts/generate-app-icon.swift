#!/usr/bin/env swift

import AppKit
import Foundation

// Keep the approved artwork as the source of truth; never redraw the old icon.
let projectDirectory = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
let sourceURL = projectDirectory.appendingPathComponent("macos/Resources/AppIcon-source.png")
guard let source = NSImage(contentsOf: sourceURL) else {
    throw NSError(domain: "CastorIcon", code: 4, userInfo: [
        NSLocalizedDescriptionKey: "Cannot load approved icon: \(sourceURL.path)",
    ])
}

let outputDirectory = URL(
    fileURLWithPath: CommandLine.arguments.dropFirst().first ?? projectDirectory.appendingPathComponent("macos/Resources").path,
    isDirectory: true
)
let fileManager = FileManager.default
try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

struct IconChunk {
    let type: String
    let pixels: Int
}

let chunks = [
    IconChunk(type: "icp4", pixels: 16),
    IconChunk(type: "icp5", pixels: 32),
    IconChunk(type: "icp6", pixels: 64),
    IconChunk(type: "ic07", pixels: 128),
    IconChunk(type: "ic08", pixels: 256),
    IconChunk(type: "ic09", pixels: 512),
    IconChunk(type: "ic10", pixels: 1024),
]

func renderIcon(pixels: Int) throws -> Data {
    let size = CGFloat(pixels)
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "CastorIcon", code: 1)
    }

    bitmap.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "CastorIcon", code: 2)
    }
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    rect.fill(using: .copy)
    source.draw(in: rect, from: .zero, operation: .copy, fraction: 1)

    NSGraphicsContext.restoreGraphicsState()
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "CastorIcon", code: 3)
    }
    return data
}

let masterPNG = try renderIcon(pixels: 1024)
try masterPNG.write(
    to: outputDirectory.appendingPathComponent("AppIcon-1024.png"),
    options: .atomic
)

func bigEndianData(_ value: Int) -> Data {
    var encoded = UInt32(value).bigEndian
    return Data(bytes: &encoded, count: MemoryLayout<UInt32>.size)
}

var payload = Data()
for chunk in chunks {
    let png = chunk.pixels == 1024 ? masterPNG : try renderIcon(pixels: chunk.pixels)
    payload.append(chunk.type.data(using: .ascii)!)
    payload.append(bigEndianData(png.count + 8))
    payload.append(png)
}

var icns = Data("icns".utf8)
icns.append(bigEndianData(payload.count + 8))
icns.append(payload)
try icns.write(
    to: outputDirectory.appendingPathComponent("AppIcon.icns"),
    options: .atomic
)

print("Generated \(outputDirectory.appendingPathComponent("AppIcon.icns").path)")
