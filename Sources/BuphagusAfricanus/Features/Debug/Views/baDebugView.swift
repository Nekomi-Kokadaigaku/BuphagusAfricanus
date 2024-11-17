import SwiftUI
import AppKit
import QuartzCore
import Combine
import Foundation


/// 调试视图
struct baDebugView: View {
    let windowId: String

    @State private var autoScroll = baDebugState.shared.autoScroll
    @State private var isPaused = baDebugState.shared.isPaused
    @StateObject private var manager = baWindowManager.shared
    @StateObject private var debugState = baDebugState.shared
    @StateObject private var themeManager = baThemeManager.shared
    @StateObject private var performanceMonitor = baPerformanceMonitor.shared
    @StateObject private var keyboardManager = baKeyboardShortcutManager.shared

    var body: some View {

        // 背景色
        // Color(NSColor.windowBackgroundColor)
        //     .ignoresSafeArea()
        // LinearGradient(
        //     gradient: Gradient(colors: [Color.purple, Color.blue]),
        //     startPoint: .topLeading,
        //     endPoint: .bottomTrailing
        // )
        // LinearGradient(
        //     gradient: Gradient(colors: [Color(hex: "2C3E50"), Color(hex: "3498DB")]),
        //     startPoint: .topLeading,
        //     endPoint: .bottomTrailing
        // )
        // themeManager.currentTheme.backgroundColor
        //     .ignoresSafeArea()

        VStack(spacing: 0) {
            toolbarView
                .frame(maxWidth: .infinity)
                .background(themeManager.currentTheme.toolbarColor)
            Divider()

            // 主要内容区域
            GeometryReader { geometry in
                VSplitView {
                    // 消息列表视图，设置最小高度
                    messageListView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(themeManager.currentTheme.backgroundColor)

                    // 监视面板视图，设置固定高度范围
                    if debugState.showWatchPanel {
                        watchPanelView
                            .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 120)
                    }

                    // 性能监控面板
                    performancePanel
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 23)
                        .background(themeManager.currentTheme.toolbarColor)
                }
            }
        }

        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minWidth: 350)
        .background(baVisualEffectView().ignoresSafeArea())
        .allowsHitTesting(true)
        .onAppear {
            #if DEVELOPMENT
            debugState.info("调试窗口已显示")
            #endif
            debugState.updateWatchVariable(name: "isReadyToSnap", value: manager.isReadyToSnap, type: "Bool")
            debugState.updateWatchVariable(name: "windowState", value: manager.windowState.rawValue, type: "String")
            debugState.updateWatchVariable(name: "windowMode", value: manager.windowMode.rawValue, type: "String")
            debugState.updateWatchVariable(name: "debugWindowSide", value: manager.debugWindowSide.rawValue, type: "String")
            debugState.updateWatchVariable(name: "targetFrameX", value: manager.targetFrame.origin.x, type: "Int")
            debugState.updateWatchVariable(name: "targetFrameY", value: manager.targetFrame.origin.y, type: "Int")
        }
        .onDisappear {
            // 发送重置通知
            NotificationCenter.default.post(
                name: NSNotification.Name("ResetDebugState"),
                object: nil
            )
        }
        // .background(themeManager.currentTheme.backgroundColor)
        .onChange(of: autoScroll) { _, newValue in
            debugState.autoScroll = newValue
        }
        .onChange(of: isPaused) { _, newValue in
            debugState.isPaused = newValue
        }
    }
}

// MARK: - 工具栏视图
extension baDebugView {

