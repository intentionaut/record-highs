import XCTest
@testable import RecordCore

final class ColourTests: XCTestCase {
    func testFrameColourParses() { XCTAssertNotEqual(colour(hex: frameHex), RGB(r: 0.5, g: 0.5, b: 0.5)) }
    func testKnownColour() {
        let c = colour(hex: "#E4572E")
        XCTAssertEqual(c.r, 228 / 255, accuracy: 1e-9); XCTAssertEqual(c.b, 46 / 255, accuracy: 1e-9)
    }
    func testMalformedFallsBackToGrey() {
        for bad in ["", "E4572E", "#E4572", "#GGGGGG"] { XCTAssertEqual(colour(hex: bad), RGB(r: 0.5, g: 0.5, b: 0.5), bad) }
    }
}

final class LayoutTests: XCTestCase {
    func testSixCellsInsideCanvasWithoutOverlap() {
        for size in PosterSize.allCases {
            let (header, cells) = gridLayout(size)
            XCTAssertEqual(cells.count, 6)
            let canvas = CGRect(origin: .zero, size: size.pixels)
            for (i, c) in cells.enumerated() {
                XCTAssertTrue(canvas.contains(c.cover) && canvas.contains(c.caption), "\(size) cell \(i)")
                XCTAssertFalse(c.cover.intersects(header))
                XCTAssertEqual(c.cover.width, c.cover.height)
                for d in cells[(i + 1)...] { XCTAssertFalse(c.cover.intersects(d.cover)) }
            }
        }
    }
    func testRowsAndColumnsAlign() {
        let cells = gridLayout(.portrait).cells
        XCTAssertEqual(cells[0].cover.minY, cells[2].cover.minY)
        XCTAssertEqual(cells[0].cover.minX, cells[3].cover.minX)
        XCTAssertLessThan(cells[0].cover.minY, cells[3].cover.minY)
    }
}

final class WeekTests: XCTestCase {
    func testRoundTripKeepsEverything() throws {
        var w = Week(label: "Week 43", dates: "19 – 25 Oct")
        w.songs[0].title = "Nude"; w.songs[0].artist = "Radiohead"; w.songs[0].genre = "Alternative"
        w.songs[0].cover = Data([1, 2, 3])
        XCTAssertEqual(try JSONDecoder().decode(Week.self, from: JSONEncoder().encode(w)), w)
    }
    func testCaptionSkipsEmptySongsAndHasNoEmDash() {
        var w = Week(label: "Week 43", dates: "19 – 25 Oct")
        w.songs[0].title = "Nude"; w.songs[0].artist = "Radiohead"; w.songs[2].title = "Untitled"
        let lines = caption(for: w).split(separator: "\n").map(String.init)
        XCTAssertEqual(Array(lines.prefix(3)), ["My week in music, Week 43:", "1. Nude by Radiohead", "2. Untitled"])
        XCTAssertEqual(lines.count, 4)                                // no genres known, so the neutral forecast still ends the post
        XCTAssertTrue(lines[3].hasPrefix("Vibe: ") && !lines[3].hasSuffix("."), lines[3])
        XCTAssertFalse(caption(for: w).contains("—"))
    }
}

final class VibeTests: XCTestCase {
    func songs(_ rows: [(String, String, String)]) -> [Song] { rows.map { var s = Song(); s.title = $0.0; s.artist = $0.1; s.genre = $0.2; return s } }
    var herWeek: [Song] { songs([("a", "A", "Pop"), ("b", "B", "Dance"), ("c", "C", "Pop"), ("d", "D", ""), ("e", "E", ""), ("f", "F", "")]) }
    var mixedWeek: [Song] { songs([("a", "A", "Pop"), ("b", "B", "Alternative"), ("c", "C", "Hip-Hop/Rap"),
                                   ("d", "D", "Electronic"), ("e", "E", "Jazz"), ("f", "F", "Indie Pop")]) }
    func oneGenre(_ g: String) -> [Song] { songs((0..<6).map { ("t\($0)", "A\($0)", g) }) }

