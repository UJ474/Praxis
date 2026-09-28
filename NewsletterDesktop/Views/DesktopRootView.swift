import SwiftUI

struct DesktopRootView: View {
    @ObservedObject var store: DesktopStore
    var body: some View {
        ZStack {
            VisualEffect(material: .hudWindow, blendingMode: .behindWindow)
            GeometryReader { proxy in
                let twoColumns = proxy.size.width > 900
                Group {
                    if twoColumns { HStack(alignment: .top, spacing: 0) { newsletter; Rule(vertical: true); tasks } }
                    else { VStack(spacing: 0) { newsletter; Rule(vertical: false); tasks } }
                }
                .padding(28)
            }
        }
        .preferredColorScheme(nil)
        .overlay(alignment: .top) { WindowDragStrip().frame(height: 30).padding(.horizontal, 10) }
        .overlay(alignment: .topTrailing) { EditControl(store: store).padding(18) }
        .overlay(alignment: .bottomLeading) { if let error = store.errorMessage { Text(error).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary).padding(12) } }
    }
    private var newsletter: some View { NewsletterView(entry: store.newsletter).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(.trailing, 24) }
    private var tasks: some View { EisenhowerView(store: store).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(.leading, 24) }
}

private struct EditControl: View {
    @ObservedObject var store: DesktopStore
    var body: some View {
        HStack(spacing: 10) {
            // if store.isEditing {
            //     Menu("Place") {
            //         Button("Left") { NotificationCenter.default.post(name: .placeDesktopEdition, object: DesktopPlacement.left) }
            //         Button("Centre") { NotificationCenter.default.post(name: .placeDesktopEdition, object: DesktopPlacement.center) }
            //         Button("Right") { NotificationCenter.default.post(name: .placeDesktopEdition, object: DesktopPlacement.right) }
            //     }.menuStyle(.borderlessButton).font(.system(size: 11, design: .monospaced))
            // }
            Button(action: { withAnimation(.easeInOut(duration: 0.18)) { store.isEditing.toggle() } }) {
                HStack(spacing: 4) {
                    Image(systemName: store.isEditing ? "checkmark.circle.fill" : "slider.horizontal.3")
                    Text(store.isEditing ? "Done" : "Configure")
                }
            }
            .buttonStyle(EditorialButtonStyle()).foregroundStyle(store.isEditing ? Color.orange : .secondary)
        }.font(.system(size: 11, weight: .medium, design: .monospaced))
    }
}

struct Rule: View {
    let vertical: Bool
    var body: some View {
        Rectangle().fill(.primary.opacity(0.22))
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
