import AppKit
import SwiftUI


/// 配置窗口的代理
class baConfigureWindowDelegate: NSObject, NSWindowDelegate, NSPopoverDelegate {
    // MARK: - Properties
    static let shared = baConfigureWindowDelegate()
    private let manager = baWindowManager.shared
    private let configManager = baConfigurationManager.shared
    var configureWindow: NSWindow?
    private var configPopover: NSPopover?

    // 窗口配置
    private var windowConfig: baConfiguration.WindowConfig {
        configManager.config.window
    }

    // MARK: - Window Setup
    func createConfigureWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: initialFrame,
            styleMask: [
                 .titled,
                // .closable,
                // .miniaturizable,
                // .resizable,
                // .fullSizeContentView
                .nonactivatingPanel,
                .borderless,
                .fullSizeContentView
            ],
            backing: .buffered,
            defer: false
        )

        configureWindow(window)
        self.configureWindow = window
        return window
    }

    /// 配置调试窗口
    private func configureWindow(_ window: NSWindow) {
        // 基本设置
        window.title = "设置"
        window.identifier = NSUserInterfaceItemIdentifier("configureWindow")
        window.delegate = self

        // window.alphaValue = 0.8
        window.hasShadow = true
        window.setFrame(NSRect(x: 0, y: 0, width: 300, height: 400), display: true)

        window.animationBehavior = .documentWindow
        // 工具提示
        window.toolbar?.displayMode = .iconOnly           // 工具栏显示模式
        window.toolbar?.isVisible = true                  // 工具栏是否可见

        // 外观设置
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.95)

        // 内容视图设置
        window.contentView = NSHostingView(rootView: baConfigurationView())
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
extension baConfigureWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let _ = notification.object as? NSWindow else { return }
    }

    func windowDidResize(_ notification: Notification) {
        guard let _ = notification.object as? NSWindow else { return }
    }

    func windowDidMove(_ notification: Notification) {
        guard let _ = notification.object as? NSWindow else { return }
    }

    func windowDidBecomeKey(_ notification: Notification) {
        guard let _ = notification.object as? NSWindow else { return }
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
extension baConfigureWindowDelegate {
    private func handleWindowResize(_ window: NSWindow) {

    }

    private func handleWindowMove(_ window: NSWindow) {

    }

    private func handleWindowActivation(_ window: NSWindow) {

    }
}

// MARK: - Window Synchronization
extension baConfigureWindowDelegate {

}

// MARK: - Public Methods
extension baConfigureWindowDelegate {
    /// 显示调试窗口
    func showConfigureWindow() {
        guard let window = baDebugWindowDelegate.shared.debugWindow else { return }
        configureWindow?.collectionBehavior = [.moveToActiveSpace]
        window.beginSheet(configureWindow!){_ in
            baDebugState.shared.system("配置窗口已关闭")
        }
        // if configPopover == nil {
        //     let popover = NSPopover()
        //     popover.contentSize = NSSize(width: windowConfig.defaultWidth, height: windowConfig.defaultHeight)
        //     popover.behavior = .transient  // 点击外部自动关闭
        //     popover.animates = true
        //     popover.contentViewController = NSHostingController(rootView: ConfigurationView())
        //     popover.delegate = self
        //     self.configPopover = popover
        // }

        // guard let window = manager.debugWindow,
        //       let positioningView = window.contentView else { return }

        // // 显示在窗口顶部中央
        // configPopover?.show(
        //     relativeTo: NSRect(
        //         x: positioningView.bounds.midX - (windowConfig.defaultWidth / 2),
        //         y: positioningView.bounds.maxY,
        //         width: 0,
        //         height: 0
        //     ),
        //     of: positioningView,
        //     preferredEdge: .maxY
        // )
    }

    /// 隐藏调试窗口
    func hideConfigureWindow() {
        guard let window = baDebugWindowDelegate.shared.debugWindow else { return }
        window.endSheet(window.attachedSheet!)
    }

    /// 切换调试窗口显示状态
    func toggleConfigureWindow() {
        if manager.debugWindow?.attachedSheet != nil {
            hideConfigureWindow()
        } else {
            showConfigureWindow()
        }
    }

    // TODO: - 重置窗口位置到 main window 的右侧并吸附
    func resetWindowPosition() {
        guard let window = manager.debugWindow else { return }
        window.setFrame(initialFrame, display: true)
    }
}
