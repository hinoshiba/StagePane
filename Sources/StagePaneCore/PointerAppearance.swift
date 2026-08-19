import Foundation

/// An sRGB color used by the audience-facing laser pointer.
public struct PointerRGBColor: Equatable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = Self.normalizedComponent(red)
        self.green = Self.normalizedComponent(green)
        self.blue = Self.normalizedComponent(blue)
    }

    public init?(hexRGB: String) {
        var value = hexRGB.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") {
            value.removeFirst()
        }
        guard value.count == 6, let packed = UInt32(value, radix: 16) else {
            return nil
        }
        self.init(
            red: Double((packed >> 16) & 0xFF) / 255,
            green: Double((packed >> 8) & 0xFF) / 255,
            blue: Double(packed & 0xFF) / 255
        )
    }

    public var hexRGB: String {
        String(
            format: "#%02X%02X%02X",
            Self.byte(from: red),
            Self.byte(from: green),
            Self.byte(from: blue)
        )
    }

    public static let presentationRed = PointerRGBColor(
        red: 1,
        green: 59.0 / 255.0,
        blue: 48.0 / 255.0
    )

    private static func normalizedComponent(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }

    private static func byte(from component: Double) -> Int {
        Int((normalizedComponent(component) * 255).rounded())
    }
}

/// Visual-only customization for the cursor-safe pointer overlay.
///
/// Changing this value never changes ScreenCaptureKit cursor visibility. That
/// separation lets active streams update their dot immediately without
/// weakening the native-cursor transition safeguards.
public struct PointerAppearance: Equatable, Sendable {
    public static let minimumDiameter = 10.0
    public static let maximumDiameter = 64.0
    public static let minimumGlow = 0.0
    public static let maximumGlow = 1.0

    public static let presentationDefault = PointerAppearance(
        diameter: 22,
        color: .presentationRed,
        glow: 0.55
    )

    public let diameter: Double
    public let color: PointerRGBColor
    public let glow: Double

    public init(diameter: Double, color: PointerRGBColor, glow: Double) {
        self.diameter = Self.clamped(
            diameter,
            minimum: Self.minimumDiameter,
            maximum: Self.maximumDiameter,
            fallback: 22
        )
        self.color = color
        self.glow = Self.clamped(
            glow,
            minimum: Self.minimumGlow,
            maximum: Self.maximumGlow,
            fallback: 0.55
        )
    }

    /// Resolves independently stored values so one malformed preference does
    /// not discard the other valid customizations.
    public static func resolvePreference(
        storedDiameter: Double?,
        storedColorHex: String?,
        storedGlow: Double?
    ) -> PointerAppearance {
        let fallback = presentationDefault
        return PointerAppearance(
            diameter: storedDiameter ?? fallback.diameter,
            color: storedColorHex.flatMap(PointerRGBColor.init(hexRGB:)) ?? fallback.color,
            glow: storedGlow ?? fallback.glow
        )
    }

    private static func clamped(
        _ value: Double,
        minimum: Double,
        maximum: Double,
        fallback: Double
    ) -> Double {
        guard value.isFinite else { return fallback }
        return min(max(value, minimum), maximum)
    }
}
