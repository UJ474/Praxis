import AppKit
import SwiftUI

final class DesktopWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    // When a click arrives inside the window while it is not the key window,
    // make it key so NSTextView can accept first-responder and the user can type.
    override func mouseDown(with event: NSEvent) {
        if !isKeyWindow { makeKey() }
        super.mouseDown(with: event)
    }
}

final class DesktopWindowController: NSWindowController, NSWindowDelegate {
    init(store: DesktopStore) {
        let frame = NSRect(x: 70, y: 90, width: 1080, height: 720)
        let window = DesktopWindow(contentRect: frame, styleMask: [.borderless, .resizable], backing: .buffered, defer: false)
        // desktopIconWindow+1 keeps us above Finder icons but below all normal app windows.
        // This is the same level used by macOS widgets.
        window.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .transient, .fullScreenAuxiliary]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isMovableByWindowBackground = false  // drag is handled by WindowDragStrip
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.hidesOnDeactivate = false
        window.isExcludedFromWindowsMenu = true
        window.minSize = NSSize(width: 620, height: 440)
        window.setFrameAutosaveName("NewsletterDesktopWindow")
        window.contentView = NSHostingView(rootView: DesktopRootView(store: store))
        super.init(window: window)
        window.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(placeWindow(_:)), name: .placeDesktopEdition, object: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func windowShouldClose(_ sender: NSWindow) -> Bool { sender.orderOut(nil); return false }
    func windowDidMove(_ notification: Notification) { window?.saveFrame(usingName: "NewsletterDesktopWindow") }
    func windowDidResize(_ notification: Notification) { window?.saveFrame(usingName: "NewsletterDesktopWindow") }
    @objc private func placeWindow(_ notification: Notification) {
        guard let window, let placement = notification.object as? DesktopPlacement, let screen = window.screen ?? NSScreen.main else { return }
        let visible = screen.visibleFrame; var frame = window.frame
        frame.origin.y = max(visible.minY + 20, min(frame.origin.y, visible.maxY - frame.height - 20))
        switch placement { case .left: frame.origin.x = visible.minX + 24; case .center: frame.origin.x = visible.midX - frame.width / 2; case .right: frame.origin.x = visible.maxX - frame.width - 24 }
        window.setFrame(frame, display: true, animate: true); window.saveFrame(usingName: "NewsletterDesktopWindow")
    }
}

enum DesktopPlacement { case left, center, right }
extension Notification.Name { static let placeDesktopEdition = Notification.Name("placeDesktopEdition") }
