import AppKit
import SwiftUI


/// 主窗口的代理
class baMainWindowDelegate: NSObject, NSWindowDelegate {
    // MARK: - Properties
    public static let shared = baMainWindowDelegate("baMainWindowDelegate")
    private let manager = baWindowManager.shared
    public var indentifier: String = "baMainWindowDelegate"
    public var window: NSWindow?
    private init(_ identifier: String) {
        self.indentifier = identifier
    }

    @MainActor
    func setupMainWindow() {
        // 确保在主线程上执行
        // guard let self = self else { return }


        self.window = NSApplication.shared.windows.first
        self.window?.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        self.window?.delegate = self
        self.window?.title = "Bilibili"
        self.window?.identifier = NSUserInterfaceItemIdentifier(self.indentifier)
        self.window?.isReleasedWhenClosed = true

        // window.alphaValue = 0.8
        self.window?.animationBehavior = .documentWindow
        // 工具提示
        self.window?.toolbar?.displayMode = .iconOnly           // 工具栏显示模式
        self.window?.toolbar?.isVisible = true                  // 工具栏是否可见

        // 外观设置
        self.window?.titlebarAppearsTransparent = true
        self.window?.titleVisibility = .visible
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
        #if ALPHA
        baDebugState.shared.system("main window did become key")
        #endif
        manager.activeWindow = window
    }
}
