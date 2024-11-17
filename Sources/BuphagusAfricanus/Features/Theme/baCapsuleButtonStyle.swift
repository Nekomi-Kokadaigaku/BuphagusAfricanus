import SwiftUI


/// 胶囊按钮样式
struct baCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12))
            .padding(.horizontal, 12)
            .padding(.vertical,6)
            .frame(maxHeight: 28)
            .frame(height: 28)
            .background(
                Capsule()
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.15 : 0.1))
            )
            .foregroundColor(.primary)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .contentShape(Capsule())
    }
}
