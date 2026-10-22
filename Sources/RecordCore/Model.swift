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
    public var weight = 0.5          // 0...1
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
        // Name a song of the week only when one frame is clearly the thickest, not a nudge of the slider.
        let byWeight = songs.sorted { $0.weight > $1.weight }, top = byWeight[0]
        if byWeight.count > 1, top.weight - byWeight[1].weight >= 0.1 { parts.append("The thickest frame is around \(top.title), the song of the week.") }
    }
    return parts.joined(separator: " ")
}

/// One-sentence forecast from the songs' genres and weights. Nil until a known genre is present.
/// `seed` 0 is the plain reading; Regenerate bumps it to vary the wording and which genres speak.
public func vibe(for songs: [Song], seed: Int = 0) -> String? {
    var totals: [String: Double] = [:]
    for s in songs where weather[s.genre] != nil { totals[s.genre, default: 0] += max(s.weight, 0.05) }
    let ranked = totals.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }.compactMap { weather[$0.key] }
    guard let top = ranked.first else { return nil }
    let others = Array(ranked.dropFirst()), n = max(seed, 0)
    let feel = others.isEmpty ? top.feel : others[(n / 3) % others.count].feel
    let activity = (n / 6) % 2 == 1 && !others.isEmpty ? others[0].activity : top.activity
    let topTwo = totals.values.sorted(by: >).prefix(2).reduce(0, +)
    let chance = Int((topTwo / totals.values.reduce(0, +) * 10).rounded()) * 10
    switch n % 3 {
    case 1:  return "\(top.sky) skies turning \(feel), with a \(chance)% chance of \(activity)."
    case 2:  return "Mostly \(top.sky.lowercased()), \(feel) later on, \(chance)% chance of \(activity)."
    default: return "\(top.sky) and \(feel), \(chance)% chance of \(activity)."
    }
}

/// The vibe as it appears everywhere: your own words if you've edited it, otherwise the forecast.
public func vibeLine(for week: Week) -> String? {
    if let own = week.vibeOverride?.trimmingCharacters(in: .whitespacesAndNewlines), !own.isEmpty { return own }
    return vibe(for: week.songs, seed: week.vibeSeed ?? 0)
}

/// A safe file name from the week label: lowercase letters, digits and single dashes, nothing that can climb out of a folder.
public func fileStem(for label: String) -> String {
    let kept = label.lowercased().map { ("a"..."z").contains($0) || ("0"..."9").contains($0) ? $0 : "-" }
    let stem = String(kept).split(separator: "-").joined(separator: "-")
    return stem.isEmpty ? "record-highs" : String(stem.prefix(60))
}

/// Frame thickness in points: 2pt at weight 0, 14pt at weight 1.
public func frameWidth(weight: Double) -> Double { 2 + 12 * min(max(weight, 0), 1) }
