/// Determines what a pointer gesture in the private Stage canvas means.
///
/// The modes are deliberately mutually exclusive: a drag rearranges a source,
/// edits its local crop, edits the Stage-wide annotation layer, or points a lens.
public enum StageInteractionMode: String, CaseIterable, Codable, Sendable {
    case arrange
    case crop
    case annotate
    case magnify

    /// Drawing and magnifying own the audience's visual attention, so captured system
    /// cursors and the local laser overlay stay hidden until Arrange or Crop
    /// resumes.
    public var suppressesAudiencePointer: Bool {
        self == .annotate || self == .magnify
    }

    /// Applies the temporary mode policy without mutating the preference that
    /// a non-drawing mode must restore later.
    public func audiencePointerStyle(preferred: PointerStyle) -> PointerStyle {
        suppressesAudiencePointer ? .hidden : preferred
    }
}
