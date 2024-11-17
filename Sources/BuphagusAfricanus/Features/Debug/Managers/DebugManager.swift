//class DebugManager {
//    // 添加缓存清理机制
//    private let cacheLimit = 1000
//    private var messageCache: [DebugMessage] = []
//
//    func cleanupCache() {
//        if messageCache.count > cacheLimit {
//            messageCache.removeFirst(messageCache.count - cacheLimit)
//        }
//    }
//
//    // 使用弱引用避免循环引用
//    weak var delegate: DebugManagerDelegate?
//}
