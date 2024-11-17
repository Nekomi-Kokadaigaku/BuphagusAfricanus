import SwiftUI


/// 配置视图
struct baConfigurationView: View {
    
    @ObservedObject private var configManager = baConfigurationManager.shared
    @State private var windowConfig: baConfiguration.WindowConfig
    @State private var performanceConfig: baConfiguration.PerformanceConfig
    @State private var logConfig: baConfiguration.LogConfig

    init() {
        _windowConfig = State(initialValue: baConfigurationManager.shared.config.window)
        _performanceConfig = State(initialValue: baConfigurationManager.shared.config.performance)
        _logConfig = State(initialValue: baConfigurationManager.shared.config.log)
    }

    var body: some View {
        Form {
            // 窗口配置
            Section("窗口设置") {
                HStack {
                    Text("默认宽度")
                    Slider(value: $windowConfig.defaultWidth, in: 200...800)
                    Text("\(Int(windowConfig.defaultWidth))")
                }
                HStack {
                    Text("默认高度")
                    Slider(value: $windowConfig.defaultHeight, in: 200...800)
                    Text("\(Int(windowConfig.defaultHeight))")
                }
                HStack {
                    Text("吸附距离")
                    Slider(value: $windowConfig.snapDistance, in: 20...200)
                    Text("\(Int(windowConfig.snapDistance))")
                }
            }

            // 性能监控配置
            Section("性能监控") {
                Toggle("CPU监控", isOn: $performanceConfig.enableCPUMonitoring)
                Toggle("内存监控", isOn: $performanceConfig.enableMemoryMonitoring)
                Toggle("FPS监控", isOn: $performanceConfig.enableFPSMonitoring)
                HStack {
                    Text("更新间隔")
                    Slider(value: $performanceConfig.updateInterval, in: 0.1...5.0)
                    Text(String(format: "%.1f秒", performanceConfig.updateInterval))
                }
            }

            // 日志配置
            Section("日志设置") {
                Toggle("自动导出", isOn: $logConfig.autoExportEnabled)
                HStack {
                    Text("最大消息数")
                    TextField("", value: $logConfig.maxMessageCount, formatter: NumberFormatter())
                }
                HStack {
                    Text("保留时间")
                    TextField("", value: $logConfig.messageRetentionPeriod, formatter: NumberFormatter())
                    Text("秒")
                }
            }

            // 保存按钮
            Button("保存配置") {
                saveAllConfigs()
                baConfigureWindowDelegate.shared.hideConfigureWindow()
            }
            .buttonStyle(baCapsuleButtonStyle())
        }
        .padding()
    }

    private func saveAllConfigs() {
        configManager.updateWindowConfig(windowConfig)
        configManager.updatePerformanceConfig(performanceConfig)
        configManager.updateLogConfig(logConfig)
    }
}
