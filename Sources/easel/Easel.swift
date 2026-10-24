import ArgumentParser
import EaselKit

@main
struct Easel: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "easel",
        abstract: "A CLI for the Canvas LMS API, built for AI agents that manage courses.",
        version: "0.1.0",
        subcommands: [
            CoursesCommand.self,
            PagesCommand.self,
            PageCommand.self,
            CreatePageCommand.self,
            UpdatePageCommand.self,
            DeletePageCommand.self,
            AssignmentsCommand.self,
            AssignmentCommand.self,
            CreateAssignmentCommand.self,
            UpdateAssignmentCommand.self,
            DeleteAssignmentCommand.self,
            SubmissionsCommand.self,
            UsersCommand.self,
            RubricsCommand.self,
            RubricCommand.self,
            CreateRubricCommand.self,
            UpdateRubricCommand.self,
            DeleteRubricCommand.self
        ]
    )

    static func main() async {
        let logging = EaselLog.bootstrapIfPossible()
        do {
            var command = try parseAsRoot()
            if var asyncCommand = command as? AsyncParsableCommand {
                try await asyncCommand.run()
            } else {
                try command.run()
            }
            await logging?.drain()
        } catch {
            await logging?.drain()
            exit(withError: error)
        }
    }

    static func emit<T: CanvasRow>(_ items: [T], format: OutputFormat) throws {
        let text = try OutputFormatter.render(items, format: format)
        if !text.isEmpty {
            print(text)
        }
    }

    static func emit<T: CanvasRow>(_ item: T, format: OutputFormat) throws {
        let text = try OutputFormatter.render(item, format: format)
        if !text.isEmpty {
            print(text)
        }
    }
}

extension OutputFormat: ExpressibleByArgument {}
