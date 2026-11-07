import Combine
import Foundation
import StagePaneCore

/// A virtual Stage. Capture consent, layout, and ink belong to this group for
/// the lifetime of the app; captured content is never saved to disk.
@MainActor
final class StageScreenGroup: ObservableObject, Identifiable {
    let id = UUID()
    @Published private(set) var name: StageLayerName
    let capture: CaptureCoordinator
    let annotations = StageAnnotationStore()
    @Published var preset: StagePreset
    @Published var theme: StageTheme
    var selectedSourceID: StageSourceID?
    var accessIssueNotice: CaptureAccessIssueNotice?
    var subscriptions = Set<AnyCancellable>()

    var title: String { name.displayTitle }

    init(ordinal: Int, preset: StagePreset, theme: StageTheme, isSelected: Bool = false) {
        name = StageLayerName(defaultTitle: L10n.text("画面 \(ordinal)", "Screen \(ordinal)"))
        self.preset = preset
        self.theme = theme
        capture = CaptureCoordinator(acceptsNewSources: isSelected)
    }

    func rename(to title: String) {
        name.rename(to: title)
    }
}
