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
            manager.dragStartLocation = debugWindow.convertPoint(fromScreen: NSEvent.mouseLocation)
            manager.stateBeforeDrag = manager.windowState

        case .leftMouseDragged:
            // 设置状态为拖动中
            manager.windowState = .dragging

            // 如果是激活的调试窗口被拖动，解除子窗口关系
            if debugWindow.parent != nil && manager.activeWindow == debugWindow
            {
                mainWindow.removeChildWindow(debugWindow)
                #if DEVELOPMENT
                    baDebugState.shared.system("解除子窗口关系")
                #endif
            }

            // 检查吸附
            /// debug window 的 frame
            let frame = debugWindow.frame
            /// main window 的 frame
            let mainFrame = mainWindow.frame
            let snapDistance = manager.getEffectiveSnapDistance(
                for: frame, and: mainFrame)
            let distanceToLeftEdge = abs(frame.maxX - mainFrame.minX)
            let distanceToRightEdge = abs(frame.minX - mainFrame.maxX)
            let hasVerticalOverlap =
                !(frame.maxY < mainFrame.minY || frame.minY > mainFrame.maxY)

            // 更新吸附状态
            manager.isReadyToSnap =
                (distanceToLeftEdge <= snapDistance
                    || distanceToRightEdge <= snapDistance)
                && hasVerticalOverlap

        case .leftMouseUp:
            // 重置拖动状态
            manager.dragStartLocation = nil

            // 处理吸附
            if manager.isReadyToSnap {
                handleDebugWindowSnap(
                    debugWindow: debugWindow, mainWindow: mainWindow)
            } else {
                if manager.windowState == .dragging {
                    manager.windowState = .detached
                }
                if manager.stateBeforeDrag == .detached {
                    manager.windowState = .detached
                }
            }

            manager.stateBeforeDrag = nil
            manager.isReadyToSnap = false
            if manager.windowState == .dragging {
                #if DEVELOPMENT
                    baDebugState.shared.userAction("结束拖动调试窗口")
                #endif
            }

        default:
            break
        }

        return event
    }

    /// 处理调试窗口的吸附
    private func handleDebugWindowSnap(
        debugWindow: NSWindow, mainWindow: NSWindow
    ) {
        let frame = debugWindow.frame
        let mainFrame = mainWindow.frame
        var newFrame = frame

        // 判断吸附方向
        let snapDistance = manager.getEffectiveSnapDistance(
            for: frame, and: mainFrame)
        let distanceToLeftEdge = abs(frame.maxX - mainFrame.minX)
        let distanceToRightEdge = abs(frame.minX - mainFrame.maxX)

        if distanceToLeftEdge <= snapDistance {
            // 吸附到左边
            newFrame.origin.x = mainFrame.minX - frame.width - 1
            newFrame.origin.y = mainFrame.minY
            newFrame.size.height = mainFrame.height
            manager.debugWindowSide = .left
            #if DEVELOPMENT
                baDebugState.shared.system("吸附到主窗口左侧")
            #endif
        } else if distanceToRightEdge <= snapDistance {
            // 吸附到右边
            newFrame.origin.x = mainFrame.maxX + 1
            newFrame.origin.y = mainFrame.minY
            newFrame.size.height = mainFrame.height
            manager.debugWindowSide = .right
            #if DEVELOPMENT
                baDebugState.shared.system("吸附到主窗口右侧")
            #endif
        }

        manager.animationWindow(
            actorWindow: debugWindow,
            fromFrame: newFrame,
            targetFrame: newFrame,
            duration: 0.15
        ) {
            mainWindow.addChildWindow(debugWindow, ordered: .above)
            // #if DEVELOPMENT
            //     baDebugState.shared.system("执行吸附动画并设置为子窗口")
            // #endif
        }

        manager.windowState = .attached
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

    /// 处理主窗口移动事件
    /// 主窗口移动时，如果 debug window 是子窗口，则更新 debug window 的位置
    /// 否则，不做任何操作
    private func handleMainWindowMove(_ notification: Notification) {
        guard let mainWindow = notification.object as? NSWindow,
            let debugWindow = manager.debugWindow,
            debugWindow.parent != nil
        else {
            return
        }

        // 更新调试窗口位置
        var newFrame = debugWindow.frame

        // 判断调试窗口在主窗口的哪一侧
        // if debugWindow.frame.minX < mainWindow.frame.minX {
        //     // 在左侧
        //     newFrame.origin.x = mainWindow.frame.minX - debugWindow.frame.width - 1
        // } else {
        //     // 在右侧
        //     newFrame.origin.x = mainWindow.frame.maxX + 1
        // }

        if manager.debugWindowSide == .left {
            newFrame.origin.x =
                mainWindow.frame.minX - debugWindow.frame.width
                - manager.debugWindowMainWindowSpacing
        } else {
            newFrame.origin.x =
                mainWindow.frame.maxX + manager.debugWindowMainWindowSpacing
        }

        newFrame.origin.y = mainWindow.frame.minY
        newFrame.size.height = mainWindow.frame.height
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

        var newFrame = debugWindow.frame
        newFrame.size.height = mainWindow.frame.height

        // 判断 debugWindow 在主窗口的哪一侧
        if manager.debugWindowSide == .left {  // debugWindow 在左侧
            newFrame.origin.x =
                mainWindow.frame.minX
                - debugWindow.frame.width
                - manager.debugWindowMainWindowSpacing
        } else {  // debugWindow 在右侧
            newFrame.origin.x =
                mainWindow.frame.maxX
                + manager.debugWindowMainWindowSpacing
        }
        newFrame.origin.y = mainWindow.frame.minY

        if manager.windowMode == .animation {
            manager.animationWindow(
                actorWindow: debugWindow,
                fromFrame: newFrame,
                targetFrame: newFrame,
                duration: 0.4,
                completionHandler: {}
            )
        } else {
            debugWindow.setFrame(newFrame, display: true)
        }
    }
}

func animateWindow(
    _ window: NSWindow, to frame: NSRect, duration: TimeInterval,
    completion: (() -> Void)? = nil
) {
    NSAnimationContext.runAnimationGroup { context in
        context.duration = duration
        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        window.animator().setFrame(frame, display: true)
        // 效果不好
        // window.setFrame(frame, display: true)
    } completionHandler: {
        completion
    }
}
