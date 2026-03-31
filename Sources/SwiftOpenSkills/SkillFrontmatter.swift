/// Decoded YAML frontmatter from a SKILL.md file.
/// Internal only — callers use `Skill` instead.
struct SkillFrontmatter: Sendable, Equatable {
    let name: String
    let description: String
    let version: String?
    let author: String?
    let tags: [String]
    let whenToUse: String?
    let argumentHint: String?
    let aliases: [String]
    let allowedTools: [String]
    let license: String?
    let compatibility: String?
    let metadata: [String: String]
}
