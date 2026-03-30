// Generated from Examples/ShowCatalog/specs/SPEC.md + Overview.md
// Do not edit manually — update the spec and regenerate

import Foundation
import SwiftOpenSkills

public struct ShowCatalog: Sendable {
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public func run() async throws -> String {
        let store = SkillStore()
        try await store.load(.directory(directory))
        return await store.catalog().systemPromptSection()
    }
}
