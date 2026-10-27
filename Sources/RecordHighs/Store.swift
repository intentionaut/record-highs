import Foundation
import RecordCore

/// Keeps the current week in the app's own sandbox container, so a quit or crash loses nothing.
enum Store {
    static var url: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("week.json")
    }
    static func load() -> Week? { (try? Data(contentsOf: url)).flatMap { try? JSONDecoder().decode(Week.self, from: $0) } }
    /// Keeps a rolled-over week beside the current one (week-week-43.json) so its songs and covers can be recovered.
    static func archive(_ week: Week) {
        let name = "week-\(fileStem(for: week.label)).json"
        try? JSONEncoder().encode(week).write(to: url.deletingLastPathComponent().appendingPathComponent(name), options: .atomic)
    }
    static func save(_ week: Week) { try? JSONEncoder().encode(week).write(to: url, options: .atomic) }
}
