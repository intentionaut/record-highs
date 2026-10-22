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
    func testFrameWidthClamps() {
        XCTAssertEqual(frameWidth(weight: -1), 2); XCTAssertEqual(frameWidth(weight: 2), 14); XCTAssertEqual(frameWidth(weight: 0.5), 8)
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
        w.songs[0].weight = 0.9; w.songs[0].cover = Data([1, 2, 3])
        XCTAssertEqual(try JSONDecoder().decode(Week.self, from: JSONEncoder().encode(w)), w)
    }
    func testCaptionSkipsEmptySongsAndHasNoEmDash() {
        var w = Week(label: "Week 43", dates: "19 – 25 Oct")
        w.songs[0].title = "Nude"; w.songs[0].artist = "Radiohead"; w.songs[2].title = "Untitled"
        XCTAssertEqual(caption(for: w), "My week in music, Week 43:\n1. Nude by Radiohead\n2. Untitled")
        XCTAssertFalse(caption(for: w).contains("—"))
    }
}

final class VibeTests: XCTestCase {
    func song(_ g: String, _ w: Double) -> Song { var s = Song(); s.genre = g; s.weight = w; return s }
    func testThisWeek() {
        let week = [song("Pop", 0.5), song("Alternative", 0.5), song("Pop", 0.48),
                    song("Alternative", 0.5), song("Electronica", 0.5), song("Soundtrack", 0.5)]
        XCTAssertEqual(vibe(for: week), "Overcast and dreamy, 70% chance of staring out of windows.")
    }
    func testSingleGenreUsesItsOwnFeel() { XCTAssertEqual(vibe(for: [song("Jazz", 1)]), "Low cloud and smoky, 100% chance of lingering over coffee.") }
    func testNoKnownGenreGivesNoVibe() { XCTAssertNil(vibe(for: [song("", 1), song("Polka", 1)])) }
    func testOneSentenceNoEmDash() {
        for g in weather.keys { let v = vibe(for: [song(g, 1)])!; XCTAssertFalse(v.contains("—")); XCTAssertEqual(v.filter { $0 == "." }.count, 1, g) }
    }
}

final class AltTextTests: XCTestCase {
    func week() -> Week {
        var w = Week(label: "Week 43", dates: "19 Oct – 25 Oct")
        let rows = [("teeth", "mallrat", "Pop", 0.5), ("Horses", "Mallrat", "Alternative", 0.9)]
        for (i, r) in rows.enumerated() { w.songs[i].title = r.0; w.songs[i].artist = r.1; w.songs[i].genre = r.2; w.songs[i].weight = r.3 }
        w.songs[1].album = "Butterfly Blue"
        return w
    }
    func testCoversEveryWordOnThePoster() {
        let alt = altText(for: week(), name: "Elle")
        for word in ["Record Highs", "Week 43", "19 Oct – 25 Oct", "Elle", "Vibe: " + vibeLine(for: week())!,
                     "1. teeth by mallrat.", "2. Horses by Mallrat, cover of the album Butterfly Blue.", "thickest frame is around Horses"] {
            XCTAssertTrue(alt.contains(word), word)
        }
        XCTAssertFalse(alt.contains("—"))
    }
    func testNoNameNoSongs() {
        XCTAssertEqual(altText(for: Week(label: "Week 1", dates: "1 – 7 Jan"), name: ""), "Record Highs poster. Week 1, 1 – 7 Jan.")
    }
    func testCaptionEndsWithVibe() {
        XCTAssertEqual(caption(for: week()), "My week in music, Week 43:\n1. teeth by mallrat\n2. Horses by Mallrat\nVibe: " + String(vibeLine(for: week())!.dropLast()))
    }
    func testOldSaveWithoutAlbumStillLoads() throws {
        let old = #"{"label":"W","dates":"d","songs":[{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","title":"t","artist":"a","genre":"Pop","weight":0.5}]}"#
        XCTAssertNil(try JSONDecoder().decode(Week.self, from: Data(old.utf8)).songs[0].album)
    }
}

final class SongOfTheWeekTests: XCTestCase {
    func testNearTieNamesNoSong() {
        var w = Week(label: "W", dates: "d")
        for i in 0..<3 { w.songs[i].title = "s\(i)"; w.songs[i].weight = i == 2 ? 0.48 : 0.5 }
        XCTAssertFalse(altText(for: w, name: "").contains("thickest"))
    }
}

final class VibeEditTests: XCTestCase {
    func week() -> Week {
        var w = Week(label: "W", dates: "d")
        for (i, g) in ["Pop", "Alternative", "Pop", "Alternative", "Electronica", "Soundtrack"].enumerated() {
            w.songs[i].title = "s\(i)"; w.songs[i].genre = g; w.songs[i].weight = i == 2 ? 0.48 : 0.5
        }
        return w
    }
    func testYourWordsWinEverywhere() {
        var w = week(); w.vibeOverride = "Sunny with a chance of Mallrat."
        XCTAssertEqual(vibeLine(for: w), "Sunny with a chance of Mallrat.")
        XCTAssertTrue(caption(for: w).hasSuffix("\nVibe: Sunny with a chance of Mallrat"))
        XCTAssertTrue(altText(for: w, name: "").contains("Vibe: Sunny with a chance of Mallrat."))
    }
    func testBlankEditFallsBackToForecast() {
        var w = week(); w.vibeOverride = "  "
        XCTAssertEqual(vibeLine(for: w), "Overcast and dreamy, 70% chance of staring out of windows.")
    }
    func testRegenerateGivesNewWordingAndCycles() {
        let lines = (0..<12).map { vibe(for: week().songs, seed: $0)! }
        XCTAssertEqual(Set(lines).count, 12)
        for l in lines { XCTAssertFalse(l.contains("—")); XCTAssertTrue(l.hasSuffix(".")) }
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
    func testWeightsRunThickToThin() {
        XCTAssertEqual(weightForRank(0, of: 6), 0.8, accuracy: 1e-9)
        XCTAssertEqual(weightForRank(5, of: 6), 0.2, accuracy: 1e-9)
        XCTAssertEqual(weightForRank(0, of: 1), 0.8)
    }
}
