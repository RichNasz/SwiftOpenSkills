import Testing
import Foundation
@testable import SwiftOpenSkills

// MARK: - Fixture helpers

private func fixturesURL() throws -> URL {
    guard let url = Bundle.module.url(forResource: "Fixtures", withExtension: nil) else {
        struct FixtureNotFound: Error {}
        throw FixtureNotFound()
    }
    return url
}

private func skillFileURL(_ name: String) throws -> URL {
    try fixturesURL()
        .appending(path: name, directoryHint: .isDirectory)
        .appending(path: "SKILL.md", directoryHint: .notDirectory)
}

private func makeTestSkill(
    slug: String,
    name: String? = nil,   // defaults to slug so name == id per spec
    description: String = "A test skill.",
    instructions: String = "Test instructions.",
    directoryURL: URL = URL(filePath: "/tmp/test-skill", directoryHint: .isDirectory),
    whenToUse: String? = nil,
    argumentHint: String? = nil,
    aliases: [String] = [],
    allowedTools: [String] = [],
    license: String? = nil,
    compatibility: String? = nil,
    metadata: [String: String] = [:]
) -> Skill {
    Skill(
        id: slug,
        name: name ?? slug,
        description: description,
        version: nil,
        author: nil,
        tags: [],
        instructions: instructions,
        directoryURL: directoryURL,
        whenToUse: whenToUse,
        argumentHint: argumentHint,
        aliases: aliases,
        allowedTools: allowedTools,
        license: license,
        compatibility: compatibility,
        metadata: metadata
    )
}

private func storeWithSkill(
    slug: String,
    instructions: String = "Test instructions."
) async -> SkillStore {
    let store = SkillStore()
    let skill = makeTestSkill(slug: slug, instructions: instructions)
    await store.register(skill)
    return store
}

// MARK: - SkillParser Tests

@Suite("SkillParser")
struct SkillParserTests {

    @Test("Parses valid skill with all fields")
    func parsesValidSkill() throws {
        let url = try skillFileURL("valid-skill")
        let skill = try SkillParser.parse(fileURL: url, slug: "valid-skill")
        #expect(skill.id == "valid-skill")
        #expect(skill.name == "valid-skill")
        #expect(skill.description == "A fully valid skill with all optional fields.")
        #expect(skill.version == "1.0.0")
        #expect(skill.author == "Test Author")
        #expect(skill.tags == ["testing", "valid"])
        #expect(!skill.instructions.isEmpty)
    }

    @Test("Parses minimal skill with only required fields")
    func parsesMinimalSkill() throws {
        let url = try skillFileURL("minimal-skill")
        let skill = try SkillParser.parse(fileURL: url, slug: "minimal-skill")
        #expect(skill.id == "minimal-skill")
        #expect(skill.name == "minimal-skill")
        #expect(skill.version == nil)
        #expect(skill.author == nil)
        #expect(skill.tags.isEmpty)
    }

    @Test("Parses tags array correctly")
    func parsesTaggedSkill() throws {
        let url = try skillFileURL("tagged-skill")
        let skill = try SkillParser.parse(fileURL: url, slug: "tagged-skill")
        #expect(skill.tags == ["swift", "llm", "agent"])
    }

    @Test("name equals id — both are the slug per spec")
    func nameEqualsSlug() throws {
        let url = try skillFileURL("valid-skill")
        let skill = try SkillParser.parse(fileURL: url, slug: "valid-skill")
        #expect(skill.id == "valid-skill")
        #expect(skill.name == skill.id)
    }

    @Test("Instruction body is non-empty and leading newlines are stripped")
    func instructionBodyExtracted() throws {
        let url = try skillFileURL("minimal-skill")
        let skill = try SkillParser.parse(fileURL: url, slug: "minimal-skill")
        #expect(!skill.instructions.hasPrefix("\n"))
        #expect(skill.instructions.contains("only name and description"))
    }

