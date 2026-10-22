import Foundation

/// A track the player says was played or Shazamed recently.
public struct Candidate: Equatable {
    public enum Source: Equatable { case played, shazam }
    public var title, artist, album, genre: String
    public var plays: Int, when: Date, source: Source, id: String
    public init(title: String, artist: String, album: String = "", genre: String = "", plays: Int = 0,
                when: Date, source: Source, id: String = "") {
        self.title = title; self.artist = artist; self.album = album; self.genre = genre
        self.plays = plays; self.when = when; self.source = source; self.id = id
    }
}

/// Chooses tracks for the empty slots: most played first (play counts are all-time, so this is an estimate),
/// then Shazams, newest first. Skips songs already on the week and duplicates. Returns at most `free` tracks.
public func pickForWeek(_ candidates: [Candidate], existing: [Song], free: Int) -> [Candidate] {
    func key(_ t: String, _ a: String) -> String { (t + "\u{1F}" + a).lowercased().trimmingCharacters(in: .whitespaces) }
    var seen = Set(existing.filter { !$0.title.isEmpty }.map { key($0.title, $0.artist) })
    let played = candidates.filter { $0.source == .played }.sorted { $0.plays != $1.plays ? $0.plays > $1.plays : $0.when > $1.when }
    let shazams = candidates.filter { $0.source == .shazam }.sorted { $0.when > $1.when }
    var picks: [Candidate] = []
    for c in played + shazams where picks.count < free && !c.title.isEmpty && seen.insert(key(c.title, c.artist)).inserted {
        picks.append(c)
    }
    return picks
}

/// Weight from rank: the first pick gets the thickest frame, the last a thin one.
public func weightForRank(_ rank: Int, of count: Int) -> Double {
    count <= 1 ? 0.8 : 0.8 - 0.6 * Double(rank) / Double(count - 1)
}
