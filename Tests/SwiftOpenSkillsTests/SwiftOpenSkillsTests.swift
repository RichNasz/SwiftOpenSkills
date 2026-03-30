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
    name: String = "Test Skill",
    description: String = "A test skill.",
    instructions: String = "Test instructions.",
    directoryURL: URL = URL(filePath: "/tmp/test-skill", directoryHint: .isDirectory)
) -> Skill {
    Skill(
        id: slug,
        name: name,
        description: description,
        version: nil,
        author: nil,
        tags: [],
        instructions: instructions,
        directoryURL: directoryURL
    )
}

private func storeWithSkill(
    slug: String,
    name: String = "Test Skill",
    instructions: String = "Test instructions."
) async -> SkillStore {
    let store = SkillStore()
    let skill = makeTestSkill(slug: slug, name: name, instructions: instructions)
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
        #expect(skill.name == "Valid Skill")
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
        #expect(skill.name == "Minimal Skill")
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

    @Test("Slug is the directory name passed in, not the YAML name")
    func slugIsDirectoryName() throws {
        let url = try skillFileURL("valid-skill")
        let skill = try SkillParser.parse(fileURL: url, slug: "valid-skill")
        #expect(skill.id == "valid-skill")
        #expect(skill.name == "Valid Skill") // YAML name != slug
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
        let crlfContent = "---\r\nname: CRLF Skill\r\ndescription: A CRLF test.\r\n---\r\nBody text.\r\n"
        let tmpDir = FileManager.default.temporaryDirectory
            .appending(path: "crlf-skill-test", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let tmpFile = tmpDir.appending(path: "SKILL.md", directoryHint: .notDirectory)
        try crlfContent.write(to: tmpFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let skill = try SkillParser.parse(fileURL: tmpFile, slug: "crlf-skill-test")
        #expect(skill.name == "CRLF Skill")
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
        try "---\nname: First\ndescription: From dir1.\n---\nBody1.".write(
            to: slug1.appending(path: "SKILL.md"), atomically: true, encoding: .utf8)
        try "---\nname: Second\ndescription: From dir2.\n---\nBody2.".write(
            to: slug2.appending(path: "SKILL.md"), atomically: true, encoding: .utf8)

        let discovery = SkillDiscovery(.directory(dir1), .directory(dir2))
        let result = try await discovery.discover()
        let found = result.skills.first { $0.id == "shared-skill" }
        #expect(found?.name == "First") // dir1 listed first → wins
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
        let store = await storeWithSkill(slug: "my-skill", name: "My Skill", instructions: "Do the thing.")
        let result = try await store.activateSkillHandler(argumentsJSON: #"{"name":"my-skill"}"#)
        #expect(result.contains("[Skill Activated: my-skill]"))
        #expect(result.contains("# My Skill"))
        #expect(result.contains("Do the thing."))
    }

    @Test("Output has no Resources line when skill has no resources directory")
    func handlerNoResourcesLine() async throws {
        let store = await storeWithSkill(slug: "no-res", name: "No Resources", instructions: "Body.")
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
        let store = await storeWithSkill(slug: "x", name: "X", instructions: "Body.")
        await #expect(throws: (any Error).self) {
            try await store.activateSkillHandler(argumentsJSON: "not-json")
        }
    }
}

// MARK: - SkillCatalog Tests

@Suite("SkillCatalog")
struct SkillCatalogTests {

    @Test("compactListing uses - slug: Name — description format")
    func compactListingFormat() {
        let skill = makeTestSkill(slug: "code-review", name: "Code Review", description: "Reviews code.")
        let catalog = SkillCatalog(skills: [skill])
        #expect(catalog.compactListing.contains("- code-review: Code Review — Reviews code."))
    }

    @Test("systemPromptSection contains catalog and activate_skill reference")
    func systemPromptSectionContainsCatalog() {
        let skill = makeTestSkill(slug: "git-commit", name: "Git Commit", description: "Writes commits.")
        let catalog = SkillCatalog(skills: [skill])
        let section = catalog.systemPromptSection()
        #expect(section.contains("## Available Skills"))
        #expect(section.contains("git-commit"))
        #expect(section.contains("activate_skill"))
    }

    @Test("entries array matches loaded skills")
    func catalogEntries() {
        let skill = makeTestSkill(slug: "my-skill", name: "My Skill", description: "Does stuff.")
        let catalog = SkillCatalog(skills: [skill])
        #expect(catalog.entries.count == 1)
        #expect(catalog.entries[0].slug == "my-skill")
        #expect(catalog.entries[0].name == "My Skill")
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
