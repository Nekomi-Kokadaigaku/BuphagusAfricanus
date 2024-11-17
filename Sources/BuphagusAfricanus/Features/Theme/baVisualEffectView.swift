import Foundation
import SwiftUI


/// 毛玻璃视图
struct baVisualEffectView: NSViewRepresentable {
    func makeNSView(context _: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.state = .active
        return effectView
    }

    func updateNSView(_: NSVisualEffectView, context _: Context) {}
}
