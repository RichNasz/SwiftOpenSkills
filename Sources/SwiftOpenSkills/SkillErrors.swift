/// Errors produced by SwiftOpenSkills during discovery, parsing, or activation.
public enum SkillError: Error, Sendable, Equatable {
    /// The SKILL.md file could not be read from disk.
    case fileReadFailed(path: String, reason: String)
    /// The file does not begin with a valid YAML frontmatter block.
    case missingFrontmatter(path: String)
    /// YAML between the frontmatter delimiters could not be parsed.
    case invalidYAML(path: String, reason: String)
    /// A required frontmatter key is absent or has the wrong type.
    case missingRequiredKey(path: String, key: String)
    /// The instruction body after the closing `---` is empty or whitespace-only.
    case emptyInstructions(path: String)
    /// No skill with the given slug was found in the store.
    case skillNotFound(slug: String)
}
