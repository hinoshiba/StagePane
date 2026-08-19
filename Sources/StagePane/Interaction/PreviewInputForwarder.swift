import AppKit
#if !STAGEPANE_APP_STORE
@preconcurrency import ApplicationServices
#endif
import CoreGraphics
import ScreenCaptureKit
import StagePaneCore

/// An exact, picker-authorized window destination for preview input.
///
/// Callers should resolve this from the current `SCContentFilter` immediately
/// before posting. A display or application capture is intentionally never
/// represented because neither identifies one destination window.
struct PreviewWindowInputDestination: Equatable, Sendable {
    let sourceID: StageSourceID
    let windowID: CGWindowID
    let processIdentifier: pid_t
    let bundleIdentifier: String

    init?(
        sourceID: StageSourceID,
        windowID: CGWindowID,
        processIdentifier: pid_t,
        bundleIdentifier: String
    ) {
        let trimmedBundleIdentifier = bundleIdentifier.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard windowID != 0,
              processIdentifier > 0,
              !trimmedBundleIdentifier.isEmpty else { return nil }
        self.sourceID = sourceID
        self.windowID = windowID
        self.processIdentifier = processIdentifier
        self.bundleIdentifier = trimmedBundleIdentifier
    }
}

enum PreviewInputForwardingFailure: Error, Equatable, Sendable {
    case unavailableInThisBuild
    case requiresMacOS15_2
    case unsupportedSourceKind
    case sourceIsNotExactlyOneWindow
    case sourceWindowIsNotOnScreen
    case invalidWindowMetadata
    case accessibilityAccessRequired
    case invalidPoint
    case targetApplicationUnavailable
    case accessibilityHitTestFailed
    case accessibilityActionUnsupported
    case accessibilityActionFailed
    case accessibilityActionOutcomeUnknown
    case selectedWindowMismatch
    case sourceTemporarilyUnavailable
    case staleDisplayedFrame
    case sourceIsNotFrontmost
}

struct ResolvedPreviewInputClick: Sendable {
    let destination: PreviewWindowInputDestination
    let globalPoint: CGPoint
    let displayedWindowFrame: CGRect
    let captureActionTicket: PreviewInteractionActionTicket
}

enum PreviewInputDestinationResolver {
    /// Uses only metadata exposed by the user-approved ScreenCaptureKit filter.
    /// It does not enumerate unrelated windows or infer a target by title.
    static func destination(
        for sourceID: StageSourceID,
        filter: SCContentFilter
    ) -> Result<PreviewWindowInputDestination, PreviewInputForwardingFailure> {
        guard #available(macOS 15.2, *) else {
            return .failure(.requiresMacOS15_2)
        }
        guard filter.style == .window else {
            return .failure(.unsupportedSourceKind)
        }
        guard filter.includedWindows.count == 1,
              let window = filter.includedWindows.first else {
            return .failure(.sourceIsNotExactlyOneWindow)
        }
        guard window.isOnScreen else {
            return .failure(.sourceWindowIsNotOnScreen)
        }
        guard let application = window.owningApplication,
              let destination = PreviewWindowInputDestination(
                  sourceID: sourceID,
                  windowID: window.windowID,
                  processIdentifier: application.processID,
                  bundleIdentifier: application.bundleIdentifier
              ) else {
            return .failure(.invalidWindowMetadata)
        }
        return .success(destination)
    }
}

enum PreviewInputForwardingResult: Equatable, Sendable {
    case posted
    case rejected(PreviewInputForwardingFailure)
}

/// Performs one accessibility press in the picker-authorized source application
/// without moving the physical cursor or activating that application. The
/// application-scoped hit test prevents another app covering the source on the
/// real desktop from stealing the action.
#if STAGEPANE_APP_STORE
@MainActor
final class PreviewInputForwarder {
    var hasPostEventAccess: Bool { false }

    @discardableResult
    func requestPostEventAccess() -> Bool { false }

    func cancelPendingActions() {}

    func performSupportedPress(
        atGlobalPoint _: CGPoint,
        to _: PreviewWindowInputDestination,
        displayedWindowFrame _: CGRect,
        captureActionTicket _: PreviewInteractionActionTicket,
        completion: @escaping @MainActor @Sendable (
            PreviewInputForwardingResult
        ) -> Void
    ) {
        completion(.rejected(.unavailableInThisBuild))
    }
}
#else
@MainActor
final class PreviewInputForwarder {
    private let actionExecutor = PreviewAccessibilityActionExecutor()
    private var isActionInFlight = false
    private var activeActionTicket: PreviewInteractionActionTicket?

    var hasPostEventAccess: Bool {
        AXIsProcessTrusted()
    }

    /// Call only in direct response to a user action that enables Control mode.
    /// The system may present its consent UI.
    @discardableResult
    func requestPostEventAccess() -> Bool {
        if AXIsProcessTrusted() { return true }
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([
            promptKey: true
        ] as CFDictionary)
    }

    func cancelPendingActions() {
        activeActionTicket?.invalidate()
    }

