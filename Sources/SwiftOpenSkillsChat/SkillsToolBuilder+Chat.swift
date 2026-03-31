#if chat
import Foundation
import SwiftOpenSkills
import SwiftChatCompletionsDSL

/// A component produced by `SkillsToolBuilder` in the Chat DSL context.
public enum SkillsComponent: Sendable {
    case tool(AgentTool)
    case skills(Skills)
}

/// A result builder that accepts both `AgentTool` and `Skills` values for the Chat DSL,
/// producing a `[SkillsComponent]` array for use with `SkillsAgent`.
@resultBuilder
public struct SkillsToolBuilder {

    public static func buildExpression(_ tool: AgentTool) -> [SkillsComponent] {
        [.tool(tool)]
    }

    public static func buildExpression(_ skills: Skills) -> [SkillsComponent] {
        [.skills(skills)]
    }

    public static func buildBlock(_ components: [SkillsComponent]...) -> [SkillsComponent] {
        components.flatMap { $0 }
    }

    public static func buildEither(first: [SkillsComponent]) -> [SkillsComponent] {
        first
    }

    public static func buildEither(second: [SkillsComponent]) -> [SkillsComponent] {
        second
    }

    public static func buildOptional(_ component: [SkillsComponent]?) -> [SkillsComponent] {
        component ?? []
    }

    public static func buildArray(_ components: [[SkillsComponent]]) -> [SkillsComponent] {
        components.flatMap { $0 }
    }
}
#endif
