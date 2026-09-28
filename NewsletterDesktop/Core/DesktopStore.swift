import SwiftUI
import AppKit

@MainActor
final class DesktopStore: ObservableObject {
    @Published var newsletter = NewsletterEntry.preview
    @Published var tasks: [TaskItem] = []
    @Published var isEditing = false
    @Published var errorMessage: String?
    private let api = APIClient()

    func refresh() async {
        do { async let n = api.latestNewsletter(); async let t = api.tasks(for: Self.monday()); newsletter = try await n; tasks = try await t; errorMessage = nil }
        catch { errorMessage = error.localizedDescription }
    }
    func refreshNow() async {
        do { async let n = api.syncNewsletter(); async let t = api.tasks(for: Self.monday()); newsletter = try await n; tasks = try await t; errorMessage = nil }
        catch { errorMessage = error.localizedDescription }
    }
    func verifyConnection() async -> String { do { try await api.healthCheck(); return "Connected" } catch { return error.localizedDescription } }
    func connectGmail() { if let url = api.gmailAuthorizationURL() { NSWorkspace.shared.open(url) } }
    func save(_ task: TaskItem) async { do { let saved = try await api.save(task); tasks.append(saved) } catch { errorMessage = error.localizedDescription } }
    func update(_ task: TaskItem) async { do { let saved = try await api.update(task); if let i = tasks.firstIndex(where: { $0.id == saved.id }) { tasks[i] = saved } } catch { errorMessage = error.localizedDescription } }
    static func monday(_ date: Date = .now) -> Date { Calendar.current.dateInterval(of: .weekOfYear, for: date)?.start ?? date }
}