    func performSupportedPress(
        atGlobalPoint globalPoint: CGPoint,
        to destination: PreviewWindowInputDestination,
        displayedWindowFrame: CGRect,
        captureActionTicket: PreviewInteractionActionTicket,
        completion: @escaping @MainActor @Sendable (
            PreviewInputForwardingResult
        ) -> Void
    ) {
        guard hasPostEventAccess else {
            completion(.rejected(.accessibilityAccessRequired))
            return
        }
        guard globalPoint.x.isFinite, globalPoint.y.isFinite else {
            completion(.rejected(.invalidPoint))
            return
        }
        guard !isActionInFlight else {
            completion(.rejected(.sourceTemporarilyUnavailable))
            return
        }
        isActionInFlight = true
        activeActionTicket = captureActionTicket
        actionExecutor.perform(
            atGlobalPoint: globalPoint,
            destination: destination,
            displayedWindowFrame: displayedWindowFrame,
            captureActionTicket: captureActionTicket
        ) { [weak self] result in
            guard let self else { return }
            isActionInFlight = false
            if activeActionTicket === captureActionTicket {
                activeActionTicket = nil
            }
            completion(result)
        }
    }
}

/// Accessibility messaging is synchronous IPC. Keeping every AX object and
/// call on this private queue prevents an unresponsive source application from
/// freezing Control Room. Timeouts are applied to every element because AX
/// messaging timeouts are object-local and are not inherited by child objects.
private final class PreviewAccessibilityActionExecutor: @unchecked Sendable {
    private static let messagingTimeout: Float = 0.16
    private static let maximumAncestorDepth = 8
    private static let windowFrameTolerance: CGFloat = 2

    private let queue = DispatchQueue(
        label: "com.hinoshiba.stagepane.preview-input",
        qos: .userInitiated
    )

    func perform(
        atGlobalPoint globalPoint: CGPoint,
        destination: PreviewWindowInputDestination,
        displayedWindowFrame: CGRect,
        captureActionTicket: PreviewInteractionActionTicket,
        completion: @escaping @MainActor @Sendable (
            PreviewInputForwardingResult
        ) -> Void
    ) {
        queue.async {
            let result = Self.performSynchronously(
                atGlobalPoint: globalPoint,
                destination: destination,
                displayedWindowFrame: displayedWindowFrame,
                captureActionTicket: captureActionTicket
            )
            Task { @MainActor in
                completion(result)
            }
        }
    }

    private static func performSynchronously(
        atGlobalPoint globalPoint: CGPoint,
        destination: PreviewWindowInputDestination,
        displayedWindowFrame: CGRect,
        captureActionTicket: PreviewInteractionActionTicket
    ) -> PreviewInputForwardingResult {
        guard captureActionTicket.isValid else {
            return .rejected(.sourceTemporarilyUnavailable)
        }
        guard targetApplicationIsCurrent(destination) else {
            return .rejected(.targetApplicationUnavailable)
        }
        guard let initialWindowFrame = selectedWindowProof(
            destination,
            at: globalPoint,
            displayedWindowFrame: displayedWindowFrame
        ) else {
            return .rejected(.selectedWindowMismatch)
        }

        let applicationElement = AXUIElementCreateApplication(
            destination.processIdentifier
        )
        applyMessagingTimeout(to: applicationElement)
        var hitElement: AXUIElement?
        let hitError = AXUIElementCopyElementAtPosition(
            applicationElement,
            Float(globalPoint.x),
            Float(globalPoint.y),
            &hitElement
        )
        guard hitError == .success, let hitElement else {
            return .rejected(.accessibilityHitTestFailed)
        }
        applyMessagingTimeout(to: hitElement)
        var hitPID: pid_t = 0
        guard AXUIElementGetPid(hitElement, &hitPID) == .success,
              hitPID == destination.processIdentifier else {
            return .rejected(.targetApplicationUnavailable)
        }
        guard selectedAXWindowMatches(initialWindowFrame, for: hitElement) else {
            return .rejected(.selectedWindowMismatch)
        }
        guard let pressableElement = firstPressableElement(startingAt: hitElement) else {
            return .rejected(.accessibilityActionUnsupported)
        }
        guard let finalWindowFrame = selectedWindowProof(
            destination,
            at: globalPoint,
            displayedWindowFrame: displayedWindowFrame
        ),
        framesMatch(
            finalWindowFrame,
            initialWindowFrame,
            tolerance: windowFrameTolerance
        ),
        selectedAXWindowMatches(finalWindowFrame, for: pressableElement) else {
            return .rejected(.selectedWindowMismatch)
        }
        applyMessagingTimeout(to: pressableElement)
        guard captureActionTicket.commitIfValid() else {
            return .rejected(.sourceTemporarilyUnavailable)
        }
        let actionError = AXUIElementPerformAction(
            pressableElement,
            kAXPressAction as CFString
        )
        switch actionError {
        case .success:
            return .posted
        case .cannotComplete:
            // Accessibility timeouts are ambiguous: the source may have
            // completed the action after the IPC call timed out. Never invite
            // an immediate retry that could press the control twice.
            return .rejected(.accessibilityActionOutcomeUnknown)
        case .actionUnsupported:
            return .rejected(.accessibilityActionUnsupported)
        default:
            return .rejected(.accessibilityActionFailed)
        }
    }

