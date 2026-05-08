import Darwin
import Foundation

@MainActor
final class CPUMonitor: NSObject {
    var onLoadUpdate: ((Double) -> Void)?

    private var previousTicks: [CPUTicks] = []
    private var timer: Timer?
    private var smoothedLoad = 0.0
    private let smoothingFactor = 0.28

    func start() {
        guard timer == nil else { return }
        previousTicks = readTicks()
        let timer = Timer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(handleTimer(_:)),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        sample()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func sample() {
        let currentTicks = readTicks()
        defer { previousTicks = currentTicks }

        guard currentTicks.count == previousTicks.count, !currentTicks.isEmpty else {
            return
        }

        let rawLoad = zip(previousTicks, currentTicks)
            .map { previous, current in previous.load(comparedTo: current) }
            .reduce(0.0, +) / Double(currentTicks.count)

        if smoothedLoad == 0 {
            smoothedLoad = rawLoad
        } else {
            smoothedLoad = (smoothingFactor * rawLoad) + ((1.0 - smoothingFactor) * smoothedLoad)
        }

        onLoadUpdate?(smoothedLoad)
    }

    @objc private func handleTimer(_ timer: Timer) {
        sample()
    }

    private func readTicks() -> [CPUTicks] {
        var cpuInfo: processor_info_array_t?
        var processorCount: natural_t = 0
        var infoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &cpuInfo,
            &infoCount
        )

        guard result == KERN_SUCCESS, let cpuInfo else {
            return []
        }

        defer {
            let byteCount = vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: cpuInfo)), byteCount)
        }

        let stateCount = Int(CPU_STATE_MAX)
        return (0..<Int(processorCount)).map { index in
            let base = index * stateCount
            return CPUTicks(
                user: UInt64(cpuInfo[base + Int(CPU_STATE_USER)]),
                system: UInt64(cpuInfo[base + Int(CPU_STATE_SYSTEM)]),
                idle: UInt64(cpuInfo[base + Int(CPU_STATE_IDLE)]),
                nice: UInt64(cpuInfo[base + Int(CPU_STATE_NICE)])
            )
        }
    }
}

private struct CPUTicks {
    let user: UInt64
    let system: UInt64
    let idle: UInt64
    let nice: UInt64

    func load(comparedTo current: CPUTicks) -> Double {
        let userDelta = current.user.saturatingSubtract(user)
        let systemDelta = current.system.saturatingSubtract(system)
        let idleDelta = current.idle.saturatingSubtract(idle)
        let niceDelta = current.nice.saturatingSubtract(nice)
        let busy = userDelta + systemDelta + niceDelta
        let total = busy + idleDelta

        guard total > 0 else { return 0 }
        return Double(busy) / Double(total)
    }
}

private extension UInt64 {
    func saturatingSubtract(_ value: UInt64) -> UInt64 {
        self >= value ? self - value : 0
    }
}
