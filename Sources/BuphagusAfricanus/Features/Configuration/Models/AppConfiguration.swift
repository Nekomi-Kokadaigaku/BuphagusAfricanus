import Foundation


// 使用属性包装器简化配置管理
@propertyWrapper
struct UserDefaultsBacked<T> {
    let key: String
    let defaultValue: T

    var wrappedValue: T {
        get { UserDefaults.standard.object(forKey: key) as? T ?? defaultValue }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

class AppConfiguration {
    @UserDefaultsBacked(key: "debug_window_show_details", defaultValue: false)
    var showDetails: Bool

    @UserDefaultsBacked(key: "debug_window_auto_scroll", defaultValue: true)
    var autoScroll: Bool
}
