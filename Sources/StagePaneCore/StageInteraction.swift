/// Determines what a pointer gesture in the private Stage canvas means.
///
/// The modes are deliberately mutually exclusive: a drag either rearranges a
/// source or edits the local annotation layer.
public enum StageInteractionMode: String, CaseIterable, Codable, Sendable {
    case arrange
    case annotate
}
