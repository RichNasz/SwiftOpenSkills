import Foundation
import Yams

/// Parses SKILL.md files into `Skill` values.
/// Internal — callers use `SkillDiscovery` or `SkillStore`.
enum SkillParser {

    /// Parses a SKILL.md file at `fileURL` using `slug` as the skill's stable identifier.
    static func parse(fileURL: URL, slug: String) throws -> Skill {
        let content: String
        do {
            content = try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            throw SkillError.fileReadFailed(path: fileURL.path, reason: error.localizedDescription)
        }

        // Normalize Windows line endings before processing.
        let normalized = content.replacingOccurrences(of: "\r\n", with: "\n")
        let (yamlString, body) = try extractSections(from: normalized, path: fileURL.path)
        let frontmatter = try parseFrontmatter(yaml: yamlString, path: fileURL.path, slug: slug)

        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SkillError.emptyInstructions(path: fileURL.path)
        }

        return Skill(
            id: slug,
            name: frontmatter.name,
            description: frontmatter.description,
            version: frontmatter.version,
            author: frontmatter.author,
            tags: frontmatter.tags,
            instructions: body,
            directoryURL: fileURL.deletingLastPathComponent(),
            whenToUse: frontmatter.whenToUse,
            argumentHint: frontmatter.argumentHint,
            aliases: frontmatter.aliases,
            allowedTools: frontmatter.allowedTools,
            license: frontmatter.license,
            compatibility: frontmatter.compatibility,
            metadata: frontmatter.metadata
        )
    }

    /// Splits normalized file content into YAML frontmatter and instruction body.
    ///
    /// Expects the file to start with a line containing only `---`.
    /// The first subsequent line containing only `---` ends the frontmatter.
    /// Everything after that line (with leading newlines stripped) is the body.
    static func extractSections(from content: String, path: String) throws -> (yaml: String, body: String) {
        let lines = content.components(separatedBy: "\n")

        guard !lines.isEmpty, lines[0].trimmingCharacters(in: .whitespaces) == "---" else {
            throw SkillError.missingFrontmatter(path: path)
        }

        // Find the closing --- delimiter (search from line 1 onwards)
        var closingIndex: Int? = nil
        for i in 1..<lines.count {
            if lines[i].trimmingCharacters(in: .whitespaces) == "---" {
                closingIndex = i
                break
            }
        }

        guard let closing = closingIndex else {
            throw SkillError.missingFrontmatter(path: path)
        }

        let yamlLines = Array(lines[1..<closing])
        let yamlString = yamlLines.joined(separator: "\n")

        let bodyStartIndex = closing + 1
        let bodyLines = bodyStartIndex < lines.count ? Array(lines[bodyStartIndex...]) : []
        let rawBody = bodyLines.joined(separator: "\n")
        // Strip leading newlines only — preserve internal structure.
        let body = String(rawBody.drop(while: { $0 == "\n" }))

        return (yamlString, body)
    }

    /// Parses a YAML string into a `SkillFrontmatter`, validating required keys.
    static func parseFrontmatter(yaml: String, path: String, slug: String) throws -> SkillFrontmatter {
        let parsed: Any?
        do {
            parsed = try Yams.load(yaml: yaml)
        } catch {
            throw SkillError.invalidYAML(path: path, reason: error.localizedDescription)
        }

        guard let dict = parsed as? [String: Any] else {
            throw SkillError.invalidYAML(path: path, reason: "Expected a YAML mapping at the top level")
        }

        guard let name = dict["name"] as? String, !name.isEmpty else {
            throw SkillError.missingRequiredKey(path: path, key: "name")
        }
        guard let description = dict["description"] as? String, !description.isEmpty else {
            throw SkillError.missingRequiredKey(path: path, key: "description")
        }

        // Validate name against spec slug-format constraints.
        try validateName(name, path: path, slug: slug)

        let version = dict["version"] as? String
        let author = dict["author"] as? String
        let tags = (dict["tags"] as? [String]) ?? []
        let whenToUse = dict["whenToUse"] as? String
        let argumentHint = dict["argumentHint"] as? String
        let aliases = (dict["aliases"] as? [String]) ?? []
        let allowedTools = (dict["allowed-tools"] as? String)
            .map { $0.split(separator: " ").map(String.init) } ?? []
        let license = dict["license"] as? String
        let compatibility = dict["compatibility"] as? String
        let metadata: [String: String] = {
            guard let raw = dict["metadata"] as? [String: Any] else { return [:] }
            return raw.reduce(into: [:]) { result, pair in result[pair.key] = "\(pair.value)" }
        }()

        return SkillFrontmatter(
            name: name,
            description: description,
            version: version,
            author: author,
            tags: tags,
            whenToUse: whenToUse,
            argumentHint: argumentHint,
            aliases: aliases,
            allowedTools: allowedTools,
            license: license,
            compatibility: compatibility,
            metadata: metadata
        )
    }

    /// Validates `name` against the Agent Skills spec slug-format rules.
    ///
    /// Rules: 1–64 chars, lowercase alphanumeric and hyphens only,
    /// no leading/trailing/consecutive hyphens, must equal the directory slug.
    private static func validateName(_ name: String, path: String, slug: String) throws {
        let validScalars = CharacterSet.lowercaseLetters
            .union(.decimalDigits)
            .union(CharacterSet(charactersIn: "-"))

        let isValidFormat = !name.isEmpty
            && name.count <= 64
            && name.unicodeScalars.allSatisfy({ validScalars.contains($0) })
            && !name.hasPrefix("-")
            && !name.hasSuffix("-")
            && !name.contains("--")

        guard isValidFormat else {
            throw SkillError.invalidName(
                path: path,
                reason: "name must be 1–64 lowercase alphanumeric characters or hyphens, " +
                        "with no leading, trailing, or consecutive hyphens"
            )
        }

        guard name == slug else {
            throw SkillError.invalidName(
                path: path,
                reason: "name \"\(name)\" must match the directory name \"\(slug)\""
            )
        }
    }
}
