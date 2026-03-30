// Generated from Examples/ActivateSkill/specs/SPEC.md + Overview.md
// Do not edit manually — update the spec and regenerate

import Foundation
import SwiftOpenSkills

public struct ActivateSkill: Sendable {
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public func run(slug: String) async throws -> String {
        let store = SkillStore()
        try await store.load(.directory(directory))
        let json = "{\"name\":\"\(slug)\"}"
        return try await store.activateSkillHandler(argumentsJSON: json)
    }
}
