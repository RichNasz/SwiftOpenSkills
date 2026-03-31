#if responses
import Foundation
import SwiftOpenSkills
import SwiftOpenResponsesDSL
import SwiftLLMToolMacros

extension SkillStore {

    /// Creates an `AgentTool` for the `activate_skill` function, compatible with
    /// `SwiftOpenResponsesDSL`.
    ///
    /// The tool definition is built from `SkillStore.activateSkillToolName` and
    /// `SkillStore.activateSkillToolDescription`. The handler delegates to
    /// `activateSkillHandler(argumentsJSON:)` on this store.
    ///
    /// - Parameter strict: Whether to enable strict mode on the function tool parameter.
    /// - Returns: An `AgentTool` ready to pass to `Agent` or `SkillsAgent`.
    public func responsesAgentTool(strict: Bool? = nil) -> AgentTool {
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
            tool: FunctionToolParam(from: toolDef, strict: strict),
            handler: { [self] argumentsJSON in
                try await self.activateSkillHandler(argumentsJSON: argumentsJSON)
            }
        )
    }

    /// Creates an `AgentTool` for the `list_skills` function, compatible with
    /// `SwiftOpenResponsesDSL`.
    ///
    /// The handler returns the current skill catalog as a pretty-printed JSON array.
    /// Accepts an optional `{"style":"detailed"}` argument to include `whenToUse` and
    /// `allowedTools` in each entry.
    ///
    /// - Parameter strict: Whether to enable strict mode on the function tool parameter.
    /// - Returns: An `AgentTool` ready to pass to `Agent` or `SkillsAgent`.
    public func listSkillsAgentTool(strict: Bool? = nil) -> AgentTool {
        let toolDef = ToolDefinition(
            name: SkillStore.listSkillsToolName,
            description: SkillStore.listSkillsToolDescription,
            parameters: .object(
                properties: [
                    ("style", .string(
                        description: "Optional. \"compact\" (default) or \"detailed\"."
                    ))
                ],
                required: []
            )
        )
        return AgentTool(
            tool: FunctionToolParam(from: toolDef, strict: strict),
            handler: { [self] argumentsJSON in
                try await self.listSkillsHandler(argumentsJSON: argumentsJSON)
            }
        )
    }
}
#endif