    /// 工具栏视图
    private var toolbarView: some View {
        VStack(spacing: 8) {
            // 第一行
            HStack {
                // 消息类型选择器
                Menu {
                    Button(action: { debugState.selectedMessageType = nil }) {
                        HStack {
                            Image(systemName: "text.line.first.and.arrowtriangle.forward")
                            Text("全部")
                            if debugState.selectedMessageType == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    Divider()
                    ForEach(DebugMessageType.allCases, id: \.self) { type in
                        Button(action: { debugState.selectedMessageType = type }) {
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                Text(type.rawValue)
                                Spacer()
                                if debugState.selectedMessageType == type {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: debugState.selectedMessageType?.icon ?? "text.line.first.and.arrowtriangle.forward")
                            .foregroundColor(debugState.selectedMessageType?.color ?? .primary)
                        Text(debugState.selectedMessageType?.rawValue ?? "全部")
                            .font(.system(size: 12))
                            .contentTransition(.opacity)
                            .transaction { transaction in
                                transaction.animation = .easeInOut(duration: 0.2).delay(0.1)
                            }
                    }
                }
                .animation(.spring(duration: 0.3), value: debugState.selectedMessageType)
                .buttonStyle(baCapsuleButtonStyle())
                .help("筛选消息类型")

                // 详情显示开关
                capsuleButton(label:
                                Image(systemName: debugState.showDetails ? "info.circle.fill" : "info.circle")
                                    // .symbolRenderingMode(.hierarchical)
                                    .padding(.horizontal,0.5)
                                    .foregroundStyle(debugState.showDetails ? .blue : .secondary), action: {
                    withAnimation {
                        debugState.showDetails.toggle()
                    }
                    UserDefaults.standard.set(debugState.showDetails, forKey: "debug_window_show_details")
                })

                // 模式切换按钮
                capsuleButton(label:
                                Image(systemName: manager.windowMode == .animation ? "sparkles" : "bolt.fill"), action: {
                    withAnimation {
                        manager.windowMode = manager.windowMode == .animation ? .direct : .animation
                    }
                })

                // 监视面板开关
                capsuleButton(label:
                                Image(systemName: debugState.showWatchPanel ? "eye.slash" : "eye"), action: {
                    withAnimation {
                        debugState.showWatchPanel.toggle()
                    }
                })

                // 配置窗口开关
                capsuleButton(label: Image(systemName: "gearshape"), action: {
                    baConfigureWindowDelegate.shared.showConfigureWindow()
                })

                Spacer()
            }

            // 第二行
            HStack(spacing: 8) {
                // 复位按钮
                capsuleButton(systemImage: "arrow.left.to.line", action: {
                    manager.snapDebugWindowToMain()
                    NSApp.stopModal()
                })

                // 导出日志按钮
                capsuleButton(systemImage: "square.and.arrow.up", action: {
                    debugState.exportCurrentMessages()
                })


                // 清除按钮
                capsuleButton(systemImage: "trash", action: {
                    debugState.clearMessages()
                })

                Spacer()
            }

            // 第三行
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                // 搜索框
                TextField("搜索", text: $debugState.searchText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                    .allowsHitTesting(true)
                    .simultaneousGesture(TapGesture().onEnded { _ in
                        NSApp.stopModal()
                    })
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        // .background(Color(NSColor.windowBackgroundColor))
        .background(Color.clear)
    }
}

// MARK: - 胶囊按钮样式
extension baDebugView{

    @ViewBuilder
    private func capsuleButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
        }
        .buttonStyle(baCapsuleButtonStyle())
    }

    @ViewBuilder
    private func capsuleButton(label: some View, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            label
        }
        .buttonStyle(baCapsuleButtonStyle())
    }
}

// MARK: - 消息列表视图
extension baDebugView{

    /// 消息列表视图 - 根据是否有消息显示不同内容
    private var messageListView: some View {
        Group {
            if filteredMessages.isEmpty {
                emptyStateView
            } else {
                messageScrollView
            }
        }
    }
}

// MARK: - 空状态视图
extension baDebugView{

    /// 空状态视图
    private var emptyStateView: some View {
        VStack {
            Spacer()
            Text("暂无调试信息")
                .foregroundColor(.gray)
                .font(.system(size: 13))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 消息滚动视图
extension baDebugView{

    /// 消息滚动视图
    private var messageScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) { // 禁用滚动条
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(filteredMessages) { message in
                        baMessageRow(message: message)
                            .id(message.id)
                    }
                }
                .padding(.vertical, 8)
            }
            .listStyle(.plain)
//             自动滚动到最新消息
             .onChange(of: debugState.debugMessages.count) { oldValue, newValue in
                 if let lastMessage = filteredMessages.last {
                     withAnimation {
                         proxy.scrollTo(lastMessage.id, anchor: .bottom)
                     }
                 }
             }
        }
    }
}

// MARK: - 监视变量面板视图
extension baDebugView {