    func testStableHashGoldens() {   // FNV-1a 64-bit reference values
        XCTAssertEqual(stableHash(""), 0xcbf29ce484222325)
        XCTAssertEqual(stableHash("a"), 0xaf63dc4c8601ec8c)
    }
    func testGenreNamesFromAnAppleMusicLibraryAllMapToAFamily() {
        let names = ["Alternative", "Pop", "Hip-Hop/Rap", "Electronic", "R&B/Soul", "Rock", "Dance", "Indie Pop", "Soundtrack", "Indie Rock",
                     "Singer/Songwriter", "Hard Rock", "Latin", "House", "Jazz", "Electronica", "Instrumental", "Pop Latino", "Hip-Hop", "Rap",
                     "Folk", "Metal", "MPB", "Alternative Folk", "Worldwide", "Soul", "French Pop", "Bossa Nova", "Urbano latino", "Techno",
                     "Downtempo", "Classical", "Ambient", "Alternative Rap", "Dubstep", "Blues", "Reggae", "Neo-Soul", "K-Pop", "Country",
                     "Contemporary R&B", "Punk", "Classical Crossover", "Bass", "Contemporary Folk", "Afrobeats", "New Age", "Adult Alternative",
                     "Jungle/Drum'n'bass"]
        for n in names { XCTAssertNotNil(family(of: n), n) }
        XCTAssertEqual(family(of: "Alternative Rap"), "hiphop"); XCTAssertEqual(family(of: "Indie Pop"), "indie")
        XCTAssertEqual(family(of: "Psychedelic Rock"), "rock"); XCTAssertEqual(family(of: "trap rap"), "hiphop")
        XCTAssertNil(family(of: "Polka")); XCTAssertNil(family(of: "")); XCTAssertNil(family(of: "  "))
    }
    func testEveryFamilyIsComplete() {
        for f in Set(genreNames.values) { XCTAssertNotNil(weather[f], f) }
        for (f, w) in weather + [("neutral", neutralWeather)] {
            XCTAssertEqual(w.skies.count, 4, f); XCTAssertEqual(w.feels.count, 4, f); XCTAssertEqual(w.activities.count, 4, f)
            for phrase in w.skies + w.feels + w.activities { XCTAssertFalse(phrase.contains("—") || phrase.contains("–") || phrase.contains("."), phrase) }
        }
    }
    func testNothingTitledMeansNoVibe() { XCTAssertNil(vibe(for: (0..<6).map { _ in var s = Song(); s.genre = "Pop"; return s })) }
    func testTitledSongsWithNoKnownGenreStillGetALine() {
        let v = vibe(for: songs([("a", "X", "Polka"), ("b", "Y", "")]))!
        XCTAssertTrue(v.contains("50%"), v)
    }
    func testTheChanceIsOutOfEveryTitledSong() {
        XCTAssertTrue(vibe(for: herWeek)!.contains("50%"))                     // 3 of 6 have a genre
        XCTAssertTrue(vibe(for: oneGenre("Pop"))!.contains("100%"))
        XCTAssertTrue(vibe(for: songs([("a", "A", "Pop"), ("b", "B", ""), ("c", "C", ""), ("d", "D", ""), ("e", "E", ""), ("f", "F", "")]))!.contains("20%"))
    }
    func testSameWeekSameLineButOtherWeeksDiffer() {
        XCTAssertEqual(vibe(for: mixedWeek, key: "Week 43|x"), vibe(for: mixedWeek, key: "Week 43|x"))
        let lines = (40...52).map { vibe(for: mixedWeek, key: "Week \($0)|x")! }
        XCTAssertGreaterThan(Set(lines).count, 6)
    }
    func testRegenerateWalksThroughDistinctLines() {
        for (name, week) in [("her", herWeek), ("mixed", mixedWeek), ("one genre", oneGenre("Jazz"))] {
            let lines = (0..<30).map { vibe(for: week, seed: $0, key: "Week 43|x")! }
            XCTAssertEqual(Set(lines).count, 30, name)
        }
    }
    func testEveryLineIsOneShortWellFormedSentence() {
        let weeks = Set(genreNames.values).map { oneGenre(family: $0) } + [herWeek, mixedWeek, songs([("a", "X", "Polka")])]
        for week in weeks { for seed in 0..<160 {
            let v = vibe(for: week, seed: seed, key: "k")!
            XCTAssertLessThanOrEqual(v.count, vibeMaxLength, v)
            XCTAssertEqual(v.filter { $0 == "." }.count, 1, v); XCTAssertTrue(v.hasSuffix("."), v)
            XCTAssertFalse(v.contains("—") || v.contains("–") || v.contains("{") || v.contains("}"), v)
            XCTAssertTrue(v.first!.isUppercase, v)
        } }
    }
    func oneGenre(family f: String) -> [Song] { oneGenre(genreNames.first { $0.value == f }!.key) }
    func testArticlesAgreeWithTheLabel() {
        let alt = (0..<200).map { vibe(for: oneGenre("Alternative"), seed: $0, key: "k")! }.filter { $0.contains("front moves in") }
        XCTAssertFalse(alt.isEmpty); for l in alt { XCTAssertTrue(l.hasPrefix("An alternative front"), l) }
        let pop = (0..<200).map { vibe(for: oneGenre("Pop"), seed: $0, key: "k")! }.filter { $0.contains("front moves in") }
        XCTAssertFalse(pop.isEmpty); for l in pop { XCTAssertTrue(l.hasPrefix("A pop front"), l) }
    }
    func testRepeatedArtistIsNamedSometimesAndLongNamesNever() {
        var week = mixedWeek; week[0].artist = "Cobrah"; week[1].artist = "Cobrah"
        let named = (0..<200).map { vibe(for: week, seed: $0, key: "k")! }
        XCTAssertTrue(named.contains { $0.contains("Cobrah") }); XCTAssertTrue(named.contains { !$0.contains("Cobrah") })
        let long = String(repeating: "x", count: 30)
        week[0].artist = long; week[1].artist = long
        XCTAssertFalse((0..<200).contains { vibe(for: week, seed: $0, key: "k")!.contains(long) })
    }
    func testHalfFilledWeekSaysSoSometimes() {
        let few = songs([("a", "A", "Pop"), ("b", "B", "Pop"), ("c", "C", "Pop")])
        XCTAssertTrue((0..<200).contains { vibe(for: few, seed: $0, key: "k")!.contains("Three songs in so far") })
        XCTAssertFalse((0..<200).contains { vibe(for: herWeek, seed: $0, key: "k")!.contains("so far") })
    }
    func testManyGenresReadAsChangeableAndFewAsSettled() {
        XCTAssertTrue((0..<200).contains { vibe(for: mixedWeek, seed: $0, key: "k")!.hasPrefix("Changeable") })
        XCTAssertTrue((0..<200).contains { vibe(for: oneGenre("Pop"), seed: $0, key: "k")!.hasPrefix("Settled") })
        XCTAssertFalse((0..<200).contains { vibe(for: mixedWeek, seed: $0, key: "k")!.hasPrefix("Settled") })
    }
}
final class VibeEditTests: XCTestCase {
    func week() -> Week {
        var w = Week(label: "Week 43", dates: "19 – 25 Oct")
        for (i, g) in ["Pop", "Alternative", "Pop", "Alternative", "Electronic", "Soundtrack"].enumerated() {
            w.songs[i].title = "s\(i)"; w.songs[i].artist = "a\(i)"; w.songs[i].genre = g
        }
        return w
    }
    func testYourWordsWinEverywhere() {
        var w = week(); w.vibeOverride = "Sunny with a chance of Mallrat."
        XCTAssertEqual(vibeLine(for: w), "Sunny with a chance of Mallrat.")
        XCTAssertTrue(caption(for: w).hasSuffix("\nVibe: Sunny with a chance of Mallrat"))
        XCTAssertTrue(altText(for: w, name: "").contains("Vibe: Sunny with a chance of Mallrat."))
    }
    func testBlankEditFallsBackToTheForecast() {
        var w = week(); w.vibeOverride = "  "
        XCTAssertEqual(vibeLine(for: w), vibe(for: w.songs, seed: 0, key: "Week 43|19 – 25 Oct"))
    }
    func testRegenerateGivesANewLineEachTime() {
        var w = week(); var seen = Set<String>()
        for i in 0..<20 { w.vibeSeed = i; seen.insert(vibeLine(for: w)!) }
        XCTAssertEqual(seen.count, 20)
    }
    func testTheLineDoesNotChangeWhileYouTypeTitles() {
        var w = week(); let before = vibeLine(for: w)
        w.songs[0].title = "something else entirely"
        XCTAssertEqual(vibeLine(for: w), before)   // the key is the week label and dates, not the titles
    }
}
final class FileStemTests: XCTestCase {
    func testOrdinaryLabel() { XCTAssertEqual(fileStem(for: "Week 43"), "week-43") }
    func testCannotEscapeTheFolder() {
        for bad in ["../escaped", "../../etc/x", "/tmp/x", "a/b", "..", "~/x", "week\u{0}43"] {
            let s = fileStem(for: bad)
            XCTAssertFalse(s.contains("/") || s.contains(".") || s.contains("~") || s.contains("\u{0}"), bad)
        }
        XCTAssertEqual(fileStem(for: "../escaped"), "escaped")
    }
    func testEmptyAndSymbolsOnlyGetADefault() { XCTAssertEqual(fileStem(for: "/// ..."), "record-highs") }
    func testLongLabelIsCapped() { XCTAssertLessThanOrEqual(fileStem(for: String(repeating: "a", count: 300)).count, 60) }
}

