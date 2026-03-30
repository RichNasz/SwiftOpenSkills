import Foundation

/// A parsed Agent Skill, ready for use in LLM conversations.
///
/// The `id` is the filesystem slug (the lowercased directory name, e.g. `"git-commit"`).
/// This is the stable identifier used as the `name` argument when calling `activate_skill`.
public struct Skill: Sendable, Equatable, Identifiable {
    /// The filesystem slug: the lowercased directory name (stable identifier).
    /// Used as the argument to `activate_skill`.
    public let id: String

    /// Human-readable name from YAML frontmatter.
    public let name: String

    /// Short description from YAML frontmatter, shown in the skill catalog.
    public let description: String

    /// Optional semantic version string.
    public let version: String?

    /// Optional author identifier.
    public let author: String?

    /// Optional categorization tags.
    public let tags: [String]

    /// The full Markdown instruction body (everything after the closing `---`).
    public let instructions: String

    /// Absolute path to the directory containing this skill's SKILL.md.
    public let directoryURL: URL

    /// Absolute URL of the SKILL.md file itself.
    public var skillFileURL: URL {
        directoryURL.appending(path: "SKILL.md", directoryHint: .notDirectory)
    }

    /// Returns URLs of files in a `resources/` subdirectory, sorted by filename.
    /// Returns an empty array if the subdirectory does not exist.
    public func resourceURLs() throws -> [URL] {
        let resourcesDir = directoryURL.appending(path: "resources", directoryHint: .isDirectory)
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: resourcesDir.path, isDirectory: &isDir),
              isDir.boolValue else {
            return []
        }
        let contents = try FileManager.default.contentsOfDirectory(
            at: resourcesDir,
            includingPropertiesForKeys: nil
        )
        return contents.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}
