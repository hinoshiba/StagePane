#!/usr/bin/swift
import AppKit
import CoreGraphics
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    fputs("Usage: swift Scripts/MakeIcon.swift <output-directory>\n", stderr)
    exit(64)
}

let outputDirectory = URL(fileURLWithPath: arguments[1], isDirectory: true)
let iconsetURL = outputDirectory.appendingPathComponent("StagePane.iconset", isDirectory: true)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

struct IconVariant {
    let points: Int
    let scale: Int

    var pixels: Int { points * scale }
    var filename: String {
        scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
    }
}

let variants = [
    IconVariant(points: 16, scale: 1),
    IconVariant(points: 16, scale: 2),
    IconVariant(points: 32, scale: 1),
    IconVariant(points: 32, scale: 2),
    IconVariant(points: 128, scale: 1),
    IconVariant(points: 128, scale: 2),
    IconVariant(points: 256, scale: 1),
    IconVariant(points: 256, scale: 2),
    IconVariant(points: 512, scale: 1),
    IconVariant(points: 512, scale: 2)
]

func roundedPath(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func render(size: Int) throws -> Data {
    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw NSError(domain: "StagePaneIcon", code: 1)
    }

    let scale = CGFloat(size) / 1024
    context.scaleBy(x: scale, y: scale)
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)

    let backgroundRect = CGRect(x: 30, y: 30, width: 964, height: 964)
    context.saveGState()
    context.addPath(roundedPath(backgroundRect, radius: 224))
    context.clip()
    let background = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            NSColor(red: 0.090, green: 0.110, blue: 0.173, alpha: 1).cgColor,
            NSColor(red: 0.027, green: 0.039, blue: 0.067, alpha: 1).cgColor
        ] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(
        background,
        start: CGPoint(x: 120, y: 940),
        end: CGPoint(x: 900, y: 60),
        options: []
    )

    context.setFillColor(NSColor(red: 0.357, green: 0.361, blue: 0.941, alpha: 0.22).cgColor)
    context.fillEllipse(in: CGRect(x: -100, y: 540, width: 700, height: 700))
    context.setFillColor(NSColor(red: 0.282, green: 0.847, blue: 0.910, alpha: 0.17).cgColor)
    context.fillEllipse(in: CGRect(x: 500, y: -120, width: 700, height: 700))
    context.restoreGState()

    let beam = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            NSColor(red: 0.357, green: 0.361, blue: 0.941, alpha: 1).cgColor,
            NSColor(red: 0.282, green: 0.847, blue: 0.910, alpha: 1).cgColor
        ] as CFArray,
        locations: [0, 1]
    )!

    let rearRect = CGRect(x: 198, y: 420, width: 500, height: 396)
    context.saveGState()
    context.setLineWidth(58)
    context.addPath(roundedPath(rearRect, radius: 82))
    context.replacePathWithStrokedPath()
    context.clip()
    context.drawLinearGradient(beam, start: CGPoint(x: 180, y: 820), end: CGPoint(x: 720, y: 400), options: [])
    context.restoreGState()

    let frontRect = CGRect(x: 350, y: 284, width: 488, height: 384)
    context.saveGState()
    context.addPath(roundedPath(frontRect, radius: 84))
    context.clip()
    context.drawLinearGradient(beam, start: CGPoint(x: 350, y: 700), end: CGPoint(x: 850, y: 270), options: [])
    context.restoreGState()

    context.setFillColor(NSColor.white.withAlphaComponent(0.95).cgColor)
    context.addPath(roundedPath(CGRect(x: 488, y: 400, width: 212, height: 152), radius: 34))
    context.fillPath()

    guard let image = context.makeImage() else {
        throw NSError(domain: "StagePaneIcon", code: 2)
    }
    let representation = NSBitmapImageRep(cgImage: image)
    guard let png = representation.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "StagePaneIcon", code: 3)
    }
    return png
}

for variant in variants {
    let data = try render(size: variant.pixels)
    try data.write(to: iconsetURL.appendingPathComponent(variant.filename), options: .atomic)
}

print(iconsetURL.path)