    @Test("CRLF files parse identically to LF files")
    func windowsLineEndingsHandled() throws {
        let crlfContent = "---\r\nname: crlf-skill-test\r\ndescription: A CRLF test.\r\n---\r\nBody text.\r\n"
        let tmpDir = FileManager.default.temporaryDirectory
            .appending(path: "crlf-skill-test", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let tmpFile = tmpDir.appending(path: "SKILL.md", directoryHint: .notDirectory)
        try crlfContent.write(to: tmpFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let skill = try SkillParser.parse(fileURL: tmpFile, slug: "crlf-skill-test")
        #expect(skill.name == "crlf-skill-test")
        #expect(skill.instructions.contains("Body text."))
    }

    @Test("Throws when file has no --- frontmatter delimiters")
    func missingFrontmatterThrows() throws {
        let url = try skillFileURL("missing-frontmatter")
        #expect(throws: SkillError.self) {
            try SkillParser.parse(fileURL: url, slug: "missing-frontmatter")
        }
    }

    @Test("Throws for malformed YAML")
    func invalidYAMLThrows() throws {
        let url = try skillFileURL("invalid-yaml")
        #expect(throws: SkillError.self) {
            try SkillParser.parse(fileURL: url, slug: "invalid-yaml")
        }
    }

    @Test("Throws missingRequiredKey(key: name) when name is absent")
    func missingNameThrows() throws {
        let url = try skillFileURL("missing-name")
        #expect(throws: SkillError.missingRequiredKey(path: url.path, key: "name")) {
            try SkillParser.parse(fileURL: url, slug: "missing-name")
        }
    }

    @Test("Throws emptyInstructions when body is whitespace-only")
    func emptyBodyThrows() throws {
        let url = try skillFileURL("empty-body")
        #expect(throws: SkillError.emptyInstructions(path: url.path)) {
            try SkillParser.parse(fileURL: url, slug: "empty-body")
        }
    }

    @Test("Throws fileReadFailed for a non-existent file")
    func nonExistentFileThrows() {
        let url = URL(filePath: "/tmp/does-not-exist-xyz/SKILL.md")
        #expect(throws: SkillError.self) {
            try SkillParser.parse(fileURL: url, slug: "nonexistent")
        }
    }
}

// MARK: - SkillDiscovery Tests

@Suite("SkillDiscovery")
struct SkillDiscoveryTests {

    @Test("Discovers valid skills from a custom directory")
    func discoversValidSkills() async throws {
        let fixturesDir = try fixturesURL()
        let discovery = SkillDiscovery(.directory(fixturesDir))
        let result = try await discovery.discover()
        let slugs = result.skills.map(\.id)
        #expect(slugs.contains("valid-skill"))
        #expect(slugs.contains("minimal-skill"))
    }

    @Test("Silently skips directory without SKILL.md")
    func skipsDirectoryWithoutSkillMD() async throws {
        let fixturesDir = try fixturesURL()
        let discovery = SkillDiscovery(.directory(fixturesDir))
        let result = try await discovery.discover()
        let slugs = result.skills.map(\.id)
        #expect(!slugs.contains("no-skill-file"))
    }

    @Test("Collects parse failures without throwing")
    func collectsFailures() async throws {
        let fixturesDir = try fixturesURL()
        let discovery = SkillDiscovery(.directory(fixturesDir))
        let result = try await discovery.discover()
        #expect(!result.failures.isEmpty)
    }

    @Test("First-occurrence slug wins across multiple directories")
    func slugDeduplication() async throws {
        let tmp = FileManager.default.temporaryDirectory
        let dir1 = tmp.appending(path: "dedup-dir1-\(UUID().uuidString)", directoryHint: .isDirectory)
        let dir2 = tmp.appending(path: "dedup-dir2-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer {
            try? FileManager.default.removeItem(at: dir1)
            try? FileManager.default.removeItem(at: dir2)
        }
        let slug1 = dir1.appending(path: "shared-skill", directoryHint: .isDirectory)
        let slug2 = dir2.appending(path: "shared-skill", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: slug1, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: slug2, withIntermediateDirectories: true)
        try "---\nname: shared-skill\ndescription: From dir1.\n---\nBody1.".write(
            to: slug1.appending(path: "SKILL.md"), atomically: true, encoding: .utf8)
        try "---\nname: shared-skill\ndescription: From dir2.\n---\nBody2.".write(
            to: slug2.appending(path: "SKILL.md"), atomically: true, encoding: .utf8)

        let discovery = SkillDiscovery(.directory(dir1), .directory(dir2))
        let result = try await discovery.discover()
        let found = result.skills.first { $0.id == "shared-skill" }
        #expect(found?.description == "From dir1.") // dir1 listed first → wins
    }

