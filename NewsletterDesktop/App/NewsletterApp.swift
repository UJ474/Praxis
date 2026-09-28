import SwiftUI
import AppKit
import ServiceManagement

@main
struct NewsletterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("3-2-1", systemImage: "newspaper") {
            Button("Show desktop edition") { delegate.desktopController?.showWindow(nil) }
            Button("Hide desktop edition") { delegate.desktopController?.window?.orderOut(nil) }
            Divider()
            Button("Refresh") { Task { await delegate.store.refresh() } }
            Button("Sync newsletter now") { Task { await delegate.store.refreshNow() } }
            Button("Connect Gmail") { delegate.store.connectGmail() }
            SettingsLink { Text("Connection Settings…") }
            Divider()
            Button("Quit 3-2-1") { NSApp.terminate(nil) }
        }
        .menuBarExtraStyle(.menu)
        Settings { ConnectionSettingsView(store: delegate.store) }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = DesktopStore()
    var desktopController: DesktopWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        try? SMAppService.mainApp.register()
        desktopController = DesktopWindowController(store: store)
        desktopController?.showWindow(nil)
        Task { await store.refresh() }
    }
}
