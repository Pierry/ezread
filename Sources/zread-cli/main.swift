import Foundation

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("zread: \(message)\n".utf8))
    exit(1)
}

let argument = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
guard let resolved = realpath(argument, nil) else {
    fail("caminho não encontrado: \(argument)")
}
let path = String(cString: resolved)
free(resolved)

var isDirectory: ObjCBool = false
FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
if !isDirectory.boolValue {
    let ext = (path as NSString).pathExtension.lowercased()
    if ext != "md" && ext != "markdown" {
        fail("não é um arquivo Markdown: \(argument)")
    }
}

/// The app that contains this binary, through any symlink on the PATH.
func enclosingAppPath() -> String {
    var size = UInt32(PATH_MAX)
    var buffer = [CChar](repeating: 0, count: Int(size))
    guard _NSGetExecutablePath(&buffer, &size) == 0, let real = realpath(buffer, nil) else {
        fail("não consegui localizar o app")
    }
    defer { free(real) }
    return URL(fileURLWithPath: String(cString: real))
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .path
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
process.arguments = ["-a", enclosingAppPath(), path]
do {
    try process.run()
    process.waitUntilExit()
} catch {
    fail("não consegui executar open: \(error.localizedDescription)")
}
if process.terminationStatus != 0 {
    fail("não consegui abrir o zread. O app está instalado?")
}
