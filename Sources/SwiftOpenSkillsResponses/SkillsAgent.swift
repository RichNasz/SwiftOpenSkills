import Foundation
import SwiftOpenSkills
import SwiftOpenResponsesDSL

/// A Responses API agent with declarative skill and tool registration.
///
/// `SkillsAgent` wraps a `SwiftOpenResponsesDSL.Agent` and resolves `Skills` instances
/// asynchronously at init time. After initialization it forwards `send`, `stream`,
/// `transcript`, and `reset` to the underlying agent.
///
/// ## Usage
/// ```swift
/// let store = SkillStore()
/// try await store.load()
///
/// let agent = try await SkillsAgent(client: client, model: "gpt-4o") {
///     Skills(store: store)                          // registers activate_skill + catalog
///     AgentTool(tool: myFileTool) { args in ... }   // additional tools
/// }
///
/// let response = try await agent.send("Review my code using best practices.")
/// ```
public actor SkillsAgent {

    private let agent: Agent

    // MARK: - Init

    /// Creates a `SkillsAgent` by resolving all `Skills` instances asynchronously,
    /// then constructing the underlying `Agent`.
    ///
    /// - Parameters:
    ///   - client: The LLM client.
    ///   - model: The model identifier string.
    ///   - baseInstructions: Optional instructions prepended before any catalog sections.
    ///   - maxToolIterations: Maximum tool-calling loop iterations (default: 10).
    ///   - tools: A `@SkillsToolBuilder` closure composing `Skills` and `AgentTool` values.
    public init(
        client: LLMClient,
        model: String,
        baseInstructions: String? = nil,
        maxToolIterations: Int = 10,
        @SkillsToolBuilder tools components: () -> [SkillsComponent]
    ) async throws {
        var agentTools: [AgentTool] = []
        var catalogSections: [String] = []

        for component in components() {
            switch component {
            case .tool(let tool):
                agentTools.append(tool)
            case .skills(let skills):
                let agentTool = await skills.asAgentTool()
                agentTools.append(agentTool)
                let section = await skills.systemPromptSection()
                catalogSections.append(section)
            }
        }

        var instructionParts: [String] = []
        if let base = baseInstructions, !base.isEmpty {
            instructionParts.append(base)
        }
        instructionParts.append(contentsOf: catalogSections)
        let instructions = instructionParts.isEmpty ? nil : instructionParts.joined(separator: "\n\n")

        let toolDefs = agentTools.map(\.tool)
        let handlers = Dictionary(uniqueKeysWithValues: agentTools.map { ($0.tool.name, $0.handler) })
        self.agent = Agent(
            client: client,
            model: model,
            instructions: instructions,
            tools: toolDefs,
            toolHandlers: handlers,
            maxToolIterations: maxToolIterations
        )
    }

    // MARK: - Forwarded API

    /// Sends a message and runs the tool-calling loop until the model produces a final response.
    public func send(_ message: String) async throws -> String {
        try await agent.send(message)
    }

    /// Streams a message through the tool-calling loop, yielding events as they arrive.
    public func stream(_ message: String) async -> AsyncThrowingStream<ToolSessionEvent, Error> {
        await agent.stream(message)
    }

    /// The conversation transcript recorded by the underlying agent.
    public var transcript: [TranscriptEntry] {
        get async { await agent.transcript }
    }

    /// Resets the underlying agent's conversation state.
    public func reset() async {
        await agent.reset()
    }
}
