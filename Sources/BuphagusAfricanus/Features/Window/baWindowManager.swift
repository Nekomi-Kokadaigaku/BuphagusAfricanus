import AppKit
import SwiftUI
import Combine


/// 窗口管理器
class baWindowManager: ObservableObject {
    static let shared = baWindowManager()

    // 确保单例
    private init() {}

    let debugWindowName = "debugWindow"

    var activeWindow: NSWindow?

    // 默认主窗口尺寸
    let defaultMainWindowWidth: CGFloat = 400
    let defaultMainWindowHeight: CGFloat = 600

    // 默认调试窗口尺寸
    let defaultDebugWindowWidth: CGFloat = 400

    // debugwindow 和 mainwindow 的间隔
    let debugWindowMainWindowSpacing: CGFloat = 0

    // 吸附配置
    let snapDistanceOutside: CGFloat = 70    // 外部吸附距离
    let snapDistanceInside: CGFloat = 290    // 内部吸附距离
    let dragStartThreshold: CGFloat = 0      // 拖动开始阈值

    /// 开始拖动的位置
    var dragStartLocation: NSPoint? {
        didSet {
            baDebugState.shared.updateWatchVariable(name: "dragStartLocationX", value: dragStartLocation?.x ?? 0, type: "Int")
            baDebugState.shared.updateWatchVariable(name: "dragStartLocationY", value: dragStartLocation?.y ?? 0, type: "Int")
        }
    }
    /// 开始拖动前的状态
    var stateBeforeDrag: WindowState? {
        didSet {
            baDebugState.shared.updateWatchVariable(name: "stateBeforeDrag", value: stateBeforeDrag?.rawValue ?? "unknown", type: "String")
        }
    }

    /// 所有观察者
    @Published var observers: [baObserverInfo] = []

    /// debug window 贴合方向
    @Published var debugWindowSide: Side = .right {
        didSet {
            baDebugState.shared.updateWatchVariable(name: "debugWindowSide", value: debugWindowSide.rawValue, type: "String")
        }
    }

    /// 期望的窗口位置
    @Published var targetFrame: NSRect = .zero {
        didSet {
            baDebugState.shared.updateWatchVariable(name: "targetFrameX", value: targetFrame.origin.x, type: "Int")
            baDebugState.shared.updateWatchVariable(name: "targetFrameY", value: targetFrame.origin.y, type: "Int")
        }
    }

    /// 期望的坐标点
    @Published var targetPosition: CGPoint = .zero {
        didSet {
            baDebugState.shared.updateWatchVariable(name: "targetPositionX", value: targetPosition.x, type: "Int")
            baDebugState.shared.updateWatchVariable(name: "targetPositionY", value: targetPosition.y, type: "Int")
        }
    }

    /// 是否需要更新窗口位置
    @Published var needUpdate = false {
        didSet {
            baDebugState.shared.updateWatchVariable(name: "needUpdate", value: needUpdate, type: "Bool")
        }
    }

    /// 最后一次更新时间
    @Published var lastUpdate: Date = .init()

    /// 窗口动画模式
    @Published var windowMode: WindowMode = .direct {
        didSet {
            baDebugState.shared.updateWatchVariable(name: "windowMode", value: windowMode.rawValue, type: "String")
        }
    }

    /// 是否准备好吸附
    @Published var isReadyToSnap = false {
        didSet {
            baDebugState.shared.updateWatchVariable(name: "isReadyToSnap", value: isReadyToSnap, type: "Bool")
        }
    }

    /// 窗口状态: 已吸附、已分离、拖拽中
    @Published var windowState: WindowState = .attached {
        didSet {
            baDebugState.shared.updateWatchVariable(name: "windowState", value: windowState.rawValue, type: "String")
        }
    }

    // 窗口引用
    var debugWindow: NSWindow?
    var mainWindow: NSWindow?
    var configureWindow: NSWindow?

}

// MARK: - 枚举类
extension baWindowManager{

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
    }
}

// MARK: - 辅助方法
extension baWindowManager {

    /// 判断两个窗口是否重叠
    func isWindowsOverlapping(_ frame1: NSRect, _ frame2: NSRect) -> Bool {
        return frame1.intersects(frame2)
    }

