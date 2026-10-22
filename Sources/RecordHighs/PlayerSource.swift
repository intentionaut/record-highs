import Foundation
import RecordCore

struct NowPlaying { var title, artist, album, genre: String; var artwork: Data? }

/// A music player the app can read the current track from. Spotify can conform later.
protocol PlayerSource {
    var name: String { get }
    func nowPlaying() throws -> NowPlaying
    /// Tracks played, or Shazamed, since `since`. Local only: no network.
    func recent(since: Date) throws -> [Candidate]
    func artwork(id: String) -> Data?
}

struct PlayerError: LocalizedError { let errorDescription: String? }

/// Apple Music through its scripting interface. Needs the Apple Events entitlement.
struct AppleMusicSource: PlayerSource {
    let name = "Apple Music"
    private func run(_ body: String) throws -> NSAppleEventDescriptor {
        var err: NSDictionary?
        let script = NSAppleScript(source: "tell application \"Music\"\n\(body)\nend tell")
        guard let out = script?.executeAndReturnError(&err) else {
            throw PlayerError(errorDescription: err?[NSAppleScript.errorMessage] as? String ?? "Apple Music didn't answer.")
        }
        return out
    }

    func nowPlaying() throws -> NowPlaying {
        let info = try run("if player state is stopped then error \"Nothing is playing in Apple Music.\"\n"
                           + "return {name, artist, album, genre} of current track")
        let art = try? run("return raw data of artwork 1 of current track").data
        return NowPlaying(title: info.atIndex(1)?.stringValue ?? "", artist: info.atIndex(2)?.stringValue ?? "",
                          album: info.atIndex(3)?.stringValue ?? "", genre: info.atIndex(4)?.stringValue ?? "", artwork: art)
    }

    func recent(since: Date) throws -> [Candidate] {
        let days = max(1, Int(Date().timeIntervalSince(since) / 86_400))
        // Each row: name, artist, album, genre, played count, date, persistent ID. Library tracks only.
        let fields = "{name, artist, album, genre, played count, %@, persistent ID}"
        func rows(_ script: String, source: Candidate.Source) -> [Candidate] {
            guard let list = try? run(script) else { return [] }
            return (0..<list.numberOfItems).compactMap { i in
                guard let r = list.atIndex(i + 1), r.numberOfItems == 7 else { return nil }
                return Candidate(title: r.atIndex(1)?.stringValue ?? "", artist: r.atIndex(2)?.stringValue ?? "",
                                 album: r.atIndex(3)?.stringValue ?? "", genre: r.atIndex(4)?.stringValue ?? "",
                                 plays: Int(r.atIndex(5)?.int32Value ?? 0), when: r.atIndex(6)?.dateValue ?? .distantPast,
                                 source: source, id: r.atIndex(7)?.stringValue ?? "")
            }
        }
        let played = rows("""
            set cutoff to (current date) - \(days) * days
            set out to {}
            repeat with t in (every track of library playlist 1 whose played date > cutoff)
                set end of out to \(String(format: fields, "played date")) of t
            end repeat
            return out
            """, source: .played)
        // Shazam saves to this playlist when it's linked to Apple Music; if it isn't there, there are simply no Shazams.
        let shazams = rows("""
            if not (exists playlist "My Shazam Tracks") then return {}
            set cutoff to (current date) - \(days) * days
            set out to {}
            repeat with t in (every track of playlist "My Shazam Tracks" whose date added > cutoff)
                set end of out to \(String(format: fields, "date added")) of t
            end repeat
            return out
            """, source: .shazam)
        return played + shazams
    }

    func artwork(id: String) -> Data? {
        guard id.allSatisfy(\.isHexDigit) else { return nil }   // persistent IDs are hex; nothing else goes into the script
        return try? run("return raw data of artwork 1 of (first track of library playlist 1 whose persistent ID is \"\(id)\")").data
    }
}
