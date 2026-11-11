import Foundation

/// What a folder's window looked like when it was last used.
public struct WindowState: Codable, Equatable {
    public var file: String?
    public var line: Int = 1
    public var sidebarVisible: Bool?
    public var collapsedFolders: [String] = []

    public init() {}
}

public enum WindowStateStore {
    private static let statesKey = "windowStates"
    private static let lastRootKey = "lastRoot"

    public static func load(root: String, from defaults: UserDefaults = .standard) -> WindowState {
        all(from: defaults)[root] ?? WindowState()
    }

    public static func save(_ state: WindowState, root: String, to defaults: UserDefaults = .standard) {
        var states = all(from: defaults)
        states[root] = state
        if let data = try? JSONEncoder().encode(states) {
            defaults.set(data, forKey: statesKey)
        }
        defaults.set(root, forKey: lastRootKey)
    }

    public static func lastRoot(from defaults: UserDefaults = .standard) -> String? {
        defaults.string(forKey: lastRootKey)
    }

    private static func all(from defaults: UserDefaults) -> [String: WindowState] {
        guard let data = defaults.data(forKey: statesKey),
              let states = try? JSONDecoder().decode([String: WindowState].self, from: data) else {
            return [:]
        }
        return states
    }
}
