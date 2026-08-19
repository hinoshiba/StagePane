/// Events that can cause StagePane to inspect Control-mode permission state.
///
/// Only `explicitContinue` is allowed to request the macOS consent UI. Passive
/// lifecycle checks must remain silent.
public enum PreviewInputPermissionEvent: CaseIterable, Sendable {
    case explicitContinue
    case applicationActivation
    case manualRecheck
}

public struct PreviewInputPermissionState: Equatable, Sendable {
    public var isTrusted: Bool
    public var requestWasAttempted: Bool

    public init(isTrusted: Bool, requestWasAttempted: Bool) {
        self.isTrusted = isTrusted
        self.requestWasAttempted = requestWasAttempted
    }
}

public enum PreviewInputPermissionAction: Equatable, Sendable {
    /// The caller only needs the permission refresh it already performed.
    case refreshOnly
    /// Ask macOS to show consent UI in response to the explicit user action.
    case requestSystemPrompt
    /// Recheck and show repair guidance instead of repeating the system prompt.
    case reviewRepair
}

public struct PreviewInputPermissionTransition: Equatable, Sendable {
    public let state: PreviewInputPermissionState
    public let action: PreviewInputPermissionAction

    public init(
        state: PreviewInputPermissionState,
        action: PreviewInputPermissionAction
    ) {
        self.state = state
        self.action = action
    }
}

/// Pure request policy for the Control-mode Accessibility permission.
///
/// Actual trust remains authoritative and is supplied by the caller after a
/// nonprompting TCC check. This type deliberately has no AppKit or TCC imports,
/// making the "prompt once, only when explicit" contract unit testable.
public enum PreviewInputPermissionPolicy {
    /// Migrates builds that predate the one-time request preference.
    ///
    /// An existing ad-hoc installation has a different macOS code identity
    /// after a rebuild, so repeating the system request cannot repair its stale
    /// TCC row. Fresh installs and consistently signed builds keep the normal
    /// one-time explicit request path.
    public static func initialRequestWasAttempted(
        storedValue: Bool?,
        isAdHocDevelopmentBuild: Bool,
        hadExistingInstallationPreferences: Bool
    ) -> Bool {
        if let storedValue { return storedValue }
        return isAdHocDevelopmentBuild && hadExistingInstallationPreferences
    }

    public static func transition(
        from state: PreviewInputPermissionState,
        for event: PreviewInputPermissionEvent
    ) -> PreviewInputPermissionTransition {
        guard !state.isTrusted else {
            return PreviewInputPermissionTransition(
                state: state,
                action: .refreshOnly
            )
        }

        switch event {
        case .applicationActivation, .manualRecheck:
            return PreviewInputPermissionTransition(
                state: state,
                action: .refreshOnly
            )
        case .explicitContinue:
            guard state.requestWasAttempted else {
                var nextState = state
                nextState.requestWasAttempted = true
                return PreviewInputPermissionTransition(
                    state: nextState,
                    action: .requestSystemPrompt
                )
            }
            return PreviewInputPermissionTransition(
                state: state,
                action: .reviewRepair
            )
        }
    }
}
