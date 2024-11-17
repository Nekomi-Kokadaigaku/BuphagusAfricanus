import AppKit
import SwiftUI


/// 主窗口的代理
class baMainWindowDelegate: NSObject, NSWindowDelegate {
    // MARK: - Properties
    public static let shared = baMainWindowDelegate(identifier: "baMainWindowDelegate")
    private let manager = baWindowManager.shared
    private var indentifier: String = "baMainWindowDelegate"
    private var window: NSWindow?
    private init(identifier: String) {
        self.indentifier = identifier
    }

    func setupMainWindow() {
        // 确保在主线程上执行
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.window = NSApplication.shared.windows.first
            self.window?.delegate = self
            self.window?.title = "Buphagus Africanus"
            self.window?.identifier = NSUserInterfaceItemIdentifier(self.indentifier)
            self.window?.isReleasedWhenClosed = true

            // window.alphaValue = 0.8
            self.window?.animationBehavior = .documentWindow
            // 工具提示
            // self.mainWindow?.toolbar?.displayMode = .iconOnly           // 工具栏显示模式
            // self.mainWindow?.toolbar?.isVisible = true                  // 工具栏是否可见

            // 外观设置
            self.window?.titlebarAppearsTransparent = true
            self.window?.isMovableByWindowBackground = true
            // self.window?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.95)

            // 内容视图设置
            self.window?.contentView?.wantsLayer = true
            self.window?.contentView?.layerContentsRedrawPolicy = .onSetNeedsDisplay


            // 大小限制
            // self.mainWindow?.minSize = NSSize(
            //     width: windowConfig.minWidth,
            //     height: windowConfig.minHeight
            // )

            // 层级设置
            // self.mainWindow?.level = .floating
            // self.mainWindow?.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]

            // 强制更新窗口
            // self.mainWindow?.setFrame(self.mainWindow?.frame ?? .zero, display: true)
        }
    }

    // MARK: - Methods
    func setIdentifier(_ identifier: String) {
        self.indentifier = identifier
    }

    func getIdentifier() -> String {
        return indentifier
    }

    func bindWindow(_ window: NSWindow) {
        self.window = window
        window.delegate = self
    }
}

extension baMainWindowDelegate {
    func windowDidBecomeKey(_ notification: Notification) {
        baDebugState.shared.system("main window did become key")
        manager.activeWindow = window
    }
}
