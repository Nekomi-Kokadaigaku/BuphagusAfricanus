import AppKit


// 将窗口管理器拆分为多个协议
protocol WindowManageable {
    func handleWindowMove()
    func handleWindowResize()
    func handleWindowSnap()
}

protocol WindowAnimatable {
    func animate(window: NSWindow, to frame: NSRect)
}

// 分离窗口状态管理
class WindowStateManager {
    // 管理窗口状态相关逻辑
}

// 分离窗口动画管理
class WindowAnimationManager {
    // 管理窗口动画相关逻辑
}
