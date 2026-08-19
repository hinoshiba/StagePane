import SwiftUI

/// A code-native StagePane lockup used by both audience output and the private
/// WYSIWYG preview. The single outer opacity keeps the mark unobtrusive while
/// preserving the brand colors.
struct StageWatermark: View {
    let prefersDarkForeground: Bool
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 5 : 7) {
            BrandMark(size: compact ? 16 : 20)
            Text("StagePane")
                .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
        }
        .foregroundStyle(prefersDarkForeground ? Color.black : Color.white)
        .opacity(0.58)
        .padding(compact ? 10 : 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
