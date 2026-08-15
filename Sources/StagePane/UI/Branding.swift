import AppKit
import SwiftUI

enum StagePanePalette {
    static let ink = Color(red: 0.047, green: 0.063, blue: 0.094)
    static let inkRaised = Color(red: 0.071, green: 0.090, blue: 0.133)
    static let indigo = Color(red: 0.357, green: 0.361, blue: 0.941)
    static let aqua = Color(red: 0.282, green: 0.847, blue: 0.910)
    static let mint = Color(red: 0.286, green: 0.878, blue: 0.694)
    static let coral = Color(red: 0.969, green: 0.420, blue: 0.447)
    static let cloud = Color(red: 0.941, green: 0.957, blue: 0.984)

    // Keep the vivid brand colors for artwork, while using contrast-safe
    // semantic variants for text, controls, and status indicators.
    static let aquaReadable = adaptiveColor(
        light: NSColor(red: 0.000, green: 0.420, blue: 0.490, alpha: 1),
        dark: NSColor(red: 0.282, green: 0.847, blue: 0.910, alpha: 1)
    )
    static let mintReadable = adaptiveColor(
        light: NSColor(red: 0.000, green: 0.400, blue: 0.290, alpha: 1),
        dark: NSColor(red: 0.286, green: 0.878, blue: 0.694, alpha: 1)
    )
    static let coralReadable = adaptiveColor(
        light: NSColor(red: 0.700, green: 0.160, blue: 0.230, alpha: 1),
        dark: NSColor(red: 0.969, green: 0.420, blue: 0.447, alpha: 1)
    )
    static let actionBeam = Color(red: 0.040, green: 0.450, blue: 0.600)

    private static func adaptiveColor(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        })
    }
}

struct BrandMark: View {
    var size: CGFloat = 34

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [StagePanePalette.indigo, StagePanePalette.aqua],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(2, size * 0.105)
                )
                .frame(width: size * 0.78, height: size * 0.64)
                .offset(x: -size * 0.11, y: -size * 0.09)

            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [StagePanePalette.indigo, StagePanePalette.aqua],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.68, height: size * 0.56)
                .offset(x: size * 0.13, y: size * 0.10)

            RoundedRectangle(cornerRadius: size * 0.09, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .frame(width: size * 0.28, height: size * 0.20)
                .offset(x: size * 0.13, y: size * 0.10)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct BrandLockup: View {
    var compact = false

    var body: some View {
        HStack(spacing: 10) {
            BrandMark(size: compact ? 28 : 36)
            Text("StagePane")
                .font(compact ? .headline : .title3.weight(.bold))
                .tracking(-0.3)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("StagePane")
    }
}

struct CardSurface: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        colorScheme == .dark
                            ? Color.white.opacity(0.055)
                            : Color.white.opacity(0.88)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.09)
                                    : Color.black.opacity(0.055),
                                lineWidth: 1
                            )
                    )
            )
    }
}

extension View {
    func cardSurface(cornerRadius: CGFloat = 20, padding: CGFloat = 20) -> some View {
        modifier(CardSurface(cornerRadius: cornerRadius, padding: padding))
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .frame(minHeight: 38)
            .background(
                LinearGradient(
                    colors: configuration.isPressed
                        ? [StagePanePalette.indigo.opacity(0.82), StagePanePalette.actionBeam.opacity(0.82)]
                        : [StagePanePalette.indigo, StagePanePalette.actionBeam],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 11, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .frame(minHeight: 38)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(
                        colorScheme == .dark
                            ? Color.white.opacity(configuration.isPressed ? 0.12 : 0.075)
                            : Color.black.opacity(configuration.isPressed ? 0.09 : 0.045)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(Color.primary.opacity(0.09), lineWidth: 1)
            )
    }
}

struct SectionHeading: View {
    let eyebrow: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(eyebrow.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(StagePanePalette.aquaReadable)
            Text(title)
                .font(.system(.title, design: .rounded, weight: .bold))
                .tracking(-0.7)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
