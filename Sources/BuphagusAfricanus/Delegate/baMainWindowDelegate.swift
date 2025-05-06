//
//  baAppDelegate.swift
//  BuphagusAfricanus
//

import AppKit
import SwiftUI


/// 主窗口的代理
class baMainWindowDelegate: NSObject, NSWindowDelegate {

    public static let shared = baMainWindowDelegate("baMainWindowDelegate")
    
    private let manager = baWindowManager.shared
    
    public var identifier: String = "baMainWindowIdentifier"
    
    public var window: NSWindow?
    
    private init(_ identifier: String) {
        self.identifier = identifier
    }

    /// 配置主窗口的一些属性包括delegate标题等
    @MainActor func setupMainWindow() {

        self.window = NSApplication.shared.windows.first
        self.window?.delegate = self
        self.window?.identifier = NSUserInterfaceItemIdentifier(self.identifier)
        self.window?.isReleasedWhenClosed = true

        self.window?.standardWindowButton(.closeButton)?.isHidden = true
        self.window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.window?.standardWindowButton(.zoomButton)?.isHidden = true

        self.window?.alphaValue = 1
        self.window?.animationBehavior = .documentWindow
        // 工具提示
        self.window?.toolbar?.displayMode = .iconOnly           // 工具栏显示模式
        self.window?.toolbar?.isVisible = true                  // 工具栏是否可见

        // 外观设置
        self.window?.titlebarAppearsTransparent = true
        self.window?.titleVisibility = .hidden
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
        self.identifier = identifier
    }

    func getIdentifier() -> String {
        return identifier
    }

    func bindWindow(_ window: NSWindow) {
        self.window = window
        window.delegate = self
    }
}

extension baMainWindowDelegate {

    func windowDidBecomeKey(
        _ notification: Notification
    ) {
        if baGlobalConfig.shared.isDebugMode {
            baDebugState.shared.system("main window did become key")
        }
        manager.activeWindow = window
    }
}