    @Test("Custom-only init scans no standard paths")
    func customOnlyNoStandardPaths() async throws {
        // Use a non-existent path — should return empty, not scan standard locations
        let discovery = SkillDiscovery(.directory(URL(filePath: "/tmp/nonexistent-skills-\(UUID().uuidString)")))
        let result = try await discovery.discover()
        #expect(result.skills.isEmpty)
    }
}

// MARK: - SkillStore Tests

@Suite("SkillStore")
struct SkillStoreTests {

    @Test("load(from:) populates the store")
    func loadPopulatesStore() async throws {
        let skill = makeTestSkill(slug: "test-skill")
        let store = SkillStore()
        await store.load(from: DiscoveryResult(skills: [skill], failures: []))
        let loaded = await store.skills
        #expect(loaded.count == 1)
        #expect(loaded.first?.id == "test-skill")
    }

    @Test("skill(slug:) returns matching skill")
    func skillBySlug() async {
        let store = await storeWithSkill(slug: "find-me")
        let found = await store.skill(slug: "find-me")
        #expect(found?.id == "find-me")
    }

    @Test("skill(slug:) returns nil for unknown slug")
    func skillBySlugMissing() async {
        let store = SkillStore()
        let found = await store.skill(slug: "does-not-exist")
        #expect(found == nil)
    }

    @Test("requireSkill throws skillNotFound for unknown slug")
    func requireSkillThrows() async throws {
        let store = SkillStore()
        await #expect(throws: SkillError.skillNotFound(slug: "missing")) {
            try await store.requireSkill(slug: "missing")
        }
    }

    @Test("register(_:) makes skill immediately queryable")
    func registerDirectly() async {
        let store = await storeWithSkill(slug: "registered")
        let found = await store.skill(slug: "registered")
        #expect(found != nil)
    }

    @Test("isLoaded is false before loading, true after")
    func isLoadedFlag() async {
        let store = SkillStore()
        let before = await store.isLoaded
        #expect(before == false)
        await store.load(from: DiscoveryResult(skills: [], failures: []))
        let after = await store.isLoaded
        #expect(after == true)
    }

    @Test("Second load(from:) replaces all existing skills")
    func loadReplacesExisting() async {
        let skill1 = makeTestSkill(slug: "skill-one")
        let skill2 = makeTestSkill(slug: "skill-two")
        let store = SkillStore()
        await store.load(from: DiscoveryResult(skills: [skill1], failures: []))
        await store.load(from: DiscoveryResult(skills: [skill2], failures: []))
        let skills = await store.skills
        #expect(skills.count == 1)
        #expect(skills.first?.id == "skill-two")
    }

    @Test("skills property returns skills sorted by slug")
    func skillsSortedBySlug() async {
        let store = SkillStore()
        await store.load(from: DiscoveryResult(
            skills: [makeTestSkill(slug: "zebra"), makeTestSkill(slug: "apple")],
            failures: []
        ))
        let ids = await store.skills.map(\.id)
        #expect(ids == ["apple", "zebra"])
    }
}

// MARK: - ActivateSkillHandler Tests

@Suite("ActivateSkillHandler")
struct ActivateSkillHandlerTests {