final class FillTests: XCTestCase {
    let now = Date()
    func c(_ t: String, _ plays: Int, ago: Double, _ s: Candidate.Source = .played) -> Candidate {
        Candidate(title: t, artist: "A", plays: plays, when: now.addingTimeInterval(-ago * 3600), source: s)
    }
    func testMostPlayedFirstThenShazamsNewestFirst() {
        let picks = pickForWeek([c("low", 1, ago: 1), c("high", 9, ago: 50), c("old shazam", 0, ago: 40, .shazam),
                                 c("new shazam", 0, ago: 2, .shazam)], existing: [], free: 4)
        XCTAssertEqual(picks.map(\.title), ["high", "low", "new shazam", "old shazam"])
    }
    func testSkipsSongsAlreadyOnTheWeekAndDuplicates() {
        var s = Song(); s.title = "High"; s.artist = "a"
        let picks = pickForWeek([c("high", 9, ago: 1), c("x", 2, ago: 1), c("X", 1, ago: 1, .shazam)], existing: [s], free: 6)
        XCTAssertEqual(picks.map(\.title), ["x"])
    }
    func testNeverMoreThanFreeSlots() {
        XCTAssertEqual(pickForWeek((0..<10).map { c("t\($0)", $0, ago: 1) }, existing: [], free: 2).count, 2)
        XCTAssertTrue(pickForWeek([c("t", 1, ago: 1)], existing: [], free: 0).isEmpty)
    }
}

