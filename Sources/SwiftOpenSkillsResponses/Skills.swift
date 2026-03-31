#if responses
import Foundation
import SwiftOpenSkills
import SwiftOpenResponsesDSL

/// A declarative wrapper around a `SkillStore` for use with `SkillsAgent` and `SkillsToolBuilder`.
///
/// `Skills` holds a reference to a `SkillStore` and resolves its `AgentTool` and system prompt
/// section asynchronously when the surrounding `SkillsAgent` is initialized.
///
/// ## Usage
/// ```swift
/// let store = SkillStore()
/// try await store.load()
///
/// let agent = try await SkillsAgent(client: client, model: "gpt-4o") {
///     Skills(store: store)
///     AgentTool(tool: myFileTool) { args in ... }
/// }
/// ```
public struct Skills: Sendable {

    /// The backing skill store.
    public let store: SkillStore

    public init(store: SkillStore) {
        self.store = store
    }

    /// Resolves the `AgentTool` for `activate_skill` from the store.
    public func asAgentTool(strict: Bool? = nil) async -> AgentTool {
        await store.responsesAgentTool(strict: strict)
    }

    /// Resolves the `AgentTool` for `list_skills` from the store.
    public func asListSkillsTool(strict: Bool? = nil) async -> AgentTool {
        await store.listSkillsAgentTool(strict: strict)
    }

    /// Returns the system prompt section generated from the store's current catalog.
    public func systemPromptSection() async -> String {
        await store.catalog().systemPromptSection()
    }
}
#endif