    private static func targetApplicationIsCurrent(
        _ destination: PreviewWindowInputDestination
    ) -> Bool {
        guard destination.processIdentifier != getpid(),
              let application = NSRunningApplication(
                  processIdentifier: destination.processIdentifier
              ),
              !application.isTerminated else { return false }
        return application.bundleIdentifier == destination.bundleIdentifier
    }

    /// CGWindowList is ordered front-to-back and exposes the picker window ID.
    /// A sibling above the selected window can steal the hit. A sibling below
    /// it with an indistinguishable frame is also unsafe because an ignored AX
    /// window can make the application-scoped hit test fall through to it.
    private static func selectedWindowProof(
        _ destination: PreviewWindowInputDestination,
        at globalPoint: CGPoint,
        displayedWindowFrame: CGRect
    ) -> CGRect? {
        guard let rawWindows = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else { return nil }

        var selectedBounds: CGRect?
        for rawWindow in rawWindows {
            guard (rawWindow[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value ==
                    destination.processIdentifier else { continue }
            guard let boundsDictionary = rawWindow[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: boundsDictionary),
                  let number = rawWindow[kCGWindowNumber as String] as? NSNumber
            else { return nil }

            if CGWindowID(number.uint32Value) == destination.windowID {
                guard bounds.contains(globalPoint),
                      framesMatch(
                          bounds,
                          displayedWindowFrame,
                          tolerance: windowFrameTolerance
                      ) else { return nil }
                selectedBounds = bounds
                continue
            }
            guard bounds.contains(globalPoint) else { continue }
            guard let selectedBounds else {
                // Another same-process window is above the picker-authorized
                // window at the requested point.
                return nil
            }
            if framesMatch(
                bounds,
                selectedBounds,
                tolerance: windowFrameTolerance
            ) {
                // Public AX has no CGWindowID attribute. A lower sibling with
                // the same frame cannot be distinguished if AX skips the
                // selected window, so fail closed.
                return nil
            }
        }
        return selectedBounds
    }

    private static func firstPressableElement(
        startingAt element: AXUIElement
    ) -> AXUIElement? {
        var current: AXUIElement? = element
        for _ in 0 ..< maximumAncestorDepth {
            guard let candidate = current else { return nil }
            applyMessagingTimeout(to: candidate)
            var actionNames: CFArray?
            if AXUIElementCopyActionNames(candidate, &actionNames) == .success,
               let names = actionNames as? [String],
               names.contains(kAXPressAction as String) {
                return candidate
            }
            current = elementAttribute(kAXParentAttribute as CFString, of: candidate)
        }
        return nil
    }

    private static func selectedAXWindowMatches(
        _ expectedFrame: CGRect,
        for element: AXUIElement
    ) -> Bool {
        guard let window = elementAttribute(kAXWindowAttribute as CFString, of: element) else {
            return false
        }
        applyMessagingTimeout(to: window)
        guard let position = pointAttribute(kAXPositionAttribute as CFString, of: window),
              let size = sizeAttribute(kAXSizeAttribute as CFString, of: window) else {
            return false
        }
        return framesMatch(
            CGRect(origin: position, size: size),
            expectedFrame,
            tolerance: windowFrameTolerance
        )
    }

    private static func framesMatch(
        _ lhs: CGRect,
        _ rhs: CGRect,
        tolerance: CGFloat
    ) -> Bool {
        abs(lhs.minX - rhs.minX) <= tolerance &&
            abs(lhs.minY - rhs.minY) <= tolerance &&
            abs(lhs.width - rhs.width) <= tolerance &&
            abs(lhs.height - rhs.height) <= tolerance
    }

    private static func applyMessagingTimeout(to element: AXUIElement) {
        _ = AXUIElementSetMessagingTimeout(element, messagingTimeout)
    }

    private static func elementAttribute(
        _ attribute: CFString,
        of element: AXUIElement
    ) -> AXUIElement? {
        applyMessagingTimeout(to: element)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let value,
              CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        let result = unsafeBitCast(value, to: AXUIElement.self)
        applyMessagingTimeout(to: result)
        return result
    }

    private static func pointAttribute(
        _ attribute: CFString,
        of element: AXUIElement
    ) -> CGPoint? {
        applyMessagingTimeout(to: element)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let value,
              CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        var point = CGPoint.zero
        let axValue = unsafeBitCast(value, to: AXValue.self)
        return AXValueGetValue(axValue, .cgPoint, &point) ? point : nil
    }

    private static func sizeAttribute(
        _ attribute: CFString,
        of element: AXUIElement
    ) -> CGSize? {
        applyMessagingTimeout(to: element)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let value,
              CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        var size = CGSize.zero
        let axValue = unsafeBitCast(value, to: AXValue.self)
        return AXValueGetValue(axValue, .cgSize, &size) ? size : nil
    }
}
#endif
