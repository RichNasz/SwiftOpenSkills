// Generated from Examples/ShowCatalog/specs/SPEC.md + Overview.md
// Do not edit manually — update the spec and regenerate

import ArgumentParser
import Foundation
import ShowCatalogExample

@main
struct ShowCatalogCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "show-catalog",
        abstract: "Load skills from a directory and print the system prompt catalog section."
    )

    @Argument(help: "Path to the directory containing skill subdirectories to scan.")
    var directory: String

    func run() async throws {
        let url = URL(filePath: directory, directoryHint: .isDirectory)
        let output = try await ShowCatalog(directory: url).run()
        print(output)
    }
}
