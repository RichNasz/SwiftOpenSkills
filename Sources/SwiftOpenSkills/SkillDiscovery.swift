import Foundation

/// Discovers Agent Skills by scanning filesystem locations for directories containing `SKILL.md`.
///
/// Initialize with a search hierarchy using `SkillSearchPath` values. Call `discover()` to
/// scan all locations and return successfully parsed skills alongside any parse failures.
///
/// Slug deduplication: if the same directory name (lowercased) appears in multiple search
/// locations, the first occurrence wins.
public actor SkillDiscovery {

    private let searchPaths: [SkillSearchPath]

    /// Creates a `SkillDiscovery` that scans only the platform-standard locations.
    public init() {
        self.searchPaths = [.standard]
    }

    /// Creates a `SkillDiscovery` with the given ordered search paths.
    /// Pass `.standard` anywhere in the list to include standard locations at that position.
    public init(_ searchPaths: SkillSearchPath...) {
        self.searchPaths = searchPaths
    }

    /// Creates a `SkillDiscovery` with an explicit array of ordered search paths.
    public init(_ searchPaths: [SkillSearchPath]) {
        self.searchPaths = searchPaths
    }

    /// Scans all configured search paths and returns a `DiscoveryResult`.
    ///
    /// Parse failures are collected into `DiscoveryResult.failures` rather than thrown,
    /// so a single bad SKILL.md does not abort the entire scan.
    public func discover() async throws -> DiscoveryResult {
        var expandedURLs: [URL] = []
        for path in searchPaths {
            switch path.kind {
            case .standard:
                expandedURLs.append(contentsOf: SkillSearchPath.standardURLs())
            case .directory(let url):
                expandedURLs.append(url)
            }
        }

        var discoveredSlugs: Set<String> = []
        var skills: [Skill] = []
        var failures: [DiscoveryFailure] = []
        let fm = FileManager.default

        for dirURL in expandedURLs {
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: dirURL.path, isDirectory: &isDir), isDir.boolValue else {
                continue
            }

            let contents: [URL]
            do {
                contents = try fm.contentsOfDirectory(
                    at: dirURL,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: .skipsHiddenFiles
                )
            } catch {
                continue
            }

            for itemURL in contents {
                var itemIsDir: ObjCBool = false
                guard fm.fileExists(atPath: itemURL.path, isDirectory: &itemIsDir),
                      itemIsDir.boolValue else {
                    continue
                }

                let slug = itemURL.lastPathComponent.lowercased()
                guard !discoveredSlugs.contains(slug) else {
                    continue // Shadowed by a higher-priority path
                }

                let skillFileURL = itemURL.appending(path: "SKILL.md", directoryHint: .notDirectory)
                guard fm.fileExists(atPath: skillFileURL.path) else {
                    continue
                }

                do {
                    let skill = try SkillParser.parse(fileURL: skillFileURL, slug: slug)
                    discoveredSlugs.insert(slug)
                    for alias in skill.aliases {
                        discoveredSlugs.insert(alias)
                    }
                    skills.append(skill)
                } catch let error as SkillError {
                    failures.append(DiscoveryFailure(directoryURL: itemURL, error: error))
                }
            }
        }

        return DiscoveryResult(skills: skills, failures: failures)
    }
}

/// The result of a skill discovery scan.
public struct DiscoveryResult: Sendable {
    /// All successfully parsed skills, deduplicated by slug (first-wins across search paths).
    public let skills: [Skill]
    /// Parse failures encountered during scanning. Not fatal — other skills are still returned.
    public let failures: [DiscoveryFailure]
}

/// Describes a single parse failure encountered during a discovery scan.
public struct DiscoveryFailure: Sendable {
    /// The directory whose `SKILL.md` failed to parse.
    public let directoryURL: URL
    /// The specific error.
    public let error: SkillError
}
