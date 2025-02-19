//
//  File.swift
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
        _ color: Color = .yellow,
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
extension Color {
    /// 生成随机颜色
    public var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}
public enum Dic {
    case topLeft, topRight, bottomLeft, bottomRight
    case topCenter, bottomCenter, centerLeft, centerRight
}
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
