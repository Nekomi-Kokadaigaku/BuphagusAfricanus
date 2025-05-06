//
//  View+Extension.swift
//  BuphagusAfricanus
//

import SwiftUI

extension View {

    /// 带边框显示的 padding
    /// - Parameters:
    ///   - edges: 添加 padding 的方向
    ///   - length: padding 大小 .padding() 默认 16px
    ///   - color: 边框颜色颜色
    /// - Returns: 修改后的视图
    public func padding(
        _ edges:   Edge.Set = .all,
        _ length:  CGFloat? = 16,
        _ color:   Color = .random,
        _ detail:  String? = nil,
        _ leading: Dic? = .topLeft
    ) -> some View {

        #if DEBUG
            self
                .padding(edges, length)
                .overlay(
                    GeometryReader { geometry in
                        ZStack {
                            Rectangle()
                                .stroke(color, lineWidth: 1)
                                .opacity(0.5)
                            HStack {
                                // 左侧Spacer
                                if [
                                    .topRight, .topCenter, .bottomRight,
                                    .bottomCenter, .centerRight,
                                ].contains(
                                    leading)
                                {
                                    Spacer()
                                }

                                VStack {
                                    // 顶部Spacer
                                    if [
                                        .bottomLeft, .bottomRight,
                                        .bottomCenter, .centerLeft,
                                        .centerRight,
                                    ].contains(
                                        leading)
                                    {
                                        Spacer()
                                    }

                                    Text(
                                        "\(Int(geometry.size.width))×\(Int(geometry.size.height))-\(detail ?? "nil")"
                                    )

                                    // 底部Spacer
                                    if [
                                        .topLeft, .topRight, .topCenter,
                                        .centerLeft, .centerRight,
                                    ].contains(leading) {
                                        Spacer()
                                    }
                                }

                                // 右侧Spacer
                                if [
                                    .topLeft, .bottomLeft, .topCenter,
                                    .bottomCenter, .centerLeft,
                                ].contains(leading) {
                                    Spacer()
                                }
                            }
                            .font(.system(size: 7))
                            .foregroundColor(color)
                            .opacity(0.4)
                        }
                    }
                )
        #else
            self.padding(edges, length)
        #endif
    }
}


public enum Dic {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case topCenter
    case bottomCenter
    case centerLeft
    case centerRight
}
