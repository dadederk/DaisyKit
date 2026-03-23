import Foundation

struct PerformanceMetrics {
    static func measure(_ block: () async throws -> Void) async throws -> TimeInterval {
        let start = ContinuousClock.now
        try await block()
        let end = ContinuousClock.now
        return start.duration(to: end).timeInterval
    }
}

private extension Duration {
    var timeInterval: TimeInterval {
        let components = self.components
        let seconds = Double(components.seconds)
        let attoseconds = Double(components.attoseconds) / 1_000_000_000_000_000_000
        return seconds + attoseconds
    }
}
