// Generated from Examples/RunAgentChat/specs/SPEC.md + Overview.md
// Do not edit manually — update the spec and regenerate

import Foundation
import SwiftChatCompletionsDSL
import SwiftOpenSkills
import SwiftOpenSkillsChat

public struct RunAgentChat: Sendable {
    public let serverURL: URL
    public let model: String
    public let apiKey: String?
    public let skillsDirectory: URL?

    public init(serverURL: URL, model: String, apiKey: String? = nil, skillsDirectory: URL? = nil) {
        self.serverURL = serverURL
        self.model = model
        self.apiKey = apiKey
        self.skillsDirectory = skillsDirectory
    }

    public func run(prompt: String) async throws -> String {
        let store = SkillStore()
        if let dir = skillsDirectory {
            try await store.load(.directory(dir))
        } else {
            try await store.load()
        }

        let client = try LLMClient(baseURL: serverURL.absoluteString, apiKey: apiKey ?? "")
        let agent = try await Agent.withSkills(store, client: client, model: model)
        return try await agent.send(prompt)
    }
}
