#if responses
import Foundation
import SwiftOpenSkills
import SwiftOpenResponsesDSL

extension Agent {

    /// Creates a Responses API `Agent` with the `activate_skill` tool pre-registered,
    /// plus any additional tools from the builder closure.
    ///
    /// The skill catalog is automatically appended to the system instructions.
    /// If you supply `baseInstructions`, the catalog section is appended after a blank line.
    ///
    /// - Parameters:
    ///   - store: A loaded `SkillStore`.
    ///   - client: The LLM client.
    ///   - model: The model identifier string.
    ///   - strict: Strict mode for the `activate_skill` function tool parameter.
    ///   - baseInstructions: Optional instructions to prepend before the catalog section.
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
        strict: Bool? = nil,
        baseInstructions: String? = nil,
        maxToolIterations: Int = 10,
        @AgentToolBuilder tools: () -> [AgentTool] = { [] }
    ) async throws -> Agent {
        let skillTool = await store.responsesAgentTool(strict: strict)
        let catalogSection = await store.catalog().systemPromptSection()
        let instructions: String = {
            if let base = baseInstructions, !base.isEmpty {
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
            instructions: instructions,
            tools: toolDefs,
            toolHandlers: handlers,
            maxToolIterations: maxToolIterations
        )
    }
}
#endif
