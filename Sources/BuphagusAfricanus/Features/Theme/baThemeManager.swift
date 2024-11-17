import SwiftUI


/// 调试窗口主题
struct DebugTheme {
    // 颜色
    var backgroundColor: Color
    var textColor: Color
    var accentColor: Color
    var toolbarColor: Color
    var dividerColor: Color

    // 字体
    var titleFont: Font
    var bodyFont: Font
    var monoFont: Font

    // 尺寸
    var cornerRadius: CGFloat
    var padding: CGFloat
    var spacing: CGFloat

    // 预定义主题
    static let light = DebugTheme(
        backgroundColor: Color(NSColor.windowBackgroundColor),
        textColor: Color(NSColor.labelColor),
        accentColor: .blue,
        toolbarColor: Color(NSColor.controlBackgroundColor),
        dividerColor: Color(NSColor.separatorColor),
        titleFont: .system(size: 13, weight: .medium),
        bodyFont: .system(size: 12),
        monoFont: .system(size: 11, design: .monospaced),
        cornerRadius: 8,
        padding: 8,
        spacing: 4
    )

    static let dark = DebugTheme(
        backgroundColor: Color(hex: "1E1E1E"),
        textColor: Color.white,
        accentColor: Color.blue,
        toolbarColor: Color(hex: "252526"),
        dividerColor: Color(hex: "333333"),
        titleFont: .system(size: 13, weight: .medium),
        bodyFont: .system(size: 12),
        monoFont: .system(size: 11, design: .monospaced),
        cornerRadius: 8,
        padding: 8,
        spacing: 4
    )
}

/// 主题管理器
class baThemeManager: ObservableObject {
    static let shared = baThemeManager()

    @Published var currentTheme: DebugTheme

    private init() {
        // 根据系统外观选择主题
        if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            currentTheme = .dark
        } else {
            currentTheme = .light
        }

        // 监听系统外观变化
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(handleAppearanceChange),
//            name: NSApplication.appearanceDidChangeNotification,
//            object: nil
//        )
    }

    @objc private func handleAppearanceChange() {
        DispatchQueue.main.async {
            if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                self.currentTheme = .dark
            } else {
                self.currentTheme = .light
            }
        }
    }
}
