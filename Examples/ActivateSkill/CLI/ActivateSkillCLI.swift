// Generated from Examples/ActivateSkill/specs/SPEC.md + Overview.md
// Do not edit manually — update the spec and regenerate

import ActivateSkillExample
import ArgumentParser
import Foundation

@main
struct ActivateSkillCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "activate-skill",
        abstract: "Load skills from a directory and activate one by slug, printing the formatted output."
    )

    @Argument(help: "Path to the directory containing skill subdirectories to scan.")
    var directory: String

    @Argument(help: "The skill slug (directory name) to activate.")
    var slug: String

    func run() async throws {
        let url = URL(filePath: directory, directoryHint: .isDirectory)
        let output = try await ActivateSkill(directory: url).run(slug: slug)
        print(output)
    }
}
