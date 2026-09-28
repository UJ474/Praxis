import SwiftUI

struct DesktopRootView: View {
    @ObservedObject var store: DesktopStore
    var body: some View {
        ZStack {
            VisualEffect(material: .hudWindow, blendingMode: .behindWindow)
            GeometryReader { proxy in
                let twoColumns = proxy.size.width > 900
                Group {
                    if twoColumns {
                        HStack(alignment: .top, spacing: 0) {
                            newsletter.frame(maxWidth: .infinity)
                            Rule(vertical: true)
                            tasks.frame(maxWidth: .infinity)
                        }
                    } else {
                        VStack(spacing: 0) {
                            newsletter.frame(maxHeight: proxy.size.height * 0.5)
                            Rule(vertical: false)
                            tasks
                        }
                    }
                }
                .padding(.top, 48)   // leave room for top chrome
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(nil)
        // Top chrome: drag strip + Edit button on same row
        .overlay(alignment: .top) {
            HStack {
                WindowDragStrip().frame(maxWidth: .infinity, maxHeight: 32)
                EditControl(store: store).padding(.trailing, 18)
            }
            .frame(height: 40)
        }
        .overlay(alignment: .bottomLeading) {
            if let error = store.errorMessage {
                Text(error)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(12)
            }
        }
    }
    private var newsletter: some View {
        NewsletterView(entry: store.newsletter)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.trailing, 20)
    }
    private var tasks: some View {
        EisenhowerView(store: store)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.leading, 20)
    }
}

private struct EditControl: View {
    @ObservedObject var store: DesktopStore
    var body: some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.18)) { store.isEditing.toggle() } }) {
            HStack(spacing: 5) {
                Image(systemName: store.isEditing ? "checkmark.circle.fill" : "pencil")
                    .font(.system(size: 11, weight: .semibold))
                Text(store.isEditing ? "Done" : "Edit")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                store.isEditing
                    ? Color.orange.opacity(0.18)
                    : Color.primary.opacity(0.06)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        store.isEditing ? Color.orange.opacity(0.6) : Color.primary.opacity(0.18),
                        lineWidth: 0.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .foregroundStyle(store.isEditing ? Color.orange : Color.primary.opacity(0.7))
        }
        .buttonStyle(.plain)
        .font(.system(size: 11, weight: .medium, design: .monospaced))
    }
}

struct Rule: View {
    let vertical: Bool
    var body: some View {
        Rectangle().fill(.primary.opacity(0.18))
            .frame(maxWidth: vertical ? 0.5 : .infinity, maxHeight: vertical ? .infinity : 0.5)
    }
}

struct VisualEffect: NSViewRepresentable {
    let material: NSVisualEffectView.Material; let blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView { let view = NSVisualEffectView(); view.material = material; view.blendingMode = blendingMode; view.state = .active; return view }
    func updateNSView(_ view: NSVisualEffectView, context: Context) { view.material = material; view.blendingMode = blendingMode }
}

private struct WindowDragStrip: NSViewRepresentable {
    func makeNSView(context: Context) -> DragView { DragView() }
    func updateNSView(_ view: DragView, context: Context) {}
}
private final class DragView: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .openHand)
    }
}
