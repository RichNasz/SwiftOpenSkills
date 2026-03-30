import Foundation
import SwiftOpenSkills
import SwiftChatCompletionsDSL
import SwiftLLMToolMacros

extension SkillStore {

    /// Creates an `AgentTool` for the `activate_skill` function, compatible with
    /// `SwiftChatCompletionsDSL`.
    ///
    /// `Tool` in SwiftChatCompletionsDSL is a typealias for `ToolDefinition`, so the
    /// activate_skill tool definition passes directly into the Chat DSL's `AgentTool` init.
    ///
    /// - Returns: An `AgentTool` ready to pass to `Agent` or `SkillsAgent`.
    public func chatAgentTool() -> AgentTool {
        let toolDef = ToolDefinition(
            name: SkillStore.activateSkillToolName,
            description: SkillStore.activateSkillToolDescription,
            parameters: .object(
                properties: [
                    ("name", .string(
                        description: "The slug identifier of the skill to activate " +
                            "(e.g. \"git-commit\"). Use the slug shown in the skill catalog."
                    ))
                ],
                required: ["name"]
            )
        )
        return AgentTool(
            tool: toolDef,
            handler: { [self] argumentsJSON in
                try await self.activateSkillHandler(argumentsJSON: argumentsJSON)
            }
        )
    }
}
