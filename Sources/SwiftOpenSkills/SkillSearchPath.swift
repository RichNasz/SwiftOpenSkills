import Foundation

/// Describes a location (or set of locations) to scan for Agent Skills.
///
/// Build a search hierarchy by passing an ordered array of `SkillSearchPath` values
/// to `SkillDiscovery` or `SkillStore.load`. Earlier entries shadow later ones when
/// the same skill slug appears in multiple locations.
///
/// ## Examples
/// ```swift
/// // Standard locations only (default)
/// SkillDiscovery()
///
/// // Custom directory only — no standard locations
/// SkillDiscovery(.directory(myURL))
///
/// // Custom first, then standard (custom takes priority)
/// SkillDiscovery(.directory(myURL), .standard)
///
/// // Standard first, then a fallback directory
/// SkillDiscovery(.standard, .directory(fallbackURL))
///
/// // Multiple custom directories, no standard
/// SkillDiscovery(.directory(projectURL), .directory(sharedURL))
/// ```
public struct SkillSearchPath: Sendable {

    internal enum Kind: Sendable {
        case standard
        case directory(URL)
    }

    internal let kind: Kind

    /// The platform-standard Agent Skills locations, scanned in this order:
    ///   1. `{cwd}/skills/`
    ///   2. `{cwd}/.skills/`
    ///   3. `~/.config/agent-skills/`
    ///   4. `~/agent-skills/`
    ///   5. `/usr/local/share/agent-skills/` (macOS/Linux only)
    public static let standard = SkillSearchPath(kind: .standard)

    /// A single explicit directory to scan for skill subdirectories.
    /// Each immediate subdirectory of `url` that contains a `SKILL.md` is treated as a skill.
    public static func directory(_ url: URL) -> SkillSearchPath {
        SkillSearchPath(kind: .directory(url))
    }

    /// Returns the concrete URLs for the standard search path on the current platform.
    internal static func standardURLs() -> [URL] {
        var urls: [URL] = []
        let fm = FileManager.default
        let cwd = URL(filePath: fm.currentDirectoryPath, directoryHint: .isDirectory)
        urls.append(cwd.appending(path: "skills", directoryHint: .isDirectory))
        urls.append(cwd.appending(path: ".skills", directoryHint: .isDirectory))
        let home = URL(filePath: NSHomeDirectory(), directoryHint: .isDirectory)
        urls.append(home.appending(path: ".config").appending(path: "agent-skills", directoryHint: .isDirectory))
        urls.append(home.appending(path: "agent-skills", directoryHint: .isDirectory))
        #if os(macOS) || os(Linux)
        urls.append(URL(filePath: "/usr/local/share/agent-skills", directoryHint: .isDirectory))
        #endif
        return urls
    }
}
