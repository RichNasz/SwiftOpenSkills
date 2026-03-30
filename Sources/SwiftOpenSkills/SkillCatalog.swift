import Foundation

/// A compact representation of a set of skills, suitable for injection into LLM system prompts.
public struct SkillCatalog: Sendable {
    /// The skills included in this catalog.
    public let skills: [Skill]

    public init(skills: [Skill]) {
        self.skills = skills
    }

    /// A compact, newline-delimited listing of all skills.
    ///
    /// Format per line: `- {slug}: {name} — {description}`
    ///
    /// Suitable for embedding directly in a system prompt alongside `systemPromptSection()`.
    public var compactListing: String {
        guard !skills.isEmpty else { return "No skills available." }
        return skills
            .map { "- \($0.id): \($0.name) — \($0.description)" }
            .joined(separator: "\n")
    }

    /// Structured catalog entries, suitable for JSON encoding.
    public var entries: [CatalogEntry] {
        skills.map { CatalogEntry(slug: $0.id, name: $0.name, description: $0.description) }
    }

    /// A Markdown section explaining available skills and how to activate them.
    ///
    /// Embed this in the system prompt so the LLM knows which skills exist
    /// and to call `activate_skill` before using one.
    public func systemPromptSection() -> String {
        guard !skills.isEmpty else {
            return "## Available Skills\n\nNo skills are currently available."
        }
        return """
        ## Available Skills

        You have access to the following agent skills. \
        Call `activate_skill` with a skill slug to load full instructions before using any skill.

        \(compactListing)
        """
    }
}

/// A single entry in the skill catalog.
public struct CatalogEntry: Sendable, Encodable, Equatable {
    public let slug: String
    public let name: String
    public let description: String
}
