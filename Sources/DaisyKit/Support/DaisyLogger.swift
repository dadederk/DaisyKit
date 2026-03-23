import OSLog

enum DaisyLogger {
    private static let subsystem = "DaisyKit"
    static let resolver = Logger(subsystem: subsystem, category: "Resolver")
    static let opf = Logger(subsystem: subsystem, category: "OPF")
    static let ncx = Logger(subsystem: subsystem, category: "NCX")
    static let dtbook = Logger(subsystem: subsystem, category: "DTBook")
    static let smil = Logger(subsystem: subsystem, category: "SMIL")
    static let normalize = Logger(subsystem: subsystem, category: "Normalize")
    static let diagnostics = Logger(subsystem: subsystem, category: "Diagnostics")
}