    /// 监视变量面板视图
    private var watchPanelView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("监视变量")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(themeManager.currentTheme.toolbarColor)

            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(debugState.watchVariables) { variable in
                        baWatchVariableView(variable: variable)
                    }
                }
                .padding(8)
            }
        }
        .background(themeManager.currentTheme.backgroundColor)
    }
}

// MARK: - 变量信息视图
struct baWatchVariableView: View {

    let variable: baWatchVariable

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(variable.name)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
            Text("\(variable.value)")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(6)
        .background(Color(.systemGray).opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - 性能指标视图组件
extension baDebugView {

    /// 性能监控面板
    private var performancePanel: some View {
        HStack(spacing: 16) {
            PerformanceMetricView(
                title: "CPU",
                value: performanceMonitor.formattedCPUUsage,
                icon: "cpu"
            )
            Spacer()
            PerformanceMetricView(
                title: "内存",
                value: performanceMonitor.formattedMemoryUsage,
                icon: "memorychip"
            )
            PerformanceMetricView(
                title: "FPS",
                value: performanceMonitor.formattedFPS,
                icon: "gauge"
            )
        }
    }
}

/// 性能指标视图组件
private struct PerformanceMetricView: View {

    let title: String
    let value: String
    let icon: String

    var body: some View {
        Label {
            Text(value)
                .font(.system(.body, design: .monospaced))
        } icon: {
            Image(systemName: icon)
        }
        .foregroundColor(.primary)
    }
}

extension baDebugView{
    private var filteredMessages: [baDebugMessage] {
        let messages = debugState.filteredMessages()
        if debugState.searchText.isEmpty {
            return messages
        }
        return messages.filter { $0.content.localizedCaseInsensitiveContains(debugState.searchText) }
    }
}

// MARK: - 单条消息行视图
struct baMessageRow: View {

    let message: baDebugMessage

    @ObservedObject var debugState: baDebugState = .shared
    @StateObject private var themeManager = baThemeManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // 消息主体 - 使用 HStack 水平布局图标和文本
            HStack(alignment: .top, spacing: 4) {
                // 消息类型图标 - 固定宽度确保对齐
                Image(systemName: message.type.icon)
                    .foregroundColor(message.type.color)
                    .frame(width: 16)

                // 消息文本 - 允许多行显示
                Text(message.formattedMessage)
                    .lineLimit(nil)

                // 使用 Spacer 确保内容左对齐
                Spacer(minLength: 0)
            }
            .font(.system(size: 12, design: .monospaced))
            .foregroundColor(message.type.color)
            .textSelection(.enabled)

            // 详细信息部分 - 仅在启用详情显示时可见
            if let details = message.details {
                if debugState.showDetails {
                    HStack {
                        Text(details)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            // 添加展开/收起动画
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            ))
                    }
                    .padding(.leading, 20) // 在 HStack 上设置 padding
                }
            }
        }
        // 设置消息行的内边距和布局
        .padding(.vertical, 3)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        // 添加背景效果
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.primary.opacity(0.05))
                .padding(.horizontal, 4)
        )
        // 添加详情切换动画
        .animation(.easeInOut(duration: 0.2), value: debugState.showDetails)
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}


// MARK: - 流式布局视图
struct FlowLayout: Layout {
    /// 元素之间的间距
    var spacing: CGFloat = 4

