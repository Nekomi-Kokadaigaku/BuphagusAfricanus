import SwiftUI
import Carbon


/// 快捷键管理器
class baKeyboardShortcutManager: ObservableObject {
    static let shared = baKeyboardShortcutManager()

    // 快捷键定义
    struct Shortcut {
        let key: String
        let modifiers: NSEvent.ModifierFlags
        let action: () -> Void

        init(key: String, modifiers: NSEvent.ModifierFlags = [.command], action: @escaping () -> Void) {
            self.key = key
            self.modifiers = modifiers
            self.action = action
        }
    }

    // 快捷键列表
    private var shortcuts: [Shortcut] = []

    // 注册快捷键
    func registerShortcuts(for debugState: baDebugState) {
        shortcuts = [
            // 清除所有消息
            Shortcut(key: "k", modifiers: [.command]) {
                debugState.clearMessages()
            },

            // 切换监视面板
            Shortcut(key: "w", modifiers: [.command, .shift]) {
                debugState.showWatchPanel.toggle()
            },

            // 切换自动滚动
            Shortcut(key: "s", modifiers: [.command]) {
                debugState.autoScroll.toggle()
            },

            // 切换详细信息显示
            Shortcut(key: "d", modifiers: [.command]) {
                debugState.showDetails.toggle()
            },

            // 导出日志
            Shortcut(key: "e", modifiers: [.command, .shift]) {
                debugState.exportCurrentMessages()
            },

            // 切换窗口吸附
            Shortcut(key: "a", modifiers: [.command, .shift]) {
                debugState.isAttached.toggle()
            }
        ]
    }

    // 处理快捷键事件
    func handleKeyEvent(_ event: NSEvent) -> Bool {
        for shortcut in shortcuts {
            if event.characters?.lowercased() == shortcut.key.lowercased() &&
                event.modifierFlags.intersection(.deviceIndependentFlagsMask) == shortcut.modifiers {
                shortcut.action()
                return true
            }
        }
        return false
    }
}

/// 快捷键视图修饰器
struct KeyboardShortcutModifier: ViewModifier {
    @ObservedObject var manager: baKeyboardShortcutManager

    func body(content: Content) -> some View {
        content
            .onAppear {
                NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    if manager.handleKeyEvent(event) {
                        return nil
                    }
                    return event
                }
            }
    }
}
