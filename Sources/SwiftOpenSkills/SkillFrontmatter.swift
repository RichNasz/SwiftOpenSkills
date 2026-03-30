/// Decoded YAML frontmatter from a SKILL.md file.
/// Internal only — callers use `Skill` instead.
struct SkillFrontmatter: Sendable, Equatable {
    let name: String
    let description: String
    let version: String?
    let author: String?
    let tags: [String]
}
