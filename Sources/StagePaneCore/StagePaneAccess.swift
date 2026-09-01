/// The product boundary between the useful free stage and StagePane Pro.
///
/// Keep privacy, safety, and presentation controls outside this policy. Pro is
/// deliberately focused on professional scale and branding so the free app
/// remains useful before a person is asked to purchase anything.
public enum StagePaneAccess {
    public static let freeSourceLimit = 4

    /// The app-enforced simultaneous-source limit for the current plan.
    ///
    /// `nil` means StagePane does not impose a count limit. The number of
    /// streams a Mac can sustain can still vary with macOS and hardware.
    public static func sourceLimit(hasProAccess: Bool) -> Int? {
        hasProAccess ? nil : freeSourceLimit
    }

    public static func canAddSource(
        currentCount: Int,
        hasProAccess: Bool
    ) -> Bool {
        canAddSource(
            currentCount: currentCount,
            sourceLimit: sourceLimit(hasProAccess: hasProAccess)
        )
    }

    /// Applies an already-resolved plan limit at capture-system boundaries.
    public static func canAddSource(
        currentCount: Int,
        sourceLimit: Int?
    ) -> Bool {
        guard let sourceLimit else {
            return true
        }
        return currentCount < sourceLimit
    }

    public static func requiresProForNextSource(
        currentCount: Int,
        hasProAccess: Bool
    ) -> Bool {
        !hasProAccess &&
            currentCount >= freeSourceLimit
    }

    /// Resolves the visible mark independently from the stored preference.
    ///
    /// A person may have a legacy `false` preference from a build that offered
    /// this setting for free. Keeping that preference is convenient after a
    /// purchase, but it must never become an entitlement cache or bypass.
    public static func showsWatermark(
        preference: Bool,
        hasProAccess: Bool
    ) -> Bool {
        hasProAccess ? preference : true
    }
}
