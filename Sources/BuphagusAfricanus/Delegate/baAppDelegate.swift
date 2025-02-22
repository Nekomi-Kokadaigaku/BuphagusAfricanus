//
//  baAppDelegate.swift
//  BuphagusAfricanus
//
//  Created by Iris on 2025-02-12.
//

import SwiftUI


/// 应用程序代理
/// 负责应用程序的生命周期管理
/// 处理window delegate做不到的事情
public class baAppDelegate: NSObject, NSApplicationDelegate {

    ///
    var windowMonitor: Any?
    var resizeObserver: NSObjectProtocol?
    let manager = baWindowManager.shared
    let debugState = baDebugState.shared

    let currentScreen = NSScreen.main ?? NSScreen.screens.first

    /// 应用程序完成启动，进行debug window 等的初始化
    public func applicationDidFinishLaunching(_ notification: Notification) {

        // 获取 main window 和 debug window
        let mWindowD = baMainWindowDelegate.shared
        let dWindowD = baDebugWindowDelegate.shared

        // 创建 debug window
        dWindowD.createDebugWindow()

        // 创建 debug window 的 configuration window
        let configureWindow = baConfigureWindowDelegate.shared.createConfigureWindow()

        // 配置 main window
        mWindowD.setupMainWindow()

        manager.mainWindow = NSApplication.shared.windows.first
        manager.debugWindow = baDebugWindowDelegate.shared.debugWindow
        manager.configureWindow = configureWindow

        setupWindowDragAndSnapMonitor()
        setupMainWindowObserver()

        baDebugWindowDelegate.shared.startupAnimation()
        baDebugWindowDelegate.shared.showDebugWindow()
        baDebugWindowDelegate.shared.bindToMainWindow(to: baMainWindowDelegate.shared.window)

        // manager.mainWindow?.addChildWindow(debugWindow, ordered: .above)
        if baGlobalConfig.shared.isDebugMode {
            baDebugState.shared.system("debugWindow bind to mainWindow")
        }

        // 显示调试窗口
        // debugWindow.makeKeyAndOrderFront(nil)
    }

    /// 应用程序退出时，移除监听器
    public func applicationWillTerminate(_ notification: Notification) {
        removeObservers()
    }

    /// 所有窗口都关闭后退出，一般开发的时候都关了就可以退出了，避免卡住
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

// MARK: - 配置调试信息窗口
extension baAppDelegate {

    /// 设置调试信息窗口鼠标事件监听器
    func setupWindowDragAndSnapMonitor() {
        // 监听调试窗口的鼠标事件: 点击, 拖拽, 释放
        windowMonitor = NSEvent.addLocalMonitorForEvents(matching: [
            .leftMouseDown, .leftMouseDragged, .leftMouseUp,
        ]) { [weak self] event in
            guard let self = self,
                let debugWindow = self.manager.debugWindow,
                let mainWindow = self.manager.mainWindow,
                event.window == debugWindow
            else { return event }

            return self.handleDebugWindowDrag(event, debugWindow: debugWindow, mainWindow: mainWindow)
        }
    }

    /// 处理调试窗口的拖拽事件
    private func handleDebugWindowDrag(
        _ event: NSEvent, debugWindow: NSWindow, mainWindow: NSWindow
    ) -> NSEvent {
        switch event.type {

        case .leftMouseDown:
            // 记录拖动开始位置和状态
            manager.stateBeforeDrag = manager.windowState

        case .leftMouseDragged:
            // 设置状态为拖动中
            manager.windowState = .dragging

            // 如果是激活的调试窗口被拖动，解除子窗口关系
            if debugWindow.parent != nil && manager.activeWindow == debugWindow {

                mainWindow.removeChildWindow(debugWindow)

                if baGlobalConfig.shared.isDebugMode {
                    baDebugState.shared.system("解除子窗口关系")
                }
            }

        case .leftMouseUp:
            let (newFrame, debugWindowSnapSide) = baWindowManager.shared.snapWindow(from: debugWindow, to: mainWindow)

            if let debugWindowSnapSide {
                // 在吸附范围，进行吸附
                manager.debugWindowSide = debugWindowSnapSide
                manager.windowState = .attached
                if [.leftInside, .rightInside].contains(debugWindowSnapSide) {
                    manager.makeWindowTrans(a: debugWindow, aa: 0.64)
                } else {
                    manager.makeWindowTrans(a: debugWindow, aa: 1)                    
                }
                mainWindow.addChildWindow(debugWindow, ordered: .above)
            } else {
                manager.debugWindowSide = .right
                manager.windowState = .detached
            }

            baWindowManager.shared.animationWindow(
                actorWindow: debugWindow,
                fromFrame: debugWindow.frame,
                targetFrame: newFrame,
                duration: 0.15
            )

        default:
            break
        }

        return event
    }
    
