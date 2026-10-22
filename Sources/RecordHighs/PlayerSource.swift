import Foundation
import RecordCore

struct LibraryMatch { var title, artist, album, genre: String; var artwork: Data? }

struct NowPlaying { var title, artist, album, genre: String; var artwork: Data? }

/// A music player the app can read the current track from. Spotify can conform later.
protocol PlayerSource {
    var name: String { get }
    func nowPlaying() throws -> NowPlaying
    /// Tracks played, or Shazamed, since `since`. Local only: no network.
    func recent(since: Date) throws -> [Candidate]
    func artwork(id: String) -> Data?
    /// One song looked up in the player's library on this Mac.
    func libraryMatch(title: String, artist: String) -> LibraryMatch?
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

    /// Looks one song up in the Apple Music library. The title and artist reach the script as parameters of a
    /// handler call, never as part of its text, so nothing a person types or pastes can run as AppleScript.
    func libraryMatch(title: String, artist: String) -> LibraryMatch? {
        guard !title.isEmpty else { return nil }
        let source = """
        on lookup(t, a)
            tell application "Music"
                if a is "" then
                    set hits to (every track of library playlist 1 whose name is t)
                else
                    set hits to (every track of library playlist 1 whose name is t and artist contains a)
                end if
                if (count of hits) is 0 then return {}
                set x to item 1 of hits
                return {name of x, artist of x, album of x, genre of x, persistent ID of x}
            end tell
        end lookup
        """
        var err: NSDictionary?
        guard let script = NSAppleScript(source: source), script.compileAndReturnError(&err) else { return nil }
        func code(_ s: String) -> FourCharCode { s.utf8.reduce(0) { $0 << 8 | FourCharCode($1) } }
        let event = NSAppleEventDescriptor(eventClass: code("ascr"), eventID: code("psbr"), targetDescriptor: .currentProcess(),
                                           returnID: -1, transactionID: 0)   // -1: any return ID, 0: no transaction
        event.setParam(NSAppleEventDescriptor(string: "lookup"), forKeyword: code("snam"))
        let args = NSAppleEventDescriptor.list()
        args.insert(NSAppleEventDescriptor(string: title), at: 1)
        args.insert(NSAppleEventDescriptor(string: artist), at: 2)
        event.setParam(args, forKeyword: code("----"))
        let r = script.executeAppleEvent(event, error: &err)
        guard err == nil, r.numberOfItems == 5 else { return nil }
        return LibraryMatch(title: r.atIndex(1)?.stringValue ?? title, artist: r.atIndex(2)?.stringValue ?? artist,
                            album: r.atIndex(3)?.stringValue ?? "", genre: r.atIndex(4)?.stringValue ?? "",
                            artwork: artwork(id: r.atIndex(5)?.stringValue ?? ""))
    }
}
