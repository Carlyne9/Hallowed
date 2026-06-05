import AppKit
import SwiftUI

/// Manages full-screen prayer overlays across all connected displays.
/// This is a stub implementation — ChimeAlert will replace the internals later.
@MainActor
class ScreenOverlayManager: ObservableObject {
    static let shared = ScreenOverlayManager()

    private struct ActiveSession {
        let prayer: Prayer
        let topic: PrayerTopic
        let theme: PrayerTheme
        let durationMinutes: Int
        let pacesPrayerPoints: Bool
        let lifecycle: PrayerSessionLifecycle
        let appEnv: AppEnvironment
        let onComplete: () -> Void
    }

    private var overlayWindows: [NSWindow] = []
    private var activeSession: ActiveSession?
    private var observers: [NSObjectProtocol] = []
    private var activityToken: NSObjectProtocol?
    private var reinforcementTimer: Timer?

    var isPresentingSession: Bool {
        activeSession != nil
    }

    private init() {}

    /// Presents a full-screen prayer overlay on every connected screen.
    /// - Parameters:
    ///   - prayer: The prayer to display.
    ///   - topic: The topic the prayer belongs to.
    ///   - theme: The theme the topic belongs to.
    ///   - periodId: The scheduled prayer period that launched the session, if any.
    ///   - onComplete: Called when the user completes or dismisses the session.
    func show(
        prayer: Prayer,
        topic: PrayerTopic,
        theme: PrayerTheme,
        durationMinutes: Int,
        pacesPrayerPoints: Bool = false,
        periodId: UUID? = nil,
        shouldLogContentIDs: Bool = true,
        appEnv: AppEnvironment,
        onComplete: @escaping () -> Void = {}
    ) {
        // Replace any existing overlay session cleanly.
        teardownWindows()

        activeSession = ActiveSession(
            prayer: prayer,
            topic: topic,
            theme: theme,
            durationMinutes: durationMinutes,
            pacesPrayerPoints: pacesPrayerPoints,
            lifecycle: PrayerSessionLifecycle(
                periodId: periodId,
                shouldLogContentIDs: shouldLogContentIDs
            ),
            appEnv: appEnv,
            onComplete: onComplete
        )

        // Hide desktop chrome so nothing bleeds through.
        var presentation: NSApplication.PresentationOptions = [.hideDock, .hideMenuBar, .disableAppleMenu]
        if SessionPreferences.isStrictModeEnabled {
            presentation.insert(.disableProcessSwitching)
        }
        NSApp.presentationOptions = presentation
        // Bring the app forward before presenting overlays.
        NSApp.activate(ignoringOtherApps: true)
        // Keep app responsive while in takeover.
        activityToken = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled],
            reason: "Hallowed prayer session overlay"
        )

        installObserversIfNeeded()
        buildWindowsFromActiveSession()
        reassertForeground()
        startReinforcementTimer()
    }

    private func buildWindowsFromActiveSession() {
        guard let session = activeSession else { return }

        for screen in NSScreen.screens {
            let window = OverlayWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.level = .screenSaver
            window.collectionBehavior = [
                .canJoinAllSpaces,
                .fullScreenAuxiliary,
                .fullScreenDisallowsTiling,
                .stationary,
                .ignoresCycle,
            ]
            window.hidesOnDeactivate = false
            window.isReleasedWhenClosed = false
            window.isOpaque = true
            window.backgroundColor = .black
            window.setFrame(screen.frame, display: true)

            let sessionView = SessionView(
                prayer: session.prayer,
                topic: session.topic,
                theme: session.theme,
                durationMinutes: session.durationMinutes,
                pacesPrayerPoints: session.pacesPrayerPoints,
                lifecycle: session.lifecycle,
                onComplete: {
                    session.onComplete()
                    self.dismiss()
                }
            )
            .environmentObject(session.appEnv)

            window.contentView = NSHostingView(rootView: sessionView)
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            overlayWindows.append(window)
        }
    }

    private func reinstallWindows() {
        guard activeSession != nil else { return }
        teardownWindows()
        buildWindowsFromActiveSession()
        reassertForeground()
    }

    private func reassertForeground() {
        guard !overlayWindows.isEmpty else { return }
        NSApp.activate(ignoringOtherApps: true)
        overlayWindows.forEach {
            $0.orderFrontRegardless()
            $0.makeKey()
        }
    }

    private func installObserversIfNeeded() {
        guard observers.isEmpty else { return }

        let center = NotificationCenter.default
        let workspaceCenter = NSWorkspace.shared.notificationCenter

        observers.append(
            center.addObserver(
                forName: NSApplication.didResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.reassertForeground()
            }
        )

        observers.append(
            center.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.reinstallWindows()
            }
        )

        observers.append(
            workspaceCenter.addObserver(
                forName: NSWorkspace.activeSpaceDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.reinstallWindows()
            }
        )
    }

    private func removeObservers() {
        let center = NotificationCenter.default
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        observers.forEach {
            center.removeObserver($0)
            workspaceCenter.removeObserver($0)
        }
        observers.removeAll()
    }

    private func startReinforcementTimer() {
        reinforcementTimer?.invalidate()
        let interval = SessionPreferences.isStrictModeEnabled ? 0.75 : 1.5
        reinforcementTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.reassertForeground()
            }
        }
    }

    private func stopReinforcementTimer() {
        reinforcementTimer?.invalidate()
        reinforcementTimer = nil
    }

    private func teardownWindows() {
        overlayWindows.forEach { $0.orderOut(nil) }
        overlayWindows.removeAll()
    }

    /// Dismisses all overlays and restores normal system UI.
    func dismiss() {
        teardownWindows()
        activeSession = nil
        removeObservers()
        stopReinforcementTimer()
        if let activityToken {
            ProcessInfo.processInfo.endActivity(activityToken)
            self.activityToken = nil
        }
        NSApp.presentationOptions = []
    }
}

private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
