import Foundation

/// Thread-safe, async-first store of loaded Agent Skills.
///
/// `SkillStore` is the primary entry point for most integrations.
/// Load skills once at startup; query from any isolation context.
///
/// ## Quick Start
/// ```swift
/// let store = SkillStore()
/// try await store.load()               // standard locations
/// let catalog = await store.catalog()
/// print(catalog.systemPromptSection())
/// ```
///
/// ## Custom Search Hierarchy
/// ```swift
/// try await store.load(.directory(myURL), .standard)  // custom first, then standard
/// try await store.load(.directory(myURL))              // custom only
/// ```
public actor SkillStore {

    // MARK: - Tool metadata

    /// The tool name used for the `activate_skill` function.
    public static let activateSkillToolName = "activate_skill"

    /// The tool description sent to the LLM describing `activate_skill`.
    public static let activateSkillToolDescription =
        "Loads the full instructions for an agent skill by its slug identifier. " +
        "Call this before performing any task that requires a skill. " +
        "The slug is the identifier shown in the skill catalog (e.g. \"git-commit\")."

    /// The tool name used for the `list_skills` function.
    public static let listSkillsToolName = "list_skills"

    /// The tool description sent to the LLM describing `list_skills`.
    public static let listSkillsToolDescription =
        "Returns the current skill catalog as a JSON array. " +
        "Use this to discover available skills at runtime when the catalog is not in the system prompt, " +
        "or to verify whether a specific skill is available before calling activate_skill."

    // MARK: - State

    private var _skills: [String: Skill] = [:]
    private var _aliasMap: [String: String] = [:]  // alias → canonical slug
    private var _isLoaded: Bool = false

    // MARK: - Init

    public init() {}

    // MARK: - Loading

    /// Discovers and loads skills from the platform-standard locations.
    @discardableResult
    public func load() async throws -> DiscoveryResult {
        try await _load(using: SkillDiscovery())
    }

    /// Discovers and loads skills using an explicit, ordered search hierarchy.
    ///
    /// - Parameter paths: Ordered search paths. Earlier paths shadow later ones for duplicate slugs.
    ///
    /// ## Examples
    /// ```swift
    /// try await store.load(.directory(myURL), .standard)  // custom first, then standard
    /// try await store.load(.directory(myURL))              // custom only
    /// try await store.load(.standard, .directory(myURL))  // standard first, then custom
    /// ```
    @discardableResult
    public func load(_ paths: SkillSearchPath...) async throws -> DiscoveryResult {
        try await _load(using: SkillDiscovery(paths))
    }

    /// Discovers and loads skills using an array of search paths.
    @discardableResult
    public func load(_ paths: [SkillSearchPath]) async throws -> DiscoveryResult {
        try await _load(using: SkillDiscovery(paths))
    }

    /// Loads skills from a pre-built `DiscoveryResult` (useful for testing or custom pipelines).
    public func load(from result: DiscoveryResult) {
        _skills = Dictionary(uniqueKeysWithValues: result.skills.map { ($0.id, $0) })
        _aliasMap = Self._buildAliasMap(from: result.skills)
        _isLoaded = true
    }

    /// Directly registers a skill, bypassing filesystem discovery.
    public func register(_ skill: Skill) {
        _skills[skill.id] = skill
        for alias in skill.aliases {
            _aliasMap[alias] = skill.id
        }
        _isLoaded = true
    }

    private func _load(using discovery: SkillDiscovery) async throws -> DiscoveryResult {
        let result = try await discovery.discover()
        _skills = Dictionary(uniqueKeysWithValues: result.skills.map { ($0.id, $0) })
        _aliasMap = Self._buildAliasMap(from: result.skills)
        _isLoaded = true
        return result
    }

    private static func _buildAliasMap(from skills: [Skill]) -> [String: String] {
        var map: [String: String] = [:]
        for skill in skills {
            for alias in skill.aliases {
                map[alias] = skill.id
            }
        }
        return map
    }

    // MARK: - Querying

    /// All currently loaded skills, sorted by slug.
    public var skills: [Skill] {
        _skills.values.sorted { $0.id < $1.id }
    }

    /// Whether the store has been loaded at least once.
    public var isLoaded: Bool { _isLoaded }

    /// Returns the skill with the given slug or alias, or `nil` if not found.
    public func skill(slug: String) -> Skill? {
        _skills[slug] ?? _skills[_aliasMap[slug] ?? ""]
    }

    /// Returns the skill with the given slug or alias.
    /// - Throws: `SkillError.skillNotFound` if no skill with that slug is loaded.
    public func requireSkill(slug: String) throws -> Skill {
        guard let skill = skill(slug: slug) else {
            throw SkillError.skillNotFound(slug: slug)
        }
        return skill
    }

    /// Resolves an alias to its canonical slug, or `nil` if the alias is not registered.
    public func canonicalSlug(for alias: String) -> String? {
        _aliasMap[alias]
    }

    // MARK: - Catalog

    /// Returns a catalog of all currently loaded skills.
    public func catalog() -> SkillCatalog {
        SkillCatalog(skills: skills)
    }

    // MARK: - Tool Handlers

    /// Handles an `activate_skill` tool call and returns the skill's full instructions.
    ///
    /// This is the raw handler for the `activate_skill` tool. Both DSL integration
    /// targets wrap this method in their respective `AgentTool` handlers.
    ///
    /// Variable substitution is applied to the instruction body before returning:
    /// - `${SKILL_DIR}` → absolute path to the skill's directory
    /// - `${SKILL_SLUG}` → the skill's canonical slug
    /// Unknown `${...}` patterns are left as-is.
    ///
    /// - Parameter argumentsJSON: JSON string with `{"name": "<slug>"}`.
    /// - Returns: Formatted string containing the skill header and full instructions.
    /// - Throws: `SkillError.skillNotFound` if the slug is not loaded, or a JSON decoding error.
    public func activateSkillHandler(argumentsJSON: String) async throws -> String {
        guard let data = argumentsJSON.data(using: .utf8) else {
            throw SkillError.skillNotFound(slug: "<invalid-json>")
        }
        let args = try JSONDecoder().decode(ActivateSkillArguments.self, from: data)
        let skill = try requireSkill(slug: args.name)

        let resolvedInstructions = Self.substituteVariables(in: skill.instructions, skill: skill)
        var output = "[Skill Activated: \(skill.id)]\n\n# \(skill.name)\n\n\(resolvedInstructions)"

        let resourceURLs = (try? skill.resourceURLs()) ?? []
        if !resourceURLs.isEmpty {
            let names = resourceURLs.map(\.lastPathComponent).joined(separator: ", ")
            output += "\n\n---\nResources: \(names)"
        }

        return output
    }

    /// Handles a `list_skills` tool call and returns the catalog as a JSON array.
    ///
    /// Accepts `{}` or `{"style":"detailed"}`. Returns a JSON-encoded array of
    /// `CatalogEntry` values representing all currently loaded skills.
    ///
    /// - Parameter argumentsJSON: JSON string, e.g. `{}` or `{"style":"detailed"}`.
    /// - Returns: Pretty-printed JSON array string.
    public func listSkillsHandler(argumentsJSON: String) async throws -> String {
        // argumentsJSON is accepted for forward-compatibility (e.g. style parameter); all
        // CatalogEntry fields are always included in the JSON output regardless.
        let cat = catalog()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(cat.entries)
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    // MARK: - Private Helpers

    private static func substituteVariables(in text: String, skill: Skill) -> String {
        text
            .replacingOccurrences(of: "${SKILL_DIR}", with: skill.directoryURL.path)
            .replacingOccurrences(of: "${SKILL_SLUG}", with: skill.id)
    }
}

// MARK: - Private argument types

private struct ActivateSkillArguments: Decodable, Sendable {
    let name: String
}