    @Test("Returns formatted output with skill activated header")
    func handlerReturnsFormattedOutput() async throws {
        let store = await storeWithSkill(slug: "my-skill", instructions: "Do the thing.")
        let result = try await store.activateSkillHandler(argumentsJSON: #"{"name":"my-skill"}"#)
        #expect(result.contains("[Skill Activated: my-skill]"))
        #expect(result.contains("# my-skill"))
        #expect(result.contains("Do the thing."))
    }

    @Test("Output has no Resources line when skill has no resources directory")
    func handlerNoResourcesLine() async throws {
        let store = await storeWithSkill(slug: "no-res", instructions: "Body.")
        let result = try await store.activateSkillHandler(argumentsJSON: #"{"name":"no-res"}"#)
        #expect(!result.contains("Resources:"))
    }

    @Test("Output includes Resources line when skill has resources directory")
    func handlerListsResources() async throws {
        let fixturesDir = try fixturesURL()
        let store = SkillStore()
        try await store.load(.directory(fixturesDir))
        let result = try await store.activateSkillHandler(argumentsJSON: #"{"name":"with-resources"}"#)
        #expect(result.contains("Resources:"))
    }

    @Test("Throws skillNotFound for unknown slug in JSON")
    func handlerThrowsOnUnknownSlug() async throws {
        let store = SkillStore()
        await #expect(throws: SkillError.skillNotFound(slug: "unknown")) {
            try await store.activateSkillHandler(argumentsJSON: #"{"name":"unknown"}"#)
        }
    }

    @Test("Throws a decoding error for invalid JSON input")
    func handlerInvalidJSON() async throws {
        let store = await storeWithSkill(slug: "x", instructions: "Body.")
        await #expect(throws: (any Error).self) {
            try await store.activateSkillHandler(argumentsJSON: "not-json")
        }
    }
}

// MARK: - SkillCatalog Tests

@Suite("SkillCatalog")
struct SkillCatalogTests {

    @Test("compactListing uses - slug: description format")
    func compactListingFormat() {
        let skill = makeTestSkill(slug: "code-review", description: "Reviews code.")
        let catalog = SkillCatalog(skills: [skill])
        #expect(catalog.compactListing.contains("- code-review: Reviews code."))
    }

    @Test("systemPromptSection contains catalog and activate_skill reference")
    func systemPromptSectionContainsCatalog() {
        let skill = makeTestSkill(slug: "git-commit", description: "Writes commits.")
        let catalog = SkillCatalog(skills: [skill])
        let section = catalog.systemPromptSection()
        #expect(section.contains("## Available Skills"))
        #expect(section.contains("git-commit"))
        #expect(section.contains("activate_skill"))
    }

    @Test("entries array matches loaded skills")
    func catalogEntries() {
        let skill = makeTestSkill(slug: "my-skill", description: "Does stuff.")
        let catalog = SkillCatalog(skills: [skill])
        #expect(catalog.entries.count == 1)
        #expect(catalog.entries[0].slug == "my-skill")
        #expect(catalog.entries[0].name == "my-skill")
        #expect(catalog.entries[0].description == "Does stuff.")
    }

    @Test("Empty catalog returns appropriate empty-state strings")
    func emptyCatalog() {
        let catalog = SkillCatalog(skills: [])
        #expect(catalog.compactListing == "No skills available.")
        #expect(catalog.systemPromptSection().contains("No skills are currently available."))
    }
}

// MARK: - Skill Resource Tests

@Suite("Skill.resourceURLs")
struct SkillResourceTests {

    @Test("Returns sorted URLs for skill with resources/ directory")
    func resourceURLsForSkillWithResources() async throws {
        let fixturesDir = try fixturesURL()
        let store = SkillStore()
        try await store.load(.directory(fixturesDir))
        let skill = try await store.requireSkill(slug: "with-resources")
        let urls = try skill.resourceURLs()
        #expect(!urls.isEmpty)
        // Sorted alphabetically: example.txt before guide.md
        #expect(urls.first?.lastPathComponent == "example.txt")
        #expect(urls.last?.lastPathComponent == "guide.md")
    }

    @Test("Returns empty array (no throw) for skill without resources/ directory")
    func resourceURLsEmptyForSkillWithoutDirectory() throws {
        let skill = makeTestSkill(slug: "no-res")
        let urls = try skill.resourceURLs()
        #expect(urls.isEmpty)
    }

    @Test("skillFileURL is computed correctly from directoryURL")
    func skillFileURLComputed() {
        let dir = URL(filePath: "/tmp/my-skill", directoryHint: .isDirectory)
        let skill = makeTestSkill(slug: "my-skill", directoryURL: dir)
        #expect(skill.skillFileURL.lastPathComponent == "SKILL.md")
        #expect(skill.skillFileURL.path.hasSuffix("/my-skill/SKILL.md"))
    }
}

// MARK: - SkillFrontmatterField Tests

@Suite("SkillFrontmatterFields")
struct SkillFrontmatterFieldTests {

    @Test("Parses whenToUse from frontmatter")
    func parsesWhenToUse() throws {
        let url = try skillFileURL("when-to-use-skill")
        let skill = try SkillParser.parse(fileURL: url, slug: "when-to-use-skill")
        #expect(skill.whenToUse != nil)
        #expect(skill.whenToUse?.contains("extended guidance") == true)
    }

    @Test("Parses argumentHint from frontmatter")
    func parsesArgumentHint() throws {
        let url = try skillFileURL("when-to-use-skill")
        let skill = try SkillParser.parse(fileURL: url, slug: "when-to-use-skill")
        #expect(skill.argumentHint == "Optional topic string, e.g. 'concurrency' or 'testing'")
    }

    @Test("Parses aliases from frontmatter")
    func parsesAliases() throws {
        let url = try skillFileURL("when-to-use-skill")
        let skill = try SkillParser.parse(fileURL: url, slug: "when-to-use-skill")
        #expect(skill.aliases == ["wtu", "usage-skill"])
    }

    @Test("Parses allowedTools from frontmatter")
    func parsesAllowedTools() throws {
        let url = try skillFileURL("when-to-use-skill")
        let skill = try SkillParser.parse(fileURL: url, slug: "when-to-use-skill")
        #expect(skill.allowedTools == ["Bash", "Read"])
    }

    @Test("Minimal skill defaults to nil whenToUse")
    func nilWhenToUseForMinimalSkill() throws {
        let url = try skillFileURL("minimal-skill")
        let skill = try SkillParser.parse(fileURL: url, slug: "minimal-skill")
        #expect(skill.whenToUse == nil)
        #expect(skill.argumentHint == nil)
    }

    @Test("Minimal skill defaults to empty aliases and allowedTools")
    func defaultsToEmptySlices() throws {
        let url = try skillFileURL("minimal-skill")
        let skill = try SkillParser.parse(fileURL: url, slug: "minimal-skill")
        #expect(skill.aliases.isEmpty)
        #expect(skill.allowedTools.isEmpty)
    }

    @Test("Parses license from frontmatter")
    func parsesLicense() throws {
        let url = try skillFileURL("when-to-use-skill")
        let skill = try SkillParser.parse(fileURL: url, slug: "when-to-use-skill")
        #expect(skill.license == "MIT")
    }

    @Test("Parses compatibility from frontmatter")
    func parsesCompatibility() throws {
        let url = try skillFileURL("when-to-use-skill")
        let skill = try SkillParser.parse(fileURL: url, slug: "when-to-use-skill")
        #expect(skill.compatibility == "Requires macOS 13 or later")
    }

    @Test("Parses metadata key-value pairs from frontmatter")
    func parsesMetadata() throws {
        let url = try skillFileURL("when-to-use-skill")
        let skill = try SkillParser.parse(fileURL: url, slug: "when-to-use-skill")
        #expect(skill.metadata["author"] == "test-org")
        #expect(skill.metadata["custom-key"] == "custom-value")
    }

    @Test("Skill without metadata has empty metadata map")
    func defaultsToEmptyMetadata() throws {
        let url = try skillFileURL("minimal-skill")
        let skill = try SkillParser.parse(fileURL: url, slug: "minimal-skill")
        #expect(skill.metadata.isEmpty)
    }
}

// MARK: - SkillAlias Tests

@Suite("SkillAliases")
struct SkillAliasTests {

    @Test("Alias resolves to canonical skill via skill(slug:)")
    func aliasResolvesToCanonicalSkill() async {
        let store = SkillStore()
        let skill = makeTestSkill(slug: "my-skill", aliases: ["shortcut", "ms"])
        await store.register(skill)
        let found = await store.skill(slug: "shortcut")
        #expect(found?.id == "my-skill")
    }

    @Test("requireSkill succeeds with alias")
    func requireSkillByAlias() async throws {
        let store = SkillStore()
        let skill = makeTestSkill(slug: "my-skill", aliases: ["ms"])
        await store.register(skill)
        let found = try await store.requireSkill(slug: "ms")
        #expect(found.id == "my-skill")
    }

    @Test("skills array contains only the canonical slug entry")
    func skillsArrayHasNoAliasDuplicates() async {
        let store = SkillStore()
        let skill = makeTestSkill(slug: "my-skill", aliases: ["alias-a", "alias-b"])
        await store.register(skill)
        let all = await store.skills
        #expect(all.count == 1)
        #expect(all.first?.id == "my-skill")
    }

    @Test("canonicalSlug(for:) returns the canonical id")
    func canonicalSlugResolvesAlias() async {
        let store = SkillStore()
        let skill = makeTestSkill(slug: "canonical", aliases: ["alias-x"])
        await store.register(skill)
        let resolved = await store.canonicalSlug(for: "alias-x")
        #expect(resolved == "canonical")
    }

    @Test("canonicalSlug(for:) returns nil for unknown alias")
    func canonicalSlugReturnsNilForUnknown() async {
        let store = SkillStore()
        let resolved = await store.canonicalSlug(for: "nonexistent")
        #expect(resolved == nil)
    }

    @Test("Discovery reserves alias names to prevent lower-priority paths stealing them")
    func discoveryReservesAliases() async throws {
        let tmp = FileManager.default.temporaryDirectory
        let dir1 = tmp.appending(path: "alias-dir1-\(UUID().uuidString)", directoryHint: .isDirectory)
        let dir2 = tmp.appending(path: "alias-dir2-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer {
            try? FileManager.default.removeItem(at: dir1)
            try? FileManager.default.removeItem(at: dir2)
        }

        // dir1 has "primary-skill" with alias "shortcut"
        let primaryDir = dir1.appending(path: "primary-skill", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: primaryDir, withIntermediateDirectories: true)
        try """
        ---
        name: primary-skill
        description: From dir1.
        aliases: [shortcut]
        ---
        Body1.
        """.write(to: primaryDir.appending(path: "SKILL.md"), atomically: true, encoding: .utf8)

        // dir2 has a skill actually named "shortcut"
        let shortcutDir = dir2.appending(path: "shortcut", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: shortcutDir, withIntermediateDirectories: true)
        try """
        ---
        name: shortcut
        description: From dir2.
        ---
        Body2.
        """.write(to: shortcutDir.appending(path: "SKILL.md"), atomically: true, encoding: .utf8)

        let discovery = SkillDiscovery(.directory(dir1), .directory(dir2))
        let result = try await discovery.discover()

        // "shortcut" from dir2 should be shadowed because dir1's alias reserved the name
        let slugs = result.skills.map(\.id)
        #expect(slugs.contains("primary-skill"))
        #expect(!slugs.contains("shortcut"))
    }
}

// MARK: - Enhanced Catalog Tests

@Suite("SkillCatalogEnhanced")
struct SkillCatalogEnhancedTests {

    @Test("Detailed section includes whenToUse when present")
    func detailedSectionIncludesWhenToUse() {
        let skill = makeTestSkill(
            slug: "my-skill",
            whenToUse: "Use when refactoring legacy code."
        )
        let catalog = SkillCatalog(skills: [skill])
        let section = catalog.systemPromptSection(style: .detailed)
        #expect(section.contains("When to use: Use when refactoring legacy code."))
    }

    @Test("Detailed section omits whenToUse line when nil")
    func detailedSectionOmitsWhenToUseWhenNil() {
        let skill = makeTestSkill(slug: "bare-skill")
        let catalog = SkillCatalog(skills: [skill])
        let section = catalog.systemPromptSection(style: .detailed)
        #expect(!section.contains("When to use:"))
    }

    @Test("Compact section never includes whenToUse even when field is populated")
    func compactSectionNeverIncludesWhenToUse() {
        let skill = makeTestSkill(slug: "my-skill", whenToUse: "Some when-to-use text.")
        let catalog = SkillCatalog(skills: [skill])
        let section = catalog.systemPromptSection(style: .compact)
        #expect(!section.contains("When to use:"))
    }

    @Test("Detailed section includes argumentHint when present")
    func detailedSectionIncludesArgumentHint() {
        let skill = makeTestSkill(slug: "my-skill", argumentHint: "Pass a topic string.")
        let catalog = SkillCatalog(skills: [skill])
        let section = catalog.systemPromptSection(style: .detailed)
        #expect(section.contains("Arguments: Pass a topic string."))
    }

    @Test("Detailed section includes allowedTools when non-empty")
    func detailedSectionIncludesAllowedTools() {
        let skill = makeTestSkill(slug: "my-skill", allowedTools: ["bash", "read"])
        let catalog = SkillCatalog(skills: [skill])
        let section = catalog.systemPromptSection(style: .detailed)
        #expect(section.contains("Tools needed: bash, read"))
    }

    @Test("Existing no-arg systemPromptSection() output is unchanged (backward-compat)")
    func existingNoArgSystemPromptSectionUnchanged() {
        let skill = makeTestSkill(slug: "git-commit", description: "Writes commits.")
        let catalog = SkillCatalog(skills: [skill])
        let noArg = catalog.systemPromptSection()
        let compact = catalog.systemPromptSection(style: .compact)
        #expect(noArg == compact)
    }

    @Test("entries array includes new fields")
    func catalogEntriesIncludeNewFields() {
        let skill = makeTestSkill(
            slug: "my-skill",
            whenToUse: "Use for X.",
            aliases: ["ms"],
            allowedTools: ["bash"]
        )
        let catalog = SkillCatalog(skills: [skill])
        let entry = catalog.entries[0]
        #expect(entry.whenToUse == "Use for X.")
        #expect(entry.aliases == ["ms"])
        #expect(entry.allowedTools == ["bash"])
    }
}

// MARK: - Token Estimation Tests

@Suite("SkillCatalogTokenEstimation")
struct SkillCatalogTokenEstimationTests {

    @Test("estimatedTokenCount returns positive value for non-empty catalog")
    func estimatedTokenCountIsPositive() {
        let skill = makeTestSkill(slug: "s", description: "A test skill.")
        let catalog = SkillCatalog(skills: [skill])
        #expect(catalog.estimatedTokenCount() > 0)
    }

    @Test("Detailed style has higher token count than compact when whenToUse is set")
    func detailedHasHigherCount() {
        let skill = makeTestSkill(
            slug: "s",
            whenToUse: "Use this skill in many detailed situations requiring extensive description."
        )
        let catalog = SkillCatalog(skills: [skill])
        #expect(catalog.estimatedTokenCount(style: .detailed) > catalog.estimatedTokenCount(style: .compact))
    }

    @Test("Empty catalog returns small positive token count")
    func emptySkillCatalogTokenCount() {
        let catalog = SkillCatalog(skills: [])
        #expect(catalog.estimatedTokenCount() > 0)
    }

    @Test("Per-skill estimatedFrontmatterTokenCount returns positive value")
    func perSkillTokenCountIsPositive() {
        let skill = makeTestSkill(slug: "s", name: "A Skill", description: "Does something.")
        let catalog = SkillCatalog(skills: [skill])
        #expect(catalog.estimatedFrontmatterTokenCount(for: skill) > 0)
    }
}

// MARK: - Variable Substitution Tests

@Suite("SkillVariableSubstitution")
struct SkillVariableSubstitutionTests {

    @Test("${SKILL_DIR} is replaced with the actual filesystem path")
    func skillDirVariableIsSubstituted() async throws {
        let fixturesDir = try fixturesURL()
        let store = SkillStore()
        try await store.load(.directory(fixturesDir))
        let result = try await store.activateSkillHandler(argumentsJSON: #"{"name":"var-skill"}"#)
        let skill = try await store.requireSkill(slug: "var-skill")
        #expect(result.contains(skill.directoryURL.path))
        #expect(!result.contains("${SKILL_DIR}"))
    }

    @Test("${SKILL_SLUG} is replaced with the skill's id")
    func skillSlugVariableIsSubstituted() async throws {
        let fixturesDir = try fixturesURL()
        let store = SkillStore()
        try await store.load(.directory(fixturesDir))
        let result = try await store.activateSkillHandler(argumentsJSON: #"{"name":"var-skill"}"#)
        #expect(result.contains("var-skill"))
        #expect(!result.contains("${SKILL_SLUG}"))
    }

    @Test("Unknown ${UNKNOWN_VAR} is left as literal text")
    func unknownVariableIsLeftAsIs() async throws {
        let fixturesDir = try fixturesURL()
        let store = SkillStore()
        try await store.load(.directory(fixturesDir))
        let result = try await store.activateSkillHandler(argumentsJSON: #"{"name":"var-skill"}"#)
        #expect(result.contains("${UNKNOWN_VAR}"))
    }

    @Test("Skill with no variables produces output identical to instructions")
    func skillWithNoVariablesIsUnchanged() async throws {
        let store = await storeWithSkill(slug: "plain", instructions: "No variables here.")
        let result = try await store.activateSkillHandler(argumentsJSON: #"{"name":"plain"}"#)
        #expect(result.contains("No variables here."))
    }
}

// MARK: - ListSkillsHandler Tests

@Suite("ListSkillsHandler")
struct ListSkillsHandlerTests {

    @Test("Returns valid JSON array with registered skills")
    func handlerReturnsJSONArray() async throws {
        let store = SkillStore()
        await store.load(from: DiscoveryResult(
            skills: [makeTestSkill(slug: "a"), makeTestSkill(slug: "b")],
            failures: []
        ))
        let result = try await store.listSkillsHandler(argumentsJSON: "{}")
        let data = Data(result.utf8)
        let decoded = try JSONDecoder().decode([CatalogEntry].self, from: data)
        #expect(decoded.count == 2)
    }

    @Test("Empty store returns a valid empty JSON array")
    func handlerReturnsEmptyArrayWhenNoSkills() async throws {
        let store = SkillStore()
        let result = try await store.listSkillsHandler(argumentsJSON: "{}")
        let data = Data(result.utf8)
        let decoded = try JSONDecoder().decode([CatalogEntry].self, from: data)
        #expect(decoded.isEmpty)
    }

    @Test("JSON contains expected slug and description")
    func handlerIncludesSlugAndDescription() async throws {
        let store = await storeWithSkill(slug: "my-skill")
        let result = try await store.listSkillsHandler(argumentsJSON: "{}")
        #expect(result.contains("my-skill"))
        #expect(result.contains("A test skill."))
    }

    @Test("Accepts empty JSON object without error")
    func handlerAcceptsEmptyArgumentsJSON() async throws {
        let store = SkillStore()
        _ = try await store.listSkillsHandler(argumentsJSON: "{}")
    }

    @Test("Accepts style:detailed argument without error")
    func handlerAcceptsStyleArgument() async throws {
        let store = await storeWithSkill(slug: "s")
        _ = try await store.listSkillsHandler(argumentsJSON: #"{"style":"detailed"}"#)
    }
}

// MARK: - SkillParser Name Validation Tests

@Suite("SkillParserNameValidation")
struct SkillParserNameValidationTests {

    /// Writes a minimal SKILL.md with the given name into a temp directory named `slug`.
    private func writeTempSkill(slug: String, name: String, description: String = "A skill.") throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appending(path: "SwiftOpenSkillsTests-\(UUID().uuidString)", directoryHint: .isDirectory)
            .appending(path: slug, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let content = """
        ---
        name: \(name)
        description: \(description)
        ---

        Body text.
        """
        let file = dir.appending(path: "SKILL.md", directoryHint: .notDirectory)
        try content.write(to: file, atomically: true, encoding: .utf8)
        return file
    }

    @Test("Uppercase name throws invalidName")
    func invalidNameFormatThrows() throws {
        let url = try writeTempSkill(slug: "my-skill", name: "My-Skill")
        #expect(throws: SkillError.self) {
            try SkillParser.parse(fileURL: url, slug: "my-skill")
        }
    }

    @Test("Name not matching directory slug throws invalidName")
    func nameDirectoryMismatchThrows() throws {
        let url = try writeTempSkill(slug: "my-skill", name: "other-name")
        #expect(throws: SkillError.self) {
            try SkillParser.parse(fileURL: url, slug: "my-skill")
        }
    }

    @Test("Name with consecutive hyphens throws invalidName")
    func nameWithConsecutiveHyphensThrows() throws {
        let url = try writeTempSkill(slug: "a--b", name: "a--b")
        #expect(throws: SkillError.self) {
            try SkillParser.parse(fileURL: url, slug: "a--b")
        }
    }

    @Test("Name longer than 64 characters throws invalidName")
    func nameTooLongThrows() throws {
        let longName = String(repeating: "a", count: 65)
        let url = try writeTempSkill(slug: longName, name: longName)
        #expect(throws: SkillError.self) {
            try SkillParser.parse(fileURL: url, slug: longName)
        }
    }

    @Test("Name with leading hyphen throws invalidName")
    func nameWithLeadingHyphenThrows() throws {
        let url = try writeTempSkill(slug: "-foo", name: "-foo")
        #expect(throws: SkillError.self) {
            try SkillParser.parse(fileURL: url, slug: "-foo")
        }
    }
}

