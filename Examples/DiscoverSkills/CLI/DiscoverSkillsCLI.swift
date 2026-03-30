// Generated from Examples/DiscoverSkills/specs/SPEC.md + Overview.md
// Do not edit manually — update the spec and regenerate

import ArgumentParser
import DiscoverSkillsExample
import Foundation

@main
struct DiscoverSkillsCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "discover-skills",
        abstract: "Scan a directory for Agent Skills and list what was found."
    )

    @Argument(help: "Path to the directory containing skill subdirectories to scan.")
    var directory: String

    func run() async throws {
        let url = URL(filePath: directory, directoryHint: .isDirectory)
        let result = try await DiscoverSkills(directory: url).run()

        if result.skills.isEmpty {
            print("No skills found in \(directory)")
        } else {
            print("Found \(result.skills.count) skill(s):\n")
            for skill in result.skills {
                print("  \(skill.id) — \(skill.name)")
                print("  Description: \(skill.description)")
                if let version = skill.version {
                    print("  Version: \(version)")
                }
                if !skill.tags.isEmpty {
                    print("  Tags: \(skill.tags.joined(separator: ", "))")
                }
                print()
            }
        }

        if !result.failures.isEmpty {
            print("\(result.failures.count) failure(s):")
            for failure in result.failures {
                print("  \(failure.directoryURL.lastPathComponent): \(failure.error)")
            }
        }
    }
}