final class ClearTests: XCTestCase {
    func testClearKeepsTheWeekAndEmptiesTheSongs() {
        var w = Week(label: "Week 43", dates: "19 – 25 Oct")
        w.songs[0].title = "teeth"; w.songs[0].cover = Data([1]); w.vibeOverride = "Mine"; w.vibeSeed = 3
        let c = cleared(w)
        XCTAssertEqual(c.label, "Week 43"); XCTAssertEqual(c.dates, "19 – 25 Oct")
        XCTAssertEqual(c.songs.count, 6)
        XCTAssertTrue(c.songs.allSatisfy { $0.title.isEmpty && $0.cover == nil })
        XCTAssertNil(c.vibeOverride); XCTAssertNil(vibeLine(for: c))
    }
}

final class FrameTests: XCTestCase {
    func testOneFrameForEverySong() { XCTAssertEqual(frameWidth, 8); XCTAssertNotEqual(colour(hex: frameHex), RGB(r: 0.5, g: 0.5, b: 0.5)) }
    func testBackgroundIsAValidColour() { XCTAssertNotEqual(colour(hex: backgroundHex), RGB(r: 0.5, g: 0.5, b: 0.5)) }
}

final class ListParseTests: XCTestCase {
    func p(_ s: String) -> [Listed] { parseSongList(s) }
    func testDashByAndNumbering() {
        XCTAssertEqual(p("teeth - mallrat"), [Listed(title: "teeth", artist: "mallrat")])
        XCTAssertEqual(p("1. Horses by Mallrat"), [Listed(title: "Horses", artist: "Mallrat")])
        XCTAssertEqual(p("• Air – Surfing on a Rocket"), [Listed(title: "Air", artist: "Surfing on a Rocket")])  // order is Title - Artist
    }
    func testLastSeparatorWins() {
        XCTAssertEqual(p("Stand by Me - Ben E. King"), [Listed(title: "Stand by Me", artist: "Ben E. King")])
        XCTAssertEqual(p("American Woman - David Lynch Remix by Muddy Magnolias"),
                       [Listed(title: "American Woman - David Lynch Remix", artist: "Muddy Magnolias")])
    }
    func testBlankLinesQuotesAndTitleOnly() {
        XCTAssertEqual(p("\n\n\"Nude\" - Radiohead\n\nJust a title\n"), [Listed(title: "Nude", artist: "Radiohead"), Listed(title: "Just a title", artist: "")])
    }
    func testBufferCaptionRoundTrips() {
        var w = Week(label: "Week 43", dates: "d")
        let rows = [("teeth", "mallrat"), ("Pedestrian at Best", "Courtney Barnett"), ("American Woman David Lynch Remix", "Muddy Mangolias")]
        for (i, r) in rows.enumerated() { w.songs[i].title = r.0; w.songs[i].artist = r.1; w.songs[i].genre = "Pop" }
        XCTAssertEqual(parseSongList(caption(for: w)), rows.map { Listed(title: $0.0, artist: $0.1) })
    }
    func testLimitAndLongLines() {
        XCTAssertEqual(parseSongList((0..<30).map { "t\($0) - a" }.joined(separator: "\n")).count, 12)
        XCTAssertLessThanOrEqual(p(String(repeating: "x", count: 500))[0].title.count, 120)
    }
    func testPlaceFillsEmptySlotsSkipsDuplicatesAndReportsNoRoom() {
        var songs = (0..<6).map { _ in Song() }
        songs[0].title = "Teeth"; songs[0].artist = "Mallrat"
        let list = (["teeth - mallrat"] + (1...6).map { "s\($0) - a" }).map { parseSongList($0)[0] }
        let r = place(list, into: songs)
        XCTAssertEqual(r.added, 5); XCTAssertEqual(r.duplicates, 1); XCTAssertEqual(r.noRoom, 1)
        XCTAssertEqual(r.songs.map(\.title), ["Teeth", "s1", "s2", "s3", "s4", "s5"])
    }
}

