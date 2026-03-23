import Foundation
import Testing
@testable import DaisyKit
#if canImport(Darwin)
import Darwin
#endif

struct DummyFixtureToken: Sendable {
    let label: String
}

struct StubFixtureManifestLoader {
    let descriptors: [FixtureDescriptor]

    func load() -> [FixtureDescriptor] {
        descriptors
    }
}

final class SpyParseRunRecorder {
    private(set) var runDurations: [TimeInterval] = []

    func record(_ duration: TimeInterval) {
        runDurations.append(duration)
    }
}

final class MockDiagnosticFamilyAsserter {
    private let allowedFamilies: Set<String>
    private(set) var assertionCount = 0

    init(allowedFamilies: Set<String>) {
        self.allowedFamilies = allowedFamilies
    }

    func assertFamilies(for diagnostics: [DaisyDiagnostic], file: StaticString = #filePath, line: UInt = #line) {
        assertionCount += 1
        for diagnostic in diagnostics {
            let family = diagnostic.code.split(separator: ".").first.map(String.init) ?? ""
            #expect(allowedFamilies.contains(family))
        }
    }
}

final class FakePeakMemoryTracker {
    private(set) var peakBytes: UInt64 = 0

    func captureCurrentUsage() {
        let current = currentMemoryUsageInBytes()
        peakBytes = max(peakBytes, current)
    }

    private func currentMemoryUsageInBytes() -> UInt64 {
#if canImport(Darwin)
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let result: kern_return_t = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPointer in
                task_info(
                    mach_task_self_,
                    task_flavor_t(TASK_VM_INFO),
                    intPointer,
                    &count
                )
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        return info.phys_footprint
#else
        return 0
#endif
    }
}
