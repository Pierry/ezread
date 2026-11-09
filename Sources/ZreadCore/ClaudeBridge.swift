import Foundation

/// Runs the user's own Claude Code, one question at a time.
public final class ClaudeBridge {
    private let timeout: TimeInterval
    private let locate: () -> URL?

    private var process: Process?
    private var generation = 0
    public private(set) var isRunning = false

    public init(timeout: TimeInterval = 180, locate: @escaping () -> URL? = ClaudeBridge.findClaude) {
        self.timeout = timeout
        self.locate = locate
        // Writing to a process that has exited must not take the app down.
        signal(SIGPIPE, SIG_IGN)
    }

    /// Calls `completion` on the main thread, unless cancelled first.
    public func ask(document: String, completion: @escaping (Result<AttentionBrief, AttentionFailure>) -> Void) {
        cancel()
        generation += 1
        let current = generation
        isRunning = true

        let finish: (Result<AttentionBrief, AttentionFailure>) -> Void = { [weak self] result in
            DispatchQueue.main.async {
                guard let self, self.generation == current else { return }
                self.isRunning = false
                self.process = nil
                completion(result)
            }
        }

        let locate = self.locate
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let executable = locate() else {
                finish(.failure(.claudeNotFound))
                return
            }
            self?.launch(executable, document: document, generation: current, finish: finish)
        }
    }

    public func cancel() {
        generation += 1
        isRunning = false
        process?.terminate()
        process = nil
    }

    private func launch(
        _ executable: URL,
        document: String,
        generation current: Int,
        finish: @escaping (Result<AttentionBrief, AttentionFailure>) -> Void
    ) {
        let child = Process()
        let input = Pipe()
        let output = Pipe()
        child.executableURL = executable
        child.arguments = AttentionRequest.arguments
        child.currentDirectoryURL = FileManager.default.temporaryDirectory
        child.environment = Self.environment(for: executable, base: ProcessInfo.processInfo.environment)
        child.standardInput = input
        child.standardOutput = output
        child.standardError = FileHandle.nullDevice

        do {
            try child.run()
        } catch {
            finish(.failure(.claudeFailed(error.localizedDescription)))
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // Cancelled while launching: the process has no owner left.
            if self.generation == current { self.process = child } else { child.terminate() }
        }

        var timedOut = false
        let watchdog = DispatchWorkItem {
            timedOut = true
            child.terminate()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: watchdog)

        // Written apart from the read so a large document cannot deadlock on full pipes.
        DispatchQueue.global().async {
            try? input.fileHandleForWriting.write(contentsOf: Data(document.utf8))
            try? input.fileHandleForWriting.close()
        }

        let data = output.fileHandleForReading.readDataToEndOfFile()
        child.waitUntilExit()
        watchdog.cancel()

        if timedOut {
            finish(.failure(.timedOut))
            return
        }
        finish(Result { try AttentionRequest.parse(data) }.mapError { $0 as? AttentionFailure ?? .unreadableAnswer })
    }

    /// Apps opened from Finder get a minimal PATH, so common install paths come first.
    public static func findClaude() -> URL? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return firstExecutable(in: [
            "\(home)/.local/bin/claude",
            "\(home)/.claude/local/claude",
            "/opt/homebrew/bin/claude",
            "/usr/local/bin/claude",
        ]) ?? executableFromLoginShell("command -v claude")
    }

    static func firstExecutable(in candidates: [String]) -> URL? {
        candidates.first(where: FileManager.default.isExecutableFile).map(URL.init(fileURLWithPath:))
    }

    /// Profiles can print banners, so only the last line counts.
    static func executableFromLoginShell(_ command: String) -> URL? {
        let shell = Process()
        let output = Pipe()
        shell.executableURL = URL(fileURLWithPath: "/bin/zsh")
        shell.arguments = ["-lc", command]
        shell.standardOutput = output
        shell.standardError = FileHandle.nullDevice
        guard (try? shell.run()) != nil else { return nil }

        let data = output.fileHandleForReading.readDataToEndOfFile()
        shell.waitUntilExit()
        let lines = String(decoding: data, as: UTF8.self).split(whereSeparator: \.isNewline)
        return firstExecutable(in: lines.last.map { [String($0)] } ?? [])
    }

    static func environment(for executable: URL, base: [String: String]) -> [String: String] {
        var environment = base
        let directories = [executable.deletingLastPathComponent().path, "/opt/homebrew/bin", "/usr/local/bin"]
        environment["PATH"] = (directories + [base["PATH"] ?? "/usr/bin:/bin"]).joined(separator: ":")
        environment.removeValue(forKey: "CLAUDECODE")
        return environment
    }
}
