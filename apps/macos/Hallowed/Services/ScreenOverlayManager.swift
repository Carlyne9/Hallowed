import AppKit
import SwiftUI

/// Manages full-screen prayer overlays across all connected displays.
/// This is a stub implementation — ChimeAlert will replace the internals later.
@MainActor
class ScreenOverlayManager: ObservableObject {
    static let shared = ScreenOverlayManager()

    private var overlayWindows: [NSWindow] = []

    private init() {}

    /// Presents a full-screen prayer overlay on every connected screen.
    /// - Parameters:
    ///   - prayer: The prayer to display.
    ///   - topic: The topic the prayer belongs to.
    ///   - theme: The theme the topic belongs to.
    ///   - onComplete: Called when the user completes or dismisses the session.
    func show(
        prayer: Prayer,
        topic: PrayerTopic,
        theme: PrayerTheme,
        durationMinutes: Int,
        appEnv: AppEnvironment,
        onComplete: @escaping () -> Void = {}
    ) {
        // Hide the dock and menu bar so nothing bleeds through
        NSApp.presentationOptions = [.hideDock, .hideMenuBar, .disableAppleMenu]

        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .stationary]
            window.isOpaque = true
            window.backgroundColor = .black
            window.isReleasedWhenClosed = false
            window.setFrame(screen.frame, display: true)

            let sessionView = SessionView(
                prayer: prayer,
                topic: topic,
                theme: theme,
                durationMinutes: durationMinutes,
                onComplete: {
                    onComplete()
                    self.dismiss()
                }
            )
            .environmentObject(appEnv)
            window.contentView = NSHostingView(rootView: sessionView)
            window.makeKeyAndOrderFront(nil)
            overlayWindows.append(window)
        }
    }

    /// Dismisses all overlays and restores normal system UI.
    func dismiss() {
        overlayWindows.forEach { $0.orderOut(nil) }
        overlayWindows.removeAll()
        NSApp.presentationOptions = []
    }
}
