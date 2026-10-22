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
    static func save(_ week: Week) { try? JSONEncoder().encode(week).write(to: url, options: .atomic) }
}