    /// 计算布局大小
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    /// 放置子视图
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)

        // 遍历每一行放置子视图
        for row in result.rows {
            for item in row {
                let x = bounds.minX + item.x
                let y = bounds.minY + item.y
                item.subview.place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(item.size)
                )
            }
        }
    }

    /// 流式布局结果结构
    struct FlowResult {
        /// 所有行
        var rows: [[Item]] = []
        /// 总高度
        var height: CGFloat = 0

        /// 布局项结构
        struct Item {
            let subview: LayoutSubview
            var size: CGSize
            var x: CGFloat
            var y: CGFloat
        }

        /// 初始化并计算布局
        init(in width: CGFloat, spacing: CGFloat, subviews: LayoutSubviews) {
            var currentRow: [Item] = []
            var x: CGFloat = 0
            var y: CGFloat = 0
            var maxHeight: CGFloat = 0

            // 遍历所有子视图计算位置
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                // 如果当前行放不下，开始新行
                if x + size.width > width && !currentRow.isEmpty {
                    rows.append(currentRow)
                    currentRow = []
                    x = 0
                    y += maxHeight + spacing
                    maxHeight = 0
                }

                currentRow.append(Item(subview: subview, size: size, x: x, y: y))
                x += size.width + spacing
                maxHeight = max(maxHeight, size.height)
            }

            // 处理最后一行
            if !currentRow.isEmpty {
                rows.append(currentRow)
                y += maxHeight
            }

            self.height = y
        }
    }
}

// MARK: - 变量监视面板视图
extension baDebugView {
    /// 变量监视面板视图
    // private var watchPanelView: some View {
    //     VStack(spacing: 0) {
    //         // 面板头部
    //         HStack {
    //             HStack(spacing: 4) {
    //                 Image(systemName: "gauge")
    //                     .font(.system(size: 11))
    //                 Text("变量监视")
    //                     .font(.system(size: 11, weight: .medium))
    //             }
    //             .foregroundColor(.secondary)

    //             Spacer()

    //             // 清除按钮
    //             Button(action: {
    //                 debugState.clearWatchVariables()
    //             }) {
    //                 Image(systemName: "trash")
    //                     .font(.system(size: 9))
    //                     .foregroundColor(.gray)
    //             }
    //             .buttonStyle(.plain)
    //             .help("清除所有监视变量")
    //         }
    //         .padding(.horizontal, 8)
    //         .padding(.vertical, 4)

    //         Divider()

    //         // 变量列表内容
    //         if debugState.watchVariables.isEmpty {
    //             // 空状态显示
    //             VStack {
    //                 Text("暂无监视变量")
    //                     .font(.system(size: 11))
    //                     .foregroundColor(.secondary)
    //             }
    //             .frame(maxWidth: .infinity)
    //             .padding(.vertical, 8)
    //         } else {
    //             // 变量列表
    //             ScrollView(.vertical, showsIndicators: false) {
    //                 FlowLayout(spacing: 4) {
    //                     ForEach(debugState.watchVariables) { variable in
    //                         WatchVariableRow(variable: variable)
    //                             .fixedSize()
    //                     }
    //                 }
    //                 .padding(4)
    //             }
    //         }
    //     }
    //     .background(Color.clear)
    // }
}

// MARK: - 添加监视变量行视图
struct baWatchVariableRow: View {
    @ObservedObject var debugState: baDebugState = .shared
    let variable: baWatchVariable

    // 根据变量类型和值获取显示颜色
    private var valueColor: Color {
        // 处理布尔值
        if variable.value == "true" {
            return .green
        } else if variable.value == "false" {
            return .red
        }

        // 根据变量类型设置颜色
        switch variable.type {
        case "Int", "Double", "Float":  // 数字类型
            return .blue
        case "String":                  // 字符串类型
            return .orange
        case "Window":                  // 窗口相关状态
            return .purple
        case "Bool":                    // 布尔值（非 true/false 的情况）
            return .gray
        default:                        // 其他类型
            return .primary
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            // 变量名和值
            HStack(spacing: 4) {
                Text(variable.name)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Text("=")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Text(variable.value)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(valueColor)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            // 删除按钮
            Button(action: {
                debugState.removeWatchVariable(name: variable.name)
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
            .opacity(0.6)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 1)
        .background(
            Capsule()
                .fill(Color.primary.opacity(0.06))
        )
        .frame(height: 16)
    }
}