private func + <K, V>(lhs: [K: V], rhs: [(K, V)]) -> [(K, V)] { Array(lhs.map { ($0.key, $0.value) }) + rhs }

final class FillMissingTests: XCTestCase {
    func testFillsOnlyWhatIsMissing() {
        var s = Song(); s.title = "t"
        let filled = fillMissing(s, genre: "Pop", album: "Album", cover: Data([1]))
        XCTAssertEqual(filled.genre, "Pop"); XCTAssertEqual(filled.album, "Album"); XCTAssertEqual(filled.cover, Data([1]))
    }
    func testNeverOverwritesWhatThePersonSet() {
        var s = Song(); s.title = "t"; s.genre = "Jazz"; s.album = "Mine"; s.cover = Data([9])
        let filled = fillMissing(s, genre: "Pop", album: "Album", cover: Data([1]))
        XCTAssertEqual(filled.genre, "Jazz"); XCTAssertEqual(filled.album, "Mine"); XCTAssertEqual(filled.cover, Data([9]))
    }
    func testEmptyResultsChangeNothing() {
        var s = Song(); s.title = "t"
        XCTAssertEqual(fillMissing(s, genre: "", album: nil, cover: nil), s)
        XCTAssertEqual(fillMissing(s, genre: "", album: "", cover: nil), s)
    }
}
