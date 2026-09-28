import SwiftUI

struct EisenhowerView: View {
    @ObservedObject var store: DesktopStore
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { Text("THIS WEEK").font(.system(size: 11, weight: .semibold, design: .monospaced)); Spacer(); Image(systemName: "calendar"); Text(DesktopStore.monday(), format: .dateTime.month(.abbreviated).day()) }.font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
            GeometryReader { proxy in
                let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
                LazyVGrid(columns: columns, spacing: 16) { ForEach(Quadrant.allCases) { quadrant in QuadrantView(quadrant: quadrant, store: store).frame(height: max(150, (proxy.size.height - 16) / 2)) } }
            }
        }
    }
}

private struct QuadrantView: View {
    let quadrant: Quadrant; @ObservedObject var store: DesktopStore
    var items: [TaskItem] { store.tasks.filter { $0.quadrant == quadrant && $0.completedAt == nil } }
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(quadrant.title).font(.system(size: 10, weight: .semibold, design: .monospaced))
            Text(quadrant.subtitle).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
            Hairline()
            ScrollView { VStack(alignment: .leading, spacing: 8) { ForEach(items) { TaskRow(task: $0, store: store) }; AddTaskEditor(quadrant: quadrant, store: store) } }.scrollIndicators(.hidden)
        }.padding(.vertical, 4)
    }
}

private struct TaskRow: View {
    let task: TaskItem; @ObservedObject var store: DesktopStore
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Button { var edited = task; edited.completedAt = .now; Task { await store.update(edited) } } label: { Circle().stroke(.secondary, lineWidth: 1).frame(width: 12, height: 12) }.buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 2) {
                if store.isEditing { InlineTaskEditor(task: task, store: store) }
                else { Text(task.content.text).font(.custom("New York", size: 13)).lineSpacing(2) }
                if task.carriedFrom != nil { Text("CARRIED OVER").font(.system(size: 8, design: .monospaced)).foregroundStyle(.orange) }
            }
        }
    }
}

private struct InlineTaskEditor: View {
    let task: TaskItem; @ObservedObject var store: DesktopStore
    @State private var content: TaskContent; @State private var editorAction: RichTextAction?
    init(task: TaskItem, store: DesktopStore) { self.task = task; _store = ObservedObject(wrappedValue: store); _content = State(initialValue: task.content) }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Button("B") { editorAction = .bold }.fontWeight(.bold)
                Button("Highlight") { editorAction = .highlight }
                Button("A+") { editorAction = .increaseSize }
                Button("Save") { var edited = task; edited.content = content; Task { await store.update(edited) } }.foregroundStyle(.orange)
            }.buttonStyle(EditorialButtonStyle()).font(.system(size: 8, design: .monospaced)).foregroundStyle(.secondary)
            RichTextEditor(content: $content, action: $editorAction).frame(height: 46)
        }
    }
}

private struct AddTaskEditor: View {
    let quadrant: Quadrant; @ObservedObject var store: DesktopStore
    @State private var content = TaskContent(text: "")
    @State private var editorAction: RichTextAction?
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 9) {
                Button("B") { editorAction = .bold }.fontWeight(.bold)
                Button("Highlight") { editorAction = .highlight }
                Button("A+") { editorAction = .increaseSize }
            }.buttonStyle(EditorialButtonStyle()).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
            RichTextEditor(content: $content, action: $editorAction).frame(height: 54)
            Button("Save task") {
                guard !content.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                let task = TaskItem(id: UUID().uuidString, weekOf: DesktopStore.monday(), completedAt: nil, carriedFrom: nil, quadrant: quadrant, content: content)
                content = TaskContent(text: ""); Task { await store.save(task) }
            }.buttonStyle(EditorialButtonStyle()).foregroundStyle(.orange)
        }.overlay(alignment: .top) { Rectangle().fill(.primary.opacity(0.22)).frame(height: 0.5) }
    }
}