    /// 获取有效的吸附距离
    func getEffectiveSnapDistance(for frame1: NSRect, and frame2: NSRect) -> CGFloat {
        return isWindowsOverlapping(frame1, frame2) ? snapDistanceInside : snapDistanceOutside
    }

    /// 吸附动画方法
    func snapDebugWindowToMain() {
        // let windows = NSApplication.shared.windows
        // guard let currentWindow = windows.first(where: { $0.title == "debugWindow" }),
        //       let mainWindow = windows.first(where: { $0.title != "debugWindow" }) else { return }
        guard let currentWindow = debugWindow,
              let mainWindow = mainWindow else {
            print("debugWindow 或 mainWindow 为空")
            return
        }

        let currentFrame = currentWindow.frame
        var newFrame = currentFrame

        // 计算贴合位置
        if currentWindow.frame.midX < mainWindow.frame.midX {
            // 当前窗口在左边，贴合到目标窗口的左边
            newFrame.origin.x = mainWindow.frame.minX
                                - currentFrame.width
                                - debugWindowMainWindowSpacing
            newFrame.origin.y = mainWindow.frame.minY
            newFrame.size.height = mainWindow.frame.size.height
            debugWindowSide = .left
        } else {
            // 当前窗口在右边，贴合到目标窗口的右边
            newFrame.origin.x = mainWindow.frame.maxX
                                + debugWindowMainWindowSpacing
            newFrame.origin.y = mainWindow.frame.minY
            newFrame.size.height = mainWindow.frame.size.height
            debugWindowSide = .right
        }

        // 动画1
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.45
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true

            currentWindow.animator().setFrame(newFrame, display: true, animate: true)
        }, completionHandler: {
            // 动画完成后设置为子窗口
            mainWindow.addChildWindow(currentWindow, ordered: .above)
            #if DEVELOPMENT
            baDebugState.shared.system("吸附完成")
            #endif
        })

        // 动画2：使用 Core Animation 显式动画
        // let animation = CABasicAnimation(keyPath: "frame")
        // animation.fromValue = NSValue(rect: currentFrame)
        // animation.toValue = NSValue(rect: newFrame)
        // animation.duration = 0.45
        // animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        // currentWindow.animations = ["frame": animation]
        // currentWindow.animator().setFrame(newFrame, display: true)
        // DispatchQueue.main.asyncAfter(deadline: .now() + animation.duration) {
        //     mainWindow.addChildWindow(currentWindow, ordered: .above)
        //     DebugState.shared.addMessage("吸附完成", type: .info)
        // }

        // 动画3：使用弹簧动画效果
        // NSAnimationContext.runAnimationGroup({ context in
        // context.duration = 0.8
        // context.timingFunction = CAMediaTimingFunction(
        //     controlPoints: 0.5, 1.8, 0.585, 0.885
        // )
        // context.allowsImplicitAnimation = true
        // currentWindow.animator().setFrame(newFrame, display: true, animate: true)
        // }, completionHandler: {
        //     mainWindow.addChildWindow(currentWindow, ordered: .above)
        //     DebugState.shared.addMessage("吸附完成", type: .info)
        // })

        // 动画4：分步动画
        // let positionFrame = NSRect(
        //     x: newFrame.origin.x,
        //     y: currentFrame.origin.y,
        //     width: currentFrame.width,
        //     height: currentFrame.height
        // )
        // NSAnimationContext.runAnimationGroup({ context in
        //     context.duration = 0.25
        //     context.timingFunction = CAMediaTimingFunction(name: .easeOut)
        //     currentWindow.animator().setFrame(positionFrame, display: true)
        // }, completionHandler: {
        //     // 第二步：调整大小
        //     NSAnimationContext.runAnimationGroup({ context in
        //         context.duration = 0.2
        //         context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        //         currentWindow.animator().setFrame(newFrame, display: true)
        //     }, completionHandler: {
        //         mainWindow.addChildWindow(currentWindow, ordered: .above)
        //         DebugState.shared.addMessage("吸附完成", type: .info)
        //     })
        // })

        windowState = .attached
    }
}
