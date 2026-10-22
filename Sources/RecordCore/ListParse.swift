import Foundation

private let quotesAndSpace = CharacterSet(charactersIn: " \t\"“”")

/// One song read from pasted text.
public struct Listed: Equatable {
    public var title: String, artist: String
    public init(title: String, artist: String) { self.title = title; self.artist = artist }
}

/// Reads pasted lines such as "teeth - mallrat", "teeth by mallrat" or "1. teeth by mallrat".
/// The last separator on a line splits title from artist, so "Stand by Me - Ben E. King" and
/// "American Woman - David Lynch Remix by Muddy Magnolias" both come out right.
/// Headings ending in a colon and "Vibe:" lines are skipped, so a pasted Buffer caption round-trips.
public func parseSongList(_ text: String, limit: Int = 12) -> [Listed] {
    var out: [Listed] = []
    for raw in text.split(whereSeparator: \.isNewline) {
        var line = raw.trimmingCharacters(in: .whitespaces)
        line = line.replacingOccurrences(of: #"^(?:\d+[.)]|[-•*])\s+"#, with: "", options: .regularExpression)
        line = line.trimmingCharacters(in: quotesAndSpace)
        if line.isEmpty || line.hasSuffix(":") || line.lowercased().hasPrefix("vibe:") { continue }
        let found = [" - ", " – ", " — ", " by "].compactMap { sep in
            line.range(of: sep, options: [.backwards, .caseInsensitive])
        }
        var title = line, artist = ""
        if let cut = found.max(by: { $0.lowerBound < $1.lowerBound }) {
            let t = line[..<cut.lowerBound].trimmingCharacters(in: quotesAndSpace)
            let a = line[cut.upperBound...].trimmingCharacters(in: quotesAndSpace)
            if !t.isEmpty && !a.isEmpty { title = t; artist = a }
        }
        out.append(Listed(title: String(title.prefix(120)), artist: String(artist.prefix(120))))
        if out.count == limit { break }
    }
    return out
}

/// Puts listed songs into the empty slots, in order. Songs already on the week are skipped.
public func place(_ list: [Listed], into songs: [Song]) -> (songs: [Song], added: Int, duplicates: Int, noRoom: Int) {
    var songs = songs, added = 0, duplicates = 0, noRoom = 0
    var seen = Set(songs.filter { !$0.title.isEmpty }.map { songKey($0.title, $0.artist) })
    for item in list {
        guard seen.insert(songKey(item.title, item.artist)).inserted else { duplicates += 1; continue }
        guard let i = songs.firstIndex(where: { $0.title.isEmpty }) else { noRoom += 1; continue }
        songs[i].title = item.title; songs[i].artist = item.artist; added += 1
    }
    return (songs, added, duplicates, noRoom)
}
