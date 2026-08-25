import Foundation

/// A conservative, satisfaction-based gate for asking the system to consider
/// showing its rating prompt. StoreKit remains responsible for whether a
/// prompt actually appears.
public enum ReviewPromptPolicy {
    public static let requiredSuccessfulSessions = 3
    public static let minimumSuccessfulSessionDuration: TimeInterval = 60
    public static let minimumExperience: TimeInterval = 3 * 24 * 60 * 60

    public static func qualifiesAsSuccessfulSession(
        duration: TimeInterval,
        needsAttention: Bool,
        reachedPreview: Bool
    ) -> Bool {
        reachedPreview &&
            !needsAttention &&
            duration >= minimumSuccessfulSessionDuration
    }

    public static func shouldRequestReview(
        successfulSessionCount: Int,
        firstSuccessfulSessionDate: Date?,
        lastRequestedVersion: String?,
        currentVersion: String,
        now: Date
    ) -> Bool {
        guard successfulSessionCount >= requiredSuccessfulSessions,
              let firstSuccessfulSessionDate,
              now.timeIntervalSince(firstSuccessfulSessionDate) >= minimumExperience,
              !currentVersion.isEmpty,
              lastRequestedVersion != currentVersion else { return false }
        return true
    }
}
