import Foundation

/// FNV-1a over UTF-8. Swift's own hashing changes on every launch, which would change the forecast each time the app opens.
public func stableHash(_ s: String) -> UInt64 {
    var h: UInt64 = 0xcbf29ce484222325
    for b in s.utf8 { h ^= UInt64(b); h = h &* 0x100000001b3 }
    return h
}

/// The family a genre name belongs to, or nil if we don't know it.
public func family(of genre: String) -> String? {
    let g = genre.lowercased().trimmingCharacters(in: .whitespaces)
    if g.isEmpty { return nil }
    if let f = genreNames[g] { return f }
    // Names we haven't listed: the first keyword that appears wins, so "alternative rap" is hip-hop and "indie pop" is indie.
    let keywords: [(String, String)] = [("rap", "hiphop"), ("hip-hop", "hiphop"), ("hip hop", "hiphop"), ("r&b", "rnb"), ("soul", "rnb"),
        ("indie", "indie"), ("metal", "metal"), ("punk", "rock"), ("rock", "rock"), ("pop", "pop"), ("folk", "folk"),
        ("jazz", "jazz"), ("blues", "jazz"), ("classical", "classical"), ("ambient", "ambient"), ("electro", "electronic"),
        ("techno", "electronic"), ("house", "dance"), ("dance", "dance"), ("latin", "latin"), ("reggae", "reggae"),
        ("country", "country"), ("soundtrack", "soundtrack"), ("alternative", "alternative")]
    return keywords.first { g.contains($0.0) }?.1
}

private struct Shape { let text: String; var needsLabel = false }

private let baseShapes = [
    Shape(text: "{Sky} and {feel}, {pct}% chance of {activity}."),
    Shape(text: "{Sky} turning {feel}, with a {pct}% chance of {activity}."),
    Shape(text: "Mostly {sky}, {feel} later on, {pct}% chance of {activity}."),
    Shape(text: "{Sky} early, {feel} by evening, and a {pct}% chance of {activity}."),
    Shape(text: "Pressure rising on {label}: {sky} and {feel}, {pct}% chance of {activity}.", needsLabel: true),
    Shape(text: "Scattered {feel} spells, {sky} at times, {pct}% chance of {activity}."),
    Shape(text: "{a_label} front moves in, {sky} and {feel}, {pct}% chance of {activity}.", needsLabel: true),
    Shape(text: "Outlook: {sky} and {feel}, with {pct}% odds of {activity}."),
    Shape(text: "{Sky} with {feel} spells, {pct}% chance of {activity}, easing by the weekend."),
]

private func upperFirst(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }
private func lowerFirst(_ s: String) -> String { s.prefix(1).lowercased() + s.dropFirst() }

/// The longest a forecast may run; the poster allows three lines at 30pt.
public let vibeMaxLength = 150

/// One-sentence forecast from the week's songs. Every shape uses a sky, a feeling, an activity and a chance, so
/// `seed` 0, 1, 2 … gives a different line each time. `key` (the week's label and dates) makes the starting
/// point stable for a week and different from other weeks. Nil only when no song has a title.
public func vibe(for songs: [Song], seed: Int = 0, key: String = "") -> String? {
    let titled = songs.filter { !$0.title.isEmpty }
    guard !titled.isEmpty else { return nil }

    var counts: [String: Int] = [:]
    for s in titled { if let f = family(of: s.genre) { counts[f, default: 0] += 1 } }
    let ranked = counts.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
    let top = ranked.first.flatMap { weather[$0.key] } ?? neutralWeather
    let second = ranked.dropFirst().first.flatMap { weather[$0.key] }
    // The chance is out of every song with a title, so a song whose genre we couldn't find lowers it, not vanishes.
    let covered = ranked.prefix(2).map(\.value).reduce(0, +)
    let pct = ranked.isEmpty ? 50 : max(10, Int((Double(covered) / Double(titled.count) * 10).rounded()) * 10)

    // Shapes that only apply to some weeks.
    var shapes = baseShapes.filter { !$0.needsLabel || !ranked.isEmpty }
    if ranked.count >= 1, ranked.count <= 2, ranked.map(\.value).reduce(0, +) >= 3 {
        shapes.append(Shape(text: "Settled all week: {sky} and {feel}, {pct}% chance of {activity}."))
    }
    if ranked.count >= 4 {
        shapes.append(Shape(text: "Changeable, with {sky} spells and {feel} patches, {pct}% chance of {activity}."))
    }
    var artistCounts: [String: Int] = [:]
    for s in titled where !s.artist.isEmpty && s.artist.count <= 24 { artistCounts[s.artist, default: 0] += 1 }
    let repeated = artistCounts.filter { $0.value >= 2 }.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }.first?.key
    if repeated != nil {
        shapes.append(Shape(text: "{artist} settles in for the week, {sky} and {feel}, {pct}% chance of {activity}."))
        shapes.append(Shape(text: "Scattered {artist} showers, {sky} and {feel}, {pct}% chance of {activity}."))
    }
    if titled.count < 6 {
        shapes.append(Shape(text: "{count} in so far: {sky} and {feel}, {pct}% chance of {activity}."))
    }

    // Walk through every combination of shape, sky, feeling and activity in a scrambled order: the step is coprime to
    // the number of combinations, so no line repeats before they have all been shown, and each press of Regenerate
    // changes most of the words. The hash of `key` sets where the walk starts, so a week keeps its line between launches.
    let feelWords = (second ?? top).feels
    let genres = second == nil ? 1 : 2
    let radices = [top.skies.count, feelWords.count, top.activities.count, genres, shapes.count]
    let total = radices.reduce(1, *)
    var step = max(1, Int(Double(total) * 0.6180339887)) | 1
    func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }
    while gcd(step, total) != 1 { step += 2 }
    var idx = (Int(stableHash(key) % UInt64(total)) + max(seed, 0) * step) % total
    func next(_ radix: Int) -> Int { let d = idx % radix; idx /= radix; return d }
    let sky = top.skies[next(radices[0])]
    let feel = feelWords[next(radices[1])]
    let activityIndex = next(radices[2])
    let activityFrom = next(radices[3]) == 1 ? second! : top
    let activity = activityFrom.activities[activityIndex % activityFrom.activities.count]
    let shape = shapes[next(radices[4])]

    let numbers = ["", "One song", "Two songs", "Three songs", "Four songs", "Five songs"]
    let aLabel = (top.label.first.map { "aeiou".contains($0) } ?? false ? "an " : "a ") + top.label
    func render(_ s: Shape) -> String {
        upperFirst(s.text
            .replacingOccurrences(of: "{Sky}", with: upperFirst(sky)).replacingOccurrences(of: "{sky}", with: lowerFirst(sky))
            .replacingOccurrences(of: "{feel}", with: feel).replacingOccurrences(of: "{activity}", with: activity)
            .replacingOccurrences(of: "{pct}", with: String(pct)).replacingOccurrences(of: "{a_label}", with: aLabel).replacingOccurrences(of: "{label}", with: top.label)
            .replacingOccurrences(of: "{artist}", with: repeated ?? "").replacingOccurrences(of: "{count}", with: numbers[min(titled.count, 5)]))
    }
    let line = render(shape)
    return line.count <= vibeMaxLength ? line : render(baseShapes[0])
}
