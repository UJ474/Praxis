import SwiftUI

struct EditorialButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 10, weight: .semibold, design: .monospaced)).foregroundStyle(configuration.isPressed ? Color.orange : .primary).padding(.horizontal, 9).padding(.vertical, 5).background(Color.primary.opacity(configuration.isPressed ? 0.10 : 0.045)).overlay(Rectangle().stroke(Color.primary.opacity(0.25), lineWidth: 0.5))
    }
}
