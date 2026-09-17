import Foundation

/// Decides whether a newly computed capture surface is different enough from
/// the one the stream was actually asked for to be worth reconfiguring.
///
/// ``CaptureSurfaceSize`` rounds each axis of a fit to an even pixel
/// independently and has no hysteresis, so a source whose reported point size
/// wobbles by a fraction of a point can make the fit alternate between two
/// even sizes forever. Comparing a fresh fit against another fresh fit sees a
/// difference at every step and reconfigures at every step, and every
/// reconfiguration changes the IOSurface size and therefore forces one
/// hide/reveal cycle on the public Stage. Comparing against the size the
/// stream is running instead turns that alternation into a single decision
/// that is already satisfied.
///
/// The deadband lives here, in the decision, and never inside `fitted`: the
/// fit stays the documented budget rule, and every value this policy retains
/// is a previous `fitted` output, so the native-size, per-dimension and total
/// pixel caps hold by construction.
public enum CaptureSurfaceStability {
    /// How far the applied surface may sit from the ideal fit before it is
    /// worth paying for a reconfiguration. Two percent is a bounded sharpness
    /// cost; the letterbox it can leave inside the IOSurface is masked out by
    /// the crop projection and is therefore never visible.
    public static let relativeDeadband = 0.02

    /// A floor for small surfaces, where two percent is below the even-pixel
    /// granularity the fit rounds to and would therefore absorb nothing.
    public static let minimumPixelDeadband = 4

    /// Whether `target` differs from the surface the stream was last asked for
    /// by more than the deadband on either axis.
    ///
    /// A non-positive applied dimension always exceeds, because there is no
    /// meaningful surface to stay anchored to.
    public static func exceedsReconfigurationDeadband(
        applied: CaptureSurfaceSize,
        target: CaptureSurfaceSize,
        relativeDeadband: Double = relativeDeadband,
        minimumPixelDeadband: Int = minimumPixelDeadband
    ) -> Bool {
        exceedsDeadband(
            applied: applied.width,
            target: target.width,
            relativeDeadband: relativeDeadband,
            minimumPixelDeadband: minimumPixelDeadband
        ) || exceedsDeadband(
            applied: applied.height,
            target: target.height,
            relativeDeadband: relativeDeadband,
            minimumPixelDeadband: minimumPixelDeadband
        )
    }

    /// Returns the surface size that should actually be requested.
    ///
    /// A nil `applied` means no surface has been requested yet — session start
    /// and content replacement, where there is no frame-derived truth to stay
    /// anchored to — so the fit is authoritative and is adopted unchanged.
    /// Otherwise the applied size is kept until the target leaves its
    /// deadband, which re-anchors the band to the size that is then applied
    /// rather than letting it ratchet away from the ideal fit.
    public static func resolvedSurfaceSize(
        applied: CaptureSurfaceSize?,
        target: CaptureSurfaceSize,
        relativeDeadband: Double = relativeDeadband,
        minimumPixelDeadband: Int = minimumPixelDeadband
    ) -> CaptureSurfaceSize {
        guard let applied else { return target }
        guard !exceedsReconfigurationDeadband(
            applied: applied,
            target: target,
            relativeDeadband: relativeDeadband,
            minimumPixelDeadband: minimumPixelDeadband
        ) else { return target }
        return applied
    }

    private static func exceedsDeadband(
        applied: Int,
        target: Int,
        relativeDeadband: Double,
        minimumPixelDeadband: Int
    ) -> Bool {
        guard applied > 0 else { return true }
        guard applied != target else { return false }
        let relative = (Double(applied) * relativeDeadband).rounded()
        let allowance = max(
            minimumPixelDeadband,
            relative.isFinite ? Int(relative) : minimumPixelDeadband
        )
        return abs(target - applied) > allowance
    }
}

/// Decides whether newly reported source geometry describes a real change to
/// the shared source window, or only the sub-point wobble that ScreenCaptureKit
/// frame metadata carries while nothing is moving.
///
/// The threshold is relative with a point floor rather than a fixed fraction of
/// a point, because a half-point difference in the reported source width is
/// already enough to flip ``CaptureSurfaceSize/fitted`` by two pixels. Arming a
/// reconfiguration for that is what turned invisible metadata noise into a
/// visible tile blink.
public enum CaptureSourceGeometryChange {
    /// One percent of the previous point dimension.
    public static let relativeThreshold = 0.01

    /// A floor for small sources, and the value that stops metadata wobble from
    /// arming a reconfiguration at any source size.
    public static let minimumPointThreshold = 2.0

    /// A backing-scale change is never noise: it changes the native pixel size
    /// of the source and must be followed.
    public static let minimumScaleThreshold = 0.01

    /// Whether `geometry` is different enough from `previous` to be worth
    /// debouncing towards a reconfiguration.
    ///
    /// A nil `previous` is always meaningful: the first complete frame of a
    /// presentation is the only frame-derived truth that exists.
    public static func isMeaningful(
        _ geometry: CaptureSourceGeometry,
        comparedTo previous: CaptureSourceGeometry?
    ) -> Bool {
        guard let previous else { return true }
        return exceedsPointThreshold(
            geometry.pointWidth,
            comparedTo: previous.pointWidth
        ) || exceedsPointThreshold(
            geometry.pointHeight,
            comparedTo: previous.pointHeight
        ) || abs(
            geometry.pointPixelScale - previous.pointPixelScale
        ) >= minimumScaleThreshold
    }

    private static func exceedsPointThreshold(
        _ dimension: Double,
        comparedTo previous: Double
    ) -> Bool {
        let threshold = max(
            minimumPointThreshold,
            previous * relativeThreshold
        )
        return abs(dimension - previous) >= threshold
    }
}
