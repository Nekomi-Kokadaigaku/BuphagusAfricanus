import Foundation
import QuartzCore
import CoreVideo


/// 性能监控管理器
class baPerformanceMonitor: ObservableObject {
    static let shared = baPerformanceMonitor()

    @Published private(set) var cpuUsage: Double = 0
    @Published private(set) var memoryUsage: UInt64 = 0
    @Published private(set) var fps: Double = 0

    private var timer: Timer?
    private var displayLink: CVDisplayLink?
    private var frameCount: UInt = 0
    private var lastFrameTime: Double = 0

    private init() {
        setupMonitoring()
    }

    private func setupMonitoring() {
        // 设置定时器，每秒更新一次性能数据
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }

        // 设置 DisplayLink 以计算 FPS
        setupDisplayLink()
    }

    private func setupDisplayLink() {
        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        guard let link = link else { return }

        let opaqueself = Unmanaged.passUnretained(self).toOpaque()
        CVDisplayLinkSetOutputCallback(link, { (displayLink, _, _, _, _, opaquePointer) -> CVReturn in
            let mySelf = Unmanaged<baPerformanceMonitor>.fromOpaque(opaquePointer!).takeUnretainedValue()
            mySelf.frameCount += 1

            let currentTime = Double(CVGetCurrentHostTime())
            let hostFrequency = Double(CVGetHostClockFrequency())

            if currentTime - Double(mySelf.lastFrameTime) >= hostFrequency {
                DispatchQueue.main.async {
                    mySelf.fps = Double(mySelf.frameCount)
                    mySelf.frameCount = 0
                    mySelf.lastFrameTime = currentTime
                }
            }

            return kCVReturnSuccess
        }, opaqueself)

        self.displayLink = link
        CVDisplayLinkStart(link)
    }

    private func updateMetrics() {
        cpuUsage = getCPUUsage()
        memoryUsage = getMemoryUsage()
    }

    // 获取 CPU 使用率
    private func getCPUUsage() -> Double {
        var totalUsageOfCPU: Double = 0.0
        var threadsList: thread_act_array_t?
        var threadsCount = mach_msg_type_number_t(0)
        let threadsResult = task_threads(mach_task_self_, &threadsList, &threadsCount)

        if threadsResult == KERN_SUCCESS, let threadsList = threadsList {
            for index in 0..<threadsCount {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(threadsList[Int(index)],
                                  thread_flavor_t(THREAD_BASIC_INFO),
                                  $0,
                                  &threadInfoCount)
                    }
                }

                if infoResult == KERN_SUCCESS {
                    let threadBasicInfo = threadInfo
                    if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                        totalUsageOfCPU = (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE)) * 100.0
                    }
                }
            }

            vm_deallocate(mach_task_self_,
                         vm_address_t(UInt(bitPattern: threadsList)),
                         vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride))
        }

        return totalUsageOfCPU
    }

    // 获取内存使用量
    private func getMemoryUsage() -> UInt64 {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(TASK_VM_INFO),
                         $0,
                         &count)
            }
        }

        if result == KERN_SUCCESS {
            return taskInfo.phys_footprint
        }

        return 0
    }

    deinit {
        timer?.invalidate()
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
    }
}

// MARK: - 格式化扩展
extension baPerformanceMonitor {
    /// 格式化的CPU使用率
    var formattedCPUUsage: String {
        String(format: "CPU: %.1f%%", cpuUsage)
    }

    /// 格式化的内存使用量
    var formattedMemoryUsage: String {
        String(format: "内存: %.1f MB", Double(memoryUsage) / 1024 / 1024)
    }

    /// 格式化的帧率
    var formattedFPS: String {
        String(format: "FPS: %.1f", fps)
    }
}
