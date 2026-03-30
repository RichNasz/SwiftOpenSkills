import Foundation
import SwiftOpenSkills
import SwiftChatCompletionsDSL

/// A declarative wrapper around a `SkillStore` for use with Chat DSL's `SkillsAgent`.
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
    public func asAgentTool() async -> AgentTool {
        await store.chatAgentTool()
    }

    /// Returns the system prompt section generated from the store's current catalog.
    public func systemPromptSection() async -> String {
        await store.catalog().systemPromptSection()
    }
}

// MARK: - Agent Convenience Factory

extension Agent {

    /// Creates a Chat Completions `Agent` with the `activate_skill` tool pre-registered,
    /// plus any additional tools from the builder closure.
    ///
    /// The skill catalog is automatically appended to the system prompt.
    ///
    /// - Parameters:
    ///   - store: A loaded `SkillStore`.
    ///   - client: The LLM client.
    ///   - model: The model identifier string.
    ///   - baseSystemPrompt: Optional system prompt text prepended before the catalog section.
    ///   - maxToolIterations: Maximum tool-calling loop iterations (default: 10).
    ///   - tools: Additional tools beyond `activate_skill`.
    ///
    /// ## Example
    /// ```swift
    /// let agent = try await Agent.withSkills(
    ///     store,
    ///     client: client,
    ///     model: "gpt-4o"
    /// ) {
    ///     AgentTool(tool: myFileTool) { args in ... }
    /// }
    /// ```
    public static func withSkills(
        _ store: SkillStore,
        client: LLMClient,
        model: String,
        baseSystemPrompt: String? = nil,
        maxToolIterations: Int = 10,
        @AgentToolBuilder tools: () -> [AgentTool] = { [] }
    ) async throws -> Agent {
        let skillTool = await store.chatAgentTool()
        let catalogSection = await store.catalog().systemPromptSection()
        let systemPrompt: String = {
            if let base = baseSystemPrompt, !base.isEmpty {
                return base + "\n\n" + catalogSection
            }
            return catalogSection
        }()

        let additionalTools = tools()
        let allTools = [skillTool] + additionalTools
        let toolDefs = allTools.map(\.tool)
        let handlers = Dictionary(uniqueKeysWithValues: allTools.map { ($0.tool.name, $0.handler) })

        return Agent(
            client: client,
            model: model,
            systemPrompt: systemPrompt,
            tools: toolDefs,
            toolHandlers: handlers,
            maxToolIterations: maxToolIterations
        )
    }
}
