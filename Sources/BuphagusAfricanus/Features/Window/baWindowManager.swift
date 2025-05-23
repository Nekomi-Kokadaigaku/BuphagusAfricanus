//
//  baWindowManager.swift
//  BuphagusAfricanus
//

import AppKit
import Combine
import Foundation
import SwiftUI

public struct windowConstant {

}

/// 提供一些窗口的计算移动等方法
public class baWindowManager: ObservableObject {

    public static let shared = baWindowManager()

    // 确保单例
    public init() {}

    let debugWindowName = "debugWindow"

    var activeWindow: NSWindow?


    @Published var showSelfDebugInfo: Bool = false

    /// 开始拖动前的状态
    @PublishedDebugTracked("stateBeforeDrag") var stateBeforeDrag: WindowState = .attached

    /// 所有观察者
    @Published var observers: [baObserverInfo] = []

    /// debug window 贴合方向
    @PublishedDebugTracked1("debugWindowSide") var debugWindowSide: Side = .right


    /// 是否需要更新窗口位置
    @Published var needUpdate = false {
        didSet {
            if baGlobalConfig.shared.isDebugMode {
                baDebugState.shared.updateWatchVariable(
                    name: "needUpdate", value: needUpdate, type: "Bool")
            }
        }
    }

    /// 最后一次更新时间
    @Published var lastUpdate: Date = .init()

    /// 窗口动画模式
    @PublishedDebugTracked1("windowMode") var windowMode: WindowMode = .direct

    /// 是否准备好吸附
    @PublishedDebugTracked1("isReadyToSnap") var isReadyToSnap = false

    /// 窗口状态: 已吸附、已分离、拖拽中
    @PublishedDebugTracked("windowState") var windowState: WindowState = .attached

    // 窗口引用
    var debugWindow: NSWindow?
    var mainWindow: NSWindow?
    var configureWindow: NSWindow?

}

// MARK: - 枚举类
extension baWindowManager {

    /// 窗口状态枚举
    enum WindowState: String {
        case attached = "已吸附"
        case detached = "已分离"
        case dragging = "拖拽中"
    }

    /// 窗口动画模式枚举
    enum WindowMode: String {
        case animation = "动画"
        case direct = "直接"
    }

    /// debug window 贴合方向枚举
    enum Side: String {
        case left = "左侧"
        case right = "右侧"
        case leftInside = "左内侧"
        case rightInside = "右内侧"
    }

    /// 动画种类
    public enum animationSection {
        case animation1
        case animation2
        case animation3
        case animation4
    }
}

// MARK: - 功能性函数
extension baWindowManager {

    /// 切换 debug window 的吸附动画模式
    public func changeAnimationMode() {
        windowMode = windowMode == .animation ? .direct : .animation
    }

    /// 隐藏/显示调试窗口
    public func changeDebugWindowVisibility() {
        if debugWindow?.isVisible ?? false {
            debugWindow?.orderOut(nil)
        } else {
            debugWindow?.makeKeyAndOrderFront(nil)
            mainWindow?.makeKeyAndOrderFront(nil)
        }
    }

    /// 吸附 debug window 到 main window
    public func snapDebugWindowToMain() {
        guard let currentWindow = debugWindow, let mainWindow = mainWindow
        else {
            baDebugState.shared.system("debugWindow 或 mainWindow 为空")
            return
        }

        let (newFrame, newSnapSide) = snapWindow(
            from: currentWindow, to: mainWindow)

        debugWindowSide = newSnapSide ?? .right

        animationWindow(
            actorWindow: currentWindow, fromFrame: currentWindow.frame,
            targetFrame: newFrame
        ) {
            mainWindow.addChildWindow(currentWindow, ordered: .above)
            if baGlobalConfig.shared.isDebugMode {

                baDebugState.shared.system("吸附完成")
            }
        }

        windowState = .attached
    }

