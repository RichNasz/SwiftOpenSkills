// Generated from Examples/DiscoverSkills/specs/SPEC.md + Overview.md
// Do not edit manually — update the spec and regenerate

import Foundation
import SwiftOpenSkills

public struct DiscoverSkills: Sendable {
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public func run() async throws -> DiscoveryResult {
        let store = SkillStore()
        return try await store.load(.directory(directory))
    }
}