    /// 移除监听器
    private func removeObservers() {
        if let monitor = windowMonitor {
            NSEvent.removeMonitor(monitor)
        }

        // 移除大小变化观察者
        if let observer = resizeObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        for observerInfo in manager.observers {
            NotificationCenter.default.removeObserver(observerInfo.observer)
            print(
                "移除 \(observerInfo.description): \(observerInfo.notificationName)"
            )
        }
    }
}

// MARK: - 监听主窗口移动，大小变化
extension baAppDelegate {
    /// 设置主窗口监听器
    private func setupMainWindowObserver() {
        setupMainWindowMoveObserver()
        setupMainWindowResizeObserver()
    }

    /// 设置主窗口移动监听器
    private func setupMainWindowMoveObserver() {
        let baMainWindowObserver: NSObjectProtocol = NotificationCenter.default
            .addObserver(
                forName: NSWindow.didMoveNotification,
                object: manager.mainWindow,
                queue: .main
            ) { [weak self] notification in
                self?.handleMainWindowMove(notification)
            }
        manager.observers.append(
            .init(
                observer: baMainWindowObserver,
                notificationName: NSWindow.didMoveNotification,
                description: "主窗口移动"
            ))
        #if DEVELOPMENT
            baDebugState.shared.system("设置主窗口移动监听器")
        #endif
    }

    /// 主要作用：debug window初始在不正确的地方，此时移动会纠正到正确的位置。
    /// 不修改的话会出现 debug window 处于错误位置但是跟着 main window 一起移动
    private func handleMainWindowMove(_ notification: Notification) {
        guard let mainWindow = notification.object as? NSWindow,
            let debugWindow = manager.debugWindow,
            debugWindow.parent != nil, manager.windowState != .detached
        else {
            return
        }

        // 更新调试窗口位置
        var newFrame = debugWindow.frame

        newFrame = moveFrame(
            from: debugWindow.frame,
            to: mainWindow.frame,
            manager.debugWindowSide
        )

        debugWindow.setFrame(newFrame, display: true)
    }

    /// 设置主窗口大小变化监听器
    private func setupMainWindowResizeObserver() {
        resizeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: manager.mainWindow,
            queue: .main
        ) { [weak self] notification in
            self?.handleMainWindowResize(notification)
        }
        manager.observers.append(
            .init(
                observer: resizeObserver!,
                notificationName: NSWindow.didResizeNotification,
                description: "主窗口大小变化"
            ))
        #if DEVELOPMENT
            baDebugState.shared.system("设置主窗口大小变化监听器")
        #endif
    }

    /// 处理主窗口大小变化事件
    /// 主窗口大小变化时，如果 debug window 是子窗口，则更新 debug window 的位置
    /// 否则，不做任何操作
    private func handleMainWindowResize(_ notification: Notification) {
        guard let mainWindow = notification.object as? NSWindow,
            let debugWindow = manager.debugWindow, debugWindow.parent != nil else { return }

        let newFrame = moveFrame(
            from: debugWindow.frame,
            to: mainWindow.frame,
            manager.debugWindowSide
        )
        debugWindow.setFrame(newFrame, display: true)
    }

    private func moveFrame(from aFrame: NSRect, to bFrame: NSRect, _ aa: baWindowManager.Side) -> NSRect {

        var newFrame = aFrame // a debug b main

        switch aa {

        case .left:
            newFrame.origin.x = bFrame.minX
                                - aFrame.width
                                - windowConstant.debugWindowMainWindowSpacing
        case .right:
            newFrame.origin.x = bFrame.maxX + windowConstant.debugWindowMainWindowSpacing
        case .leftInside:
            newFrame.origin.x = bFrame.minX + windowConstant.debugWindowInsideToMainWindowSpacing
        case .rightInside:
            newFrame.origin.x = bFrame.maxX
                                - aFrame.width
                                - windowConstant.debugWindowInsideToMainWindowSpacing
        }

        switch manager.debugWindowSide {

        case .left, .right:
            newFrame.origin.y = bFrame.minY
        case .leftInside, .rightInside:
            newFrame.origin.y = bFrame.minY + windowConstant.debugWindowInsideToMainWindowSpacing
        }

        switch manager.debugWindowSide {

        case .left, .right:
            newFrame.size.height = bFrame.height
        case .leftInside, .rightInside:
            newFrame.size.height = bFrame.height - windowConstant.debugWindowInsideToMainWindowSpacing * 2
        }

        return newFrame
    }
}
