import Foundation

/// A bounded raster size for exporting one clean Stage frame.
///
/// The limit admits 8K landscape or portrait output while preventing an
/// accidental square 8K allocation from consuming hundreds of megabytes.
public struct StageSnapshotSize: Equatable, Sendable {
    public static let maximumDimension = 7_680
    public static let maximumPixelCount = 7_680 * 4_320

    public let width: Int
    public let height: Int

    public init?(width: Int, height: Int) {
        let pixelCount = width.multipliedReportingOverflow(by: height)
        guard width > 0,
              height > 0,
              width <= Self.maximumDimension,
              height <= Self.maximumDimension,
              !pixelCount.overflow,
              pixelCount.partialValue <= Self.maximumPixelCount else { return nil }
        self.width = width
        self.height = height
    }

    public init(preset: StagePreset) {
        // Every built-in preset is substantially below the export ceiling.
        self.width = preset.pixelWidth
        self.height = preset.pixelHeight
    }
}
