// MARK: - 错误定义
enum baConfigurationError: Error {
    case invalidPath
    case saveFailed(Error)
    case loadFailed(Error)
}
