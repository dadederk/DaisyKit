import Foundation

public func parsePublication(
    at url: URL,
    options: DaisyParseOptions = .init()
) async throws -> DaisyParseReport {
    try await DaisyParserPipeline(options: options, zipLimits: .v1Defaults).parse(at: url)
}
