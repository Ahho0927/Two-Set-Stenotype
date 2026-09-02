#!/usr/bin/env swift

import AppKit
import Foundation

let outputDirectory = URL(
    fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "macos/Resources",
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
        throw NSError(domain: "TSSIcon", code: 1)
    }

    bitmap.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "TSSIcon", code: 2)
    }
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    let scale = size / 1024
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    let tileRect = NSRect(x: 86 * scale, y: 86 * scale, width: 852 * scale, height: 852 * scale)
    let tilePath = NSBezierPath(roundedRect: tileRect, xRadius: 204 * scale, yRadius: 204 * scale)
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.32)
    shadow.shadowBlurRadius = 46 * scale
    shadow.shadowOffset = NSSize(width: 0, height: -24 * scale)
    shadow.set()
    NSGradient(
        starting: NSColor(calibratedRed: 0.39, green: 0.39, blue: 0.95, alpha: 1),
        ending: NSColor(calibratedRed: 0.20, green: 0.16, blue: 0.58, alpha: 1)
    )?.draw(in: tilePath, angle: -62)

    NSGraphicsContext.saveGraphicsState()
    tilePath.addClip()
    let highlight = NSBezierPath(ovalIn: NSRect(x: 150 * scale, y: 520 * scale, width: 760 * scale, height: 520 * scale))
    NSColor.white.withAlphaComponent(0.10).setFill()
    highlight.fill()
    NSGraphicsContext.restoreGraphicsState()

    let keySize = NSSize(width: 238 * scale, height: 294 * scale)
    let origins = [
        NSPoint(x: 151 * scale, y: 350 * scale),
        NSPoint(x: 393 * scale, y: 378 * scale),
        NSPoint(x: 635 * scale, y: 350 * scale),
    ]
    let letters = ["T", "S", "S"]

    for (index, origin) in origins.enumerated() {
        let rect = NSRect(origin: origin, size: keySize)
        let keyPath = NSBezierPath(roundedRect: rect, xRadius: 62 * scale, yRadius: 62 * scale)
        let keyShadow = NSShadow()
        keyShadow.shadowColor = NSColor.black.withAlphaComponent(0.23)
        keyShadow.shadowBlurRadius = 18 * scale
        keyShadow.shadowOffset = NSSize(width: 0, height: -12 * scale)
        keyShadow.set()
        NSColor.white.withAlphaComponent(0.94).setFill()
        keyPath.fill()

        NSGraphicsContext.current?.cgContext.setShadow(offset: .zero, blur: 0, color: nil)
        NSColor.white.withAlphaComponent(0.48).setStroke()
        keyPath.lineWidth = 5 * scale
        keyPath.stroke()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let fontSize = max(8, 126 * scale)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: NSColor(calibratedRed: 0.24, green: 0.20, blue: 0.62, alpha: 1),
            .paragraphStyle: paragraph,
        ]
        let textRect = NSRect(
            x: rect.minX,
            y: rect.midY - fontSize * 0.55,
            width: rect.width,
            height: fontSize * 1.2
        )
        letters[index].draw(in: textRect, withAttributes: attributes)
    }

    NSGraphicsContext.restoreGraphicsState()
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "TSSIcon", code: 3)
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
