/// Determines what a pointer gesture in the private Stage canvas means.
///
/// The modes are deliberately mutually exclusive: a drag either rearranges a
/// source or edits the local annotation layer.
public enum StageInteractionMode: String, CaseIterable, Codable, Sendable {
    case arrange
    case annotate

    /// Drawing owns the audience's visual attention, so captured system
    /// cursors and the local laser overlay stay hidden until Arrange resumes.
    public var suppressesAudiencePointer: Bool {
        self == .annotate
    }

    /// Applies the temporary mode policy without mutating the preference that
    /// Arrange must restore later.
    public func audiencePointerStyle(preferred: PointerStyle) -> PointerStyle {
        suppressesAudiencePointer ? .hidden : preferred
    }
}
