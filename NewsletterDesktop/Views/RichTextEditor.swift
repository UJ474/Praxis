import SwiftUI
import AppKit

/// AppKit-backed editor. It preserves bold, highlight, and point-size runs as `RichRange`.
enum RichTextAction: Equatable { case bold, highlight, increaseSize }

struct RichTextEditor: NSViewRepresentable {
    @Binding var content: TaskContent
    @Binding var action: RichTextAction?
    func makeCoordinator() -> Coordinator { Coordinator(content: $content) }
    func makeNSView(context: Context) -> NSScrollView {
        let editor = NSTextView(); editor.isRichText = true; editor.isEditable = true; editor.isSelectable = true; editor.allowsUndo = true; editor.drawsBackground = false
        editor.font = .systemFont(ofSize: 14); editor.textColor = .labelColor; editor.delegate = context.coordinator
        editor.isHorizontallyResizable = false; editor.textContainer?.widthTracksTextView = true
        let scroll = NSScrollView(); scroll.drawsBackground = false; scroll.hasVerticalScroller = true; scroll.autohidesScrollers = true; scroll.documentView = editor
        return scroll
    }
    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let editor = scroll.documentView as? NSTextView, !context.coordinator.isWriting else { return }
        if editor.string != content.text { editor.string = content.text }
        if let action { context.coordinator.apply(action, in: editor); DispatchQueue.main.async { self.action = nil } }
    }
    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var content: TaskContent; var isWriting = false
        init(content: Binding<TaskContent>) { _content = content }
        func textDidChange(_ notification: Notification) {
            guard let editor = notification.object as? NSTextView else { return }; isWriting = true; defer { isWriting = false }
            let value = editor.attributedString(); var ranges: [RichRange] = []
            value.enumerateAttributes(in: NSRange(location: 0, length: value.length)) { attributes, range, _ in
                let font = attributes[.font] as? NSFont; let color = attributes[.backgroundColor] as? NSColor
                let bold = font?.fontDescriptor.symbolicTraits.contains(.bold) == true
                let hex = color.map { String(format: "#%02X%02X%02X", Int($0.redComponent * 255), Int($0.greenComponent * 255), Int($0.blueComponent * 255)) }
                if bold || hex != nil || font?.pointSize != 14 { ranges.append(.init(start: range.location, end: range.location + range.length, bold: bold ? true : nil, highlight: hex, fontSize: font.map { Double($0.pointSize) })) }
            }
            content = TaskContent(text: editor.string, ranges: ranges)
        }
        func apply(_ action: RichTextAction, in editor: NSTextView) {
            let range = editor.selectedRange(); guard range.length > 0 else { return }
            guard let storage = editor.textStorage else { return }
            switch action {
            case .bold:
                let current = storage.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont ?? .systemFont(ofSize: 14)
                let traits = current.fontDescriptor.symbolicTraits
                let next = traits.contains(.bold) ? traits.subtracting(.bold) : traits.union(.bold)
                storage.addAttribute(.font, value: NSFont(descriptor: current.fontDescriptor.withSymbolicTraits(next), size: current.pointSize)!, range: range)
            case .highlight: storage.addAttribute(.backgroundColor, value: NSColor.systemYellow.withAlphaComponent(0.45), range: range)
            case .increaseSize:
                let current = storage.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont ?? .systemFont(ofSize: 14)
                storage.addAttribute(.font, value: NSFont(descriptor: current.fontDescriptor, size: min(current.pointSize + 2, 24))!, range: range)
            }
            textDidChange(Notification(name: NSText.didChangeNotification, object: editor))
        }
    }
}
