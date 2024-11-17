import Foundation


/// 配置管理器
class baConfigurationManager: ObservableObject {
    // 使用懒加载属性而不是闭包初始化
//    private static var instance: baConfigurationManager?
//
//    static var shared: baConfigurationManager {
//        if instance == nil {
//            instance = baConfigurationManager()
//        }
//        return instance!
//    }
    static let shared = baConfigurationManager()

    @Published private(set) var config: baConfiguration

    private init() {
        print("ConfigurationManager: Initializing...")

        // 先设置默认配置
        self.config = .default

        // 创建配置目录
        createConfigurationDirectory()

        // 尝试加载配置
        loadConfiguration()

        print("ConfigurationManager: Initialization completed")
    }
}

// MARK: - 配置文件操作
extension baConfigurationManager {
    
    /// 获取配置文件路径
    private var configFileURL: URL? {
        do {
            let appSupport = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let bundleID = Bundle.main.bundleIdentifier ?? "com.app.debugwindow"
            print("ConfigurationManager: Bundle ID - \(bundleID)")
            print("ConfigurationManager: App Support - \(appSupport)")
            let appFolder = appSupport.appendingPathComponent(bundleID)
            return appFolder.appendingPathComponent(config.configFileName)
        } catch {
            print(
                "ConfigurationManager: Failed to get config file URL - \(error)"
            )
            return nil
        }
    }

    /// 创建配置文件目录
    private func createConfigurationDirectory() {
        guard let fileURL = configFileURL else {
            print("ConfigurationManager: No valid config file URL")
            return
        }

        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            print("ConfigurationManager: Directory created successfully")
        } catch {
            print("ConfigurationManager: Failed to create directory - \(error)")
        }
    }

    /// 加载配置
    private func loadConfiguration() {
        guard let fileURL = configFileURL else { return }

        do {
            // 如果文件不存在，返回 nil（将使用默认配置）
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                return
            }

            // 读取配置文件
            let data = try Data(contentsOf: fileURL)
            let config = try JSONDecoder().decode(
                baConfiguration.self, from: data)
            self.config = config
        } catch {
            #if DEBUG
                print("Failed to load configuration: \(error)")
            #endif
        }
    }

    /// 保存配置
    func saveConfiguration(_ config: baConfiguration) throws {
        guard let fileURL = configFileURL else {
            throw baConfigurationError.invalidPath
        }

        do {
            let data = try JSONEncoder().encode(config)
            try data.write(to: fileURL)
            self.config = config
        } catch {
            throw baConfigurationError.saveFailed(error)
        }
    }
}

// MARK: - 配置更新方法
extension baConfigurationManager {

    /// 更新窗口配置
    func updateWindowConfig(_ config: baConfiguration.WindowConfig) {
        var newConfig = self.config
        newConfig.window = config
        try? saveConfiguration(newConfig)
    }

    /// 更新性能监控配置
    func updatePerformanceConfig(_ config: baConfiguration.PerformanceConfig) {
        var newConfig = self.config
        newConfig.performance = config
        try? saveConfiguration(newConfig)
    }

    /// 更新日志配置
    func updateLogConfig(_ config: baConfiguration.LogConfig) {
        var newConfig = self.config
        newConfig.log = config
        try? saveConfiguration(newConfig)
    }
}
