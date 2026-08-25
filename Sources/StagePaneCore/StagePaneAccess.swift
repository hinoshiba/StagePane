/// The product boundary between the useful free stage and StagePane Pro.
///
/// Keep privacy, safety, and presentation controls outside this policy. Pro is
/// deliberately limited to professional scale and branding so the free app
/// remains useful before a person is asked to purchase anything.
public enum StagePaneAccess {
    public static let freeSourceLimit = 2
    public static let proSourceLimit = 4

    public static func sourceLimit(hasProAccess: Bool) -> Int {
        hasProAccess ? proSourceLimit : freeSourceLimit
    }

    public static func canAddSource(
        currentCount: Int,
        hasProAccess: Bool
    ) -> Bool {
        currentCount < sourceLimit(hasProAccess: hasProAccess)
    }

    public static func requiresProForNextSource(
        currentCount: Int,
        hasProAccess: Bool
    ) -> Bool {
        !hasProAccess &&
            currentCount >= freeSourceLimit &&
            currentCount < proSourceLimit
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
