import AppKit
import SwiftUI


/// 调试窗口的代理
class baDebugWindowDelegate: NSObject, NSWindowDelegate {
    // MARK: - Properties
    static let shared = baDebugWindowDelegate()
    private let manager = baWindowManager.shared
    private let configManager = baConfigurationManager.shared
    var debugWindow: NSWindow?

    // 窗口配置
    private var windowConfig: baConfiguration.WindowConfig {
        configManager.config.window
    }

    // MARK: - 创建调试窗口
    ///
    /// 调试窗口的初始化配置:
    /// - 位置: 屏幕最右侧
    /// - 高度: 与主窗口相同
    /// - 界面元素:
    ///   - 隐藏标题栏
    ///   - 隐藏关闭按钮
    ///   - 隐藏最小化按钮
    ///   - 隐藏缩放按钮
    func createDebugWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: initialFrame,
            styleMask: [
                .titled,
                .closable,
                .miniaturizable,
                .resizable,
                .fullSizeContentView,
                .nonactivatingPanel,
                .borderless
            ],
            backing: .buffered,
            defer: false
        )

        configureWindow(window)
        self.debugWindow = window
        return window
    }

    /// 配置调试窗口
    private func configureWindow(_ window: NSWindow) {
        // 基本设置
        window.title = manager.debugWindowName
        window.identifier = NSUserInterfaceItemIdentifier(manager.debugWindowName)
        window.delegate = self

        // window.alphaValue = 0.8
        window.hasShadow = true

        window.animationBehavior = .documentWindow
        // 工具提示
        window.toolbar?.displayMode = .iconOnly           // 工具栏显示模式
        window.toolbar?.isVisible = true                  // 工具栏是否可见

        // 外观设置
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.95)

        // 内容视图设置
        window.contentView = NSHostingView(rootView: baDebugView(windowId: manager.debugWindowName))
        window.contentView?.wantsLayer = true
        window.contentView?.layerContentsRedrawPolicy = .onSetNeedsDisplay


        // 大小限制
        window.minSize = NSSize(
            width: windowConfig.minWidth,
            height: windowConfig.minHeight
        )

        // 层级设置
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]
    }

    // MARK: - Window Initial Frame
    private var initialFrame: NSRect {
        guard let mainScreen = NSScreen.main else {
            return NSRect(x: 0, y: 0, width: windowConfig.defaultWidth, height: windowConfig.defaultHeight)
        }

        let screenFrame = mainScreen.visibleFrame
        return NSRect(
            x: screenFrame.maxX - windowConfig.defaultWidth,
            y: screenFrame.minY,
            width: windowConfig.defaultWidth,
            height: windowConfig.defaultHeight
        )
    }
}

// MARK: - Window Delegate Methods
extension baDebugWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        saveWindowState(window)
    }

    func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        manager.activeWindow = window
        handleWindowActivation(window)
    }

    func windowDidMove(_ notification: Notification){
        if manager.activeWindow == manager.debugWindow {
            baDebugState.shared.system("debug window did move")
        } else {
            baDebugState.shared.system("debug window did move, but not active")
        }
    }

    // MARK: - Window State Management
    private func saveWindowState(_ window: NSWindow) {
        // 保存窗口位置和大小
        let frameDict = [
            "x": window.frame.origin.x,
            "y": window.frame.origin.y,
            "width": window.frame.size.width,
            "height": window.frame.size.height
        ]
        UserDefaults.standard.set(frameDict, forKey: "debug_window_frame")
    }

    private func restoreWindowState(_ window: NSWindow) {
        guard let frameDict = UserDefaults.standard.dictionary(forKey: "debug_window_frame"),
              let x = frameDict["x"] as? CGFloat,
              let y = frameDict["y"] as? CGFloat,
              let width = frameDict["width"] as? CGFloat,
              let height = frameDict["height"] as? CGFloat else { return }

        // 确保尺寸不小于最小允许值
        let safeWidth = max(width, windowConfig.minWidth)
        let safeHeight = max(height, windowConfig.minHeight)

        let frame = NSRect(x: x, y: y, width: safeWidth, height: safeHeight)

        // 确保窗口在可见屏幕范围内
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            let visibleFrame = screen.visibleFrame
            // 检查窗口是否至少有25%在屏幕内
            let minVisibleArea = frame.size.width * frame.size.height * 0.25
            let intersection = visibleFrame.intersection(frame)

            if !intersection.isNull && intersection.size.width * intersection.size.height >= minVisibleArea {
                window.setFrame(frame, display: true)
            } else {
                // 如果窗口大部分在屏幕外，使用默认位置
                window.setFrame(initialFrame, display: true)
            }
        } else {
            window.setFrame(initialFrame, display: true)
        }
    }
}

// MARK: - Window Event Handlers
extension baDebugWindowDelegate {

    private func handleWindowActivation(_ window: NSWindow) {
        // 处理窗口激活
        manager.activeWindow = window
        #if DEVELOPMENT
        if window == manager.debugWindow {
            baDebugState.shared.system("debug window did become key", details: """
                Identifier: \(window.identifier?.rawValue ?? "none")
                FileName: \((#file as NSString).lastPathComponent)
                FileID: \(#fileID)
                Function: \(#function)
                Line: \(#line)
                """)
        }
        #endif
    }
}

// MARK: - Window Synchronization
extension baDebugWindowDelegate {
    private func syncWindowSize(_ window: NSWindow) {
        guard let mainWindow = manager.mainWindow else { return }

        var newFrame = window.frame
        newFrame.size.height = mainWindow.frame.height

        window.setFrame(newFrame, display: true)
    }

    private func syncWindowPosition(_ window: NSWindow) {
        guard let mainWindow = manager.mainWindow else { return }

        var newFrame = window.frame
        if manager.debugWindowSide == .left {
            newFrame.origin.x = mainWindow.frame.minX - window.frame.width - 1
        } else {
            newFrame.origin.x = mainWindow.frame.maxX + 1
        }
        newFrame.origin.y = mainWindow.frame.minY

        animateWindow(window, to: newFrame, duration: 0.3)
    }
}

// MARK: - Public Methods
extension baDebugWindowDelegate {
    /// 显示调试窗口
    func showDebugWindow() {
        guard let window = manager.debugWindow else { return }
        window.makeKeyAndOrderFront(nil)
    }

    /// 隐藏调试窗口
    func hideDebugWindow() {
        manager.debugWindow?.orderOut(nil)
    }

    /// 切换调试窗口显示状态
    func toggleDebugWindow() {
        if manager.debugWindow?.isVisible ?? false {
            hideDebugWindow()
        } else {
            showDebugWindow()
        }
    }

    // TODO: - 重置窗口位置到 main window 的右侧并吸附
    func resetWindowPosition() {
        guard let window = manager.debugWindow else { return }
        window.setFrame(initialFrame, display: true)
    }
}
