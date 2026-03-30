import Foundation
import SwiftOpenSkills
import SwiftOpenResponsesDSL

/// A component produced by `SkillsToolBuilder`.
/// Either a plain `AgentTool` or a `Skills` instance that resolves asynchronously.
public enum SkillsComponent: Sendable {
    case tool(AgentTool)
    case skills(Skills)
}

/// A result builder that accepts both `AgentTool` and `Skills` values,
/// producing a `[SkillsComponent]` array for use with `SkillsAgent`.
///
/// `Skills` instances are resolved asynchronously at `SkillsAgent` init time,
/// after which the agent behaves identically to a standard `Agent`.
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
