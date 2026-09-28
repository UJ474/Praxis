import SwiftUI

struct EisenhowerView: View {
    @ObservedObject var store: DesktopStore
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("THIS WEEK")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                Spacer()
                Image(systemName: "calendar")
                Text(DesktopStore.monday(), format: .dateTime.month(.abbreviated).day())
            }
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(.secondary)

            GeometryReader { proxy in
                let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Quadrant.allCases) { quadrant in
                        QuadrantView(quadrant: quadrant, store: store)
                            .frame(height: max(160, (proxy.size.height - 14) / 2))
                    }
                }
            }
        }
    }
}

private struct QuadrantView: View {
    let quadrant: Quadrant; @ObservedObject var store: DesktopStore
    var items: [TaskItem] { store.tasks.filter { $0.quadrant == quadrant && $0.completedAt == nil } }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            VStack(alignment: .leading, spacing: 2) {
                Text(quadrant.title)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                Text(quadrant.subtitle)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Hairline()
            // Task list
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items) { TaskRow(task: $0, store: store) }
                    // Always-visible sticky-style add input
                    StickyAddInput(quadrant: quadrant, store: store)
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(10)
        .background(Color.primary.opacity(0.03))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct TaskRow: View {
    let task: TaskItem; @ObservedObject var store: DesktopStore
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            // Complete button
            Button {
                var edited = task; edited.completedAt = .now
                Task { await store.update(edited) }
            } label: {
                Circle()
                    .stroke(.secondary, lineWidth: 1)
                    .frame(width: 11, height: 11)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                if store.isEditing {
                    InlineTaskEditor(task: task, store: store)
                } else {
                    Text(task.content.text)
                        .font(.custom("New York", size: 13))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if task.carriedFrom != nil {
                    Text("CARRIED OVER")
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}

private struct InlineTaskEditor: View {
    let task: TaskItem; @ObservedObject var store: DesktopStore
    @State private var content: TaskContent
    @State private var editorAction: RichTextAction?
    init(task: TaskItem, store: DesktopStore) {
        self.task = task; _store = ObservedObject(wrappedValue: store)
        _content = State(initialValue: task.content)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            RichTextEditor(content: $content, action: $editorAction)
                .frame(height: 50)
                .background(Color.primary.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.orange.opacity(0.35), lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            HStack(spacing: 6) {
                MiniButton("B", bold: true) { editorAction = .bold }
                MiniButton("H") { editorAction = .highlight }
                MiniButton("A+") { editorAction = .increaseSize }
                Spacer()
                MiniButton("Save", accent: true) {
                    var edited = task; edited.content = content
                    Task { await store.update(edited) }
                }
            }
        }
    }
}

/// Always-visible sticky-note-style text input at the bottom of each quadrant.
private struct StickyAddInput: View {
    let quadrant: Quadrant; @ObservedObject var store: DesktopStore
    @State private var content = TaskContent(text: "")
    @State private var editorAction: RichTextAction?
    @State private var isFocused = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // The text field — always visible, looks like a sticky note
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.primary.opacity(isFocused ? 0.07 : 0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(isFocused ? Color.orange.opacity(0.5) : Color.primary.opacity(0.12), lineWidth: 0.5)
                    )
                if content.text.isEmpty {
                    Text("Add a task…")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary.opacity(0.6))
                        .padding(.horizontal, 7)
                        .padding(.top, 6)
                }
                RichTextEditor(content: $content, action: $editorAction)
                    .frame(height: 52)
                    .padding(4)
            }
            .frame(height: 52)
            .onHover { over in withAnimation(.easeInOut(duration: 0.12)) { isFocused = over } }

            // Action row
            HStack(spacing: 6) {
                MiniButton("B", bold: true) { editorAction = .bold }
                MiniButton("H") { editorAction = .highlight }
                Spacer()
                MiniButton("Add", accent: true) {
                    guard !content.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    let task = TaskItem(
                        id: UUID().uuidString,
                        weekOf: DesktopStore.monday(),
                        completedAt: nil,
                        carriedFrom: nil,
                        quadrant: quadrant,
                        content: content
                    )
                    content = TaskContent(text: "")
                    Task { await store.save(task) }
                }
            }
        }
        .padding(.top, 4)
    }
}

private struct MiniButton: View {
    let label: String
    var bold: Bool = false
    var accent: Bool = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .fontWeight(bold ? .bold : .medium)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(accent ? Color.orange : Color.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(accent ? Color.orange.opacity(0.10) : Color.primary.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(accent ? Color.orange.opacity(0.35) : Color.primary.opacity(0.18), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }
}
