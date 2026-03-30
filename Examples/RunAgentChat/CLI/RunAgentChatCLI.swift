// Generated from Examples/RunAgentChat/specs/SPEC.md + Overview.md
// Do not edit manually — update the spec and regenerate

import ArgumentParser
import Foundation
import RunAgentChatExample

@main
struct RunAgentChatCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run-agent-chat",
        abstract: "Send a prompt to a Chat Completions API endpoint with skills pre-loaded."
    )

    @Argument(help: "The message to send to the agent.")
    var prompt: String

    @Option(name: .long, help: "Full URL of a Chat Completions API endpoint (e.g. http://127.0.0.1:1234/v1/chat/completions).")
    var serverURL: String

    @Option(name: .long, help: "Model identifier (e.g. gpt-4o, llama3).")
    var model: String

    @Option(name: .long, help: "Path to a directory of skills. If omitted, standard locations are scanned.")
    var skillsDir: String?

    @Option(name: .long, help: "API key for authentication. Omit for local or unauthenticated endpoints.")
    var apiKey: String?

    func run() async throws {
        guard let url = URL(string: serverURL) else {
            throw ValidationError("Invalid server URL: \(serverURL)")
        }
        let skillsDirectory = skillsDir.map { URL(filePath: $0, directoryHint: .isDirectory) }
        let example = RunAgentChat(serverURL: url, model: model, apiKey: apiKey, skillsDirectory: skillsDirectory)
        let reply = try await example.run(prompt: prompt)
        print(reply)
    }
}
