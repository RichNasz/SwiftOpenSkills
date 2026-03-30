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

    // MARK: - State

    private var _skills: [String: Skill] = [:]
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
        _isLoaded = true
    }

    /// Directly registers a skill, bypassing filesystem discovery.
    public func register(_ skill: Skill) {
        _skills[skill.id] = skill
        _isLoaded = true
    }

    private func _load(using discovery: SkillDiscovery) async throws -> DiscoveryResult {
        let result = try await discovery.discover()
        _skills = Dictionary(uniqueKeysWithValues: result.skills.map { ($0.id, $0) })
        _isLoaded = true
        return result
    }

    // MARK: - Querying

    /// All currently loaded skills, sorted by slug.
    public var skills: [Skill] {
        _skills.values.sorted { $0.id < $1.id }
    }

    /// Whether the store has been loaded at least once.
    public var isLoaded: Bool { _isLoaded }

    /// Returns the skill with the given slug, or `nil` if not found.
    public func skill(slug: String) -> Skill? {
        _skills[slug]
    }

    /// Returns the skill with the given slug.
    /// - Throws: `SkillError.skillNotFound` if no skill with that slug is loaded.
    public func requireSkill(slug: String) throws -> Skill {
        guard let skill = _skills[slug] else {
            throw SkillError.skillNotFound(slug: slug)
        }
        return skill
    }

    // MARK: - Catalog

    /// Returns a catalog of all currently loaded skills.
    public func catalog() -> SkillCatalog {
        SkillCatalog(skills: skills)
    }

    // MARK: - Tool Handler

    /// Handles an `activate_skill` tool call and returns the skill's full instructions.
    ///
    /// This is the raw handler for the `activate_skill` tool. Both DSL integration
    /// targets wrap this method in their respective `AgentTool` handlers.
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

        var output = "[Skill Activated: \(skill.id)]\n\n# \(skill.name)\n\n\(skill.instructions)"

        let resourceURLs = (try? skill.resourceURLs()) ?? []
        if !resourceURLs.isEmpty {
            let names = resourceURLs.map(\.lastPathComponent).joined(separator: ", ")
            output += "\n\n---\nResources: \(names)"
        }

        return output
    }
}

// MARK: - Private

private struct ActivateSkillArguments: Decodable, Sendable {
    let name: String
}
