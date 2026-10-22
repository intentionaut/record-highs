import Foundation

public struct RGB: Equatable { public let r, g, b: Double }

/// Parses "#RRGGBB". Anything malformed falls back to grey.
public func colour(hex: String) -> RGB {
    guard hex.count == 7, hex.first == "#", let v = UInt32(hex.dropFirst(), radix: 16)
    else { return RGB(r: 0.5, g: 0.5, b: 0.5) }
    return RGB(r: Double(v >> 16 & 0xFF) / 255, g: Double(v >> 8 & 0xFF) / 255, b: Double(v & 0xFF) / 255)
}

public struct Song: Identifiable, Codable, Equatable {
    public var id = UUID()
    public var title = "", artist = "", genre = ""   // genre feeds the vibe; not shown in the editor
    public var album: String?        // from Find cover or Apple Music; used in alt text. Optional so older saves still load.
    public var cover: Data?          // image bytes; saved with the week, never uploaded
    public init() {}
}

/// Everything you've entered for one week. Saved on every change so nothing is lost on quit.
public struct Week: Codable, Equatable {
    public var label: String, dates: String, songs: [Song]
    public var vibeOverride: String?   // your edit of the vibe line; nil means use the forecast
    public var vibeSeed: Int?          // which regenerated wording; optional so older saves still load
    public init(label: String, dates: String, songs: [Song] = (0..<6).map { _ in Song() }) {
        self.label = label; self.dates = dates; self.songs = songs
    }
}

/// Adds what a lookup found without overwriting anything the person already has: a typed genre, a dropped cover.
public func fillMissing(_ song: Song, genre: String, album: String?, cover: Data?) -> Song {
    var s = song
    if s.genre.isEmpty, !genre.isEmpty { s.genre = genre }
    if (s.album ?? "").isEmpty, let a = album, !a.isEmpty { s.album = a }
    if s.cover == nil { s.cover = cover }
    return s
}

/// The same week with all six songs and the vibe cleared; the week label, dates and name stay.
public func cleared(_ week: Week) -> Week {
    Week(label: week.label, dates: week.dates)
}

/// The post text copied for Buffer: the week, the songs, then the vibe. Songs without a title are skipped.
public func caption(for week: Week) -> String {
    let lines = week.songs.filter { !$0.title.isEmpty }.enumerated()
        .map { "\($0.offset + 1). \($0.element.title)" + ($0.element.artist.isEmpty ? "" : " by \($0.element.artist)") }
    let tail = vibeLine(for: week).map { v in ["Vibe: " + (v.hasSuffix(".") ? String(v.dropLast()) : v)] } ?? []
    return (["My week in music, \(week.label):"] + lines + tail).joined(separator: "\n")
}

/// Alt text for the poster: every word on it, in reading order, plus what the covers are.
public func altText(for week: Week, name: String) -> String {
    let songs = week.songs.filter { !$0.title.isEmpty }
    var parts = ["Record Highs poster. \(week.label), \(week.dates)" + (name.isEmpty ? "." : ", by \(name).")]
    if let v = vibeLine(for: week) { parts.append("Vibe: \(v)") }
    if !songs.isEmpty {
        parts.append("\(songs.count) album cover\(songs.count == 1 ? "" : "s") in a grid of three across, each with the song title and artist beneath:")
        parts += songs.enumerated().map { i, s in
            "\(i + 1). \(s.title)" + (s.artist.isEmpty ? "" : " by \(s.artist)")
                + ((s.album ?? "").isEmpty ? "." : ", cover of the album \(s.album!).")
        }
    }
    return parts.joined(separator: " ")
}

/// The vibe as it appears everywhere: your own words if you've edited it, otherwise the forecast.
public func vibeLine(for week: Week) -> String? {
    if let own = week.vibeOverride?.trimmingCharacters(in: .whitespacesAndNewlines), !own.isEmpty { return own }
    return vibe(for: week.songs, seed: week.vibeSeed ?? 0, key: week.label + "|" + week.dates)
}

/// A safe file name from the week label: lowercase letters, digits and single dashes, nothing that can climb out of a folder.
public func fileStem(for label: String) -> String {
    let kept = label.lowercased().map { ("a"..."z").contains($0) || ("0"..."9").contains($0) ? $0 : "-" }
    let stem = String(kept).split(separator: "-").joined(separator: "-")
    return stem.isEmpty ? "record-highs" : String(stem.prefix(60))
}

