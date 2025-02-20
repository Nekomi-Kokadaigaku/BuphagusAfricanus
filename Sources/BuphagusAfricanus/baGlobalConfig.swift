//
//  baGlobalConfig.swift
//  BuphagusAfricanus
//
//  Created by Iris on 2025-02-20.
//


import Foundation

/// 全局配置管理器
public class baGlobalConfig {
    /// 共享实例
    public static let shared = baGlobalConfig()
    
    /// 是否启用调试模式
    @Published private(set) var isDebugMode: Bool = false
    
    /// 是否启用详细日志
    @Published private(set) var isVerboseLogging: Bool = false
    
    /// 自定义配置项
    private var customConfigs: [String: Any] = [:]
    
    private init() {}
    
    /// 设置调试模式
    public func setDebugMode(_ enabled: Bool) {
        isDebugMode = enabled
        baDebugState.shared.system(
            "Debug mode \(enabled ? "enabled" : "disabled")",
            details: "Set by baGlobalConfig"
        )
    }
    
    /// 设置详细日志
    public func setVerboseLogging(_ enabled: Bool) {
        isVerboseLogging = enabled
        baDebugState.shared.system(
            "Verbose logging \(enabled ? "enabled" : "disabled")",
            details: "Set by baGlobalConfig"
        )
    }
    
    /// 设置自定义配置项
    public func setConfig(_ value: Any, forKey key: String) {
        customConfigs[key] = value
        baDebugState.shared.system(
            "Custom config set",
            details: "Key: \(key), Value: \(value)"
        )
    }
    
    /// 获取自定义配置项
    public func getConfig<T>(forKey key: String) -> T? {
        return customConfigs[key] as? T
    }
}