    public func animationWindow(
        actorWindow: NSWindow,
        fromFrame: NSRect,
        targetFrame: NSRect,
        duration: TimeInterval = 0.45,
        _ aa: animationSection = .animation1,
        completionHandler: @escaping () -> Void = {}
    ) {

        switch aa {
        case .animation1:
            NSAnimationContext.runAnimationGroup { context in
                context.duration = duration
                context.timingFunction = CAMediaTimingFunction(
                    name: .easeInEaseOut)
                context.allowsImplicitAnimation = true

                actorWindow.animator().setFrame(
                    targetFrame, display: true, animate: true)

            } completionHandler: {
                completionHandler()
            }
        case .animation2:  // 动画2：使用 Core Animation 显式动画
            let animation = CABasicAnimation(keyPath: "frame")
            animation.fromValue = NSValue(rect: fromFrame)
            animation.toValue = NSValue(rect: targetFrame)
            animation.duration = duration
            animation.timingFunction = CAMediaTimingFunction(
                name: .easeInEaseOut)
            actorWindow.animations = ["frame": animation]
            actorWindow.animator().setFrame(targetFrame, display: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + animation.duration)
            {
                completionHandler()
            }
        case .animation3:  // 动画3：使用弹簧动画效果
            NSAnimationContext.runAnimationGroup { context in
                context.duration = duration
                context.timingFunction = CAMediaTimingFunction(
                    controlPoints: 0.5, 1.8, 0.585, 0.885
                )
                context.allowsImplicitAnimation = true
                actorWindow.animator().setFrame(
                    targetFrame, display: true, animate: true)
            } completionHandler: {
                completionHandler()
            }
        case .animation4:  // 动画4：分步动画
            let positionFrame = NSRect(
                x: targetFrame.origin.x,
                y: targetFrame.origin.y,
                width: targetFrame.width,
                height: targetFrame.height
            )
            NSAnimationContext.runAnimationGroup { context in
                context.duration = duration
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                actorWindow.animator().setFrame(positionFrame, display: true)
            } completionHandler: {
                // 第二步：调整大小
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = duration
                    context.timingFunction = CAMediaTimingFunction(
                        name: .easeInEaseOut)
                    actorWindow.animator().setFrame(targetFrame, display: true)
                } completionHandler: {
                    completionHandler()
                }
            }
        }
    }

    public func makeWindowTrans(
        a: NSWindow, aa: CGFloat, duration: TimeInterval = 0.15
    ) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            a.animator().alphaValue = aa
        }
    }
}

// MARK: - 辅助方法
extension baWindowManager {

    /// 判断两个窗口是否重叠
    private func isWindowsOverlapping(_ f1: NSRect, _ f2: NSRect) -> Bool {
        return f1.intersects(f2)
    }
    func snapWindow(from floatWindow: NSWindow, to bottomWindow: NSWindow) -> (
        NSRect, Side?
    ) {
        let aFrame = floatWindow.frame
        let bFrame = bottomWindow.frame
        return calculateDebugWindowFrame(
            float: aFrame,
            Bottom: bFrame,
            baConsts.debugWindowInsideToMainWindowSpacing
        )
    }

    /// 计算调试窗口在不同位置的理想 frame
    /// - Parameters:
    ///   - position: 停靠位置
    ///   - mainFrame: 主窗口的 frame
    ///   - debugFrame: 调试窗口当前的 frame
    /// - Returns: 计算得到的新 frame
    private func calculateDebugWindowFrame(
        float debugFrame: NSRect,
        Bottom mainFrame: NSRect,
        _ insideSpace: CGFloat
    ) -> (NSRect, Side?) {

        var newFrame = debugFrame

        /// 贴合到左侧外面
        if debugFrame.midX < mainFrame.minX && mainFrame.minX < debugFrame.maxX
        {
            newFrame.origin.x = max(
                0,
                mainFrame.minX
                - baConsts.defaultDebugWindowWidth
                - baConsts.debugWindowMainWindowSpacing
            )
            newFrame.origin.y = mainFrame.minY
            newFrame.size.height = mainFrame.size.height
            return (newFrame, .left)
        }

        /// 贴合到左侧内侧
        if debugFrame.minX < mainFrame.minX && mainFrame.minX < debugFrame.midX
        {
            newFrame.origin.x = mainFrame.minX + insideSpace
            newFrame.origin.y = mainFrame.minY + insideSpace
            newFrame.size.height = mainFrame.size.height - insideSpace * 2
            return (newFrame, .leftInside)
        }

        /// 贴合到右侧外面
        if debugFrame.minX < mainFrame.maxX && mainFrame.maxX < debugFrame.midX
        {
            newFrame.origin.x = mainFrame.maxX
            newFrame.origin.y = mainFrame.minY
            newFrame.size.height = mainFrame.size.height
            return (newFrame, .right)
        }

        /// 贴合到右侧内侧
        if debugFrame.midX < mainFrame.maxX && mainFrame.maxX < debugFrame.maxX
        {
            newFrame.origin.x =
            mainFrame.maxX - baConsts.defaultDebugWindowWidth - insideSpace
            newFrame.origin.y = mainFrame.minY + insideSpace
            newFrame.size.height = mainFrame.size.height - insideSpace * 2
            return (newFrame, .rightInside)
        }

        // 如果没有匹配任何条件，返回默认值
        return (newFrame, nil)
    }
}
