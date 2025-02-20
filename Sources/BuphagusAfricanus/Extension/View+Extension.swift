//
//  View+Extension.swift
//  BuphagusAfricanus
//
//  Created by Iris on 2025-02-18.
//

import SwiftUI

extension View {

    /// 调试用padding
    /// - Parameters:
    ///   - edges: 添加padding的方向
    ///   - length: padding大小 .padding()默认加的是32x32
    ///   - color: 显示外边框的颜色
    /// - Returns: 修改后的视图
    public func padding(
        _ edges: Edge.Set = .all,
        _ length: CGFloat? = nil,
        _ color: Color = .random,
        _ detail: String? = nil,
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
                                if [.topRight, .topCenter, .bottomRight, .bottomCenter, .centerRight].contains(leading) {
                                    Spacer()
                                }

                                VStack {
                                    // 顶部Spacer
                                    if [.bottomLeft, .bottomRight, .bottomCenter, .centerLeft, .centerRight].contains(leading) {
                                        Spacer()
                                    }

                                    Text("\(Int(geometry.size.width))×\(Int(geometry.size.height))-\(detail ?? "nil")")

                                    // 底部Spacer
                                    if [.topLeft, .topRight, .topCenter, .centerLeft, .centerRight].contains(leading) {
                                        Spacer()
                                    }
                                }

                                // 右侧Spacer
                                if [.topLeft, .bottomLeft, .topCenter, .bottomCenter, .centerLeft].contains(leading) {
                                    Spacer()
                                }
                            }
                            .font(.system(size: 10))
                            .foregroundColor(color)
                            .opacity(0.8)
                        }
                    }
                )
                .ignoresSafeArea()
        #else
            self.padding(edges, length)
        #endif
    }
}

public enum Dic {
    case topLeft, topRight, bottomLeft, bottomRight
    case topCenter, bottomCenter, centerLeft, centerRight
}
