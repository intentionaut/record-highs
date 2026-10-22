#if DEBUG   // developer-only; not in the release app
import SwiftUI
import RecordCore

/// Sample posters with flat placeholder covers, so no real album art ships in the repo.
@MainActor enum Samples {
    static let tracks = [("Low Tide", "The Harbour Lights"), ("Paper Planes Home", "Mira Vale"), ("Night Bus", "Ostrich Club"),
                         ("Sunday Static", "Juniper & Co"), ("Glass Hours", "Teo Marsh"), ("Run It Back", "The Long Field")]

    static func render(into dir: URL) {
        let songs = tracks.enumerated().map { i, t -> Song in
            var s = Song(); s.title = t.0; s.artist = t.1
            s.genre = ["Alternative", "Pop", "Alternative", "Electronica", "Pop", "Soundtrack"][i]
            let r = ImageRenderer(content: Color(hue: Double(i) / 6, saturation: 0.25, brightness: 0.75).frame(width: 300, height: 300))
            s.cover = r.cgImage.flatMap { NSBitmapImageRep(cgImage: $0).representation(using: .png, properties: [:]) }
            return s
        }
        do {
            let poster = PosterView(songs: songs, week: "Week 43", dates: "19 – 25 Oct", name: "Sample", vibe: vibe(for: songs), size: .portrait)
            print(try Export.write(poster, to: dir, stem: "sample").path)
        } catch { print(error.localizedDescription); exit(1) }
    }

    static func render(week path: String, into dir: String, name: String) {
        do {
            let w = try JSONDecoder().decode(Week.self, from: Data(contentsOf: URL(fileURLWithPath: path)))
            let poster = PosterView(songs: w.songs, week: w.label, dates: w.dates, name: name, vibe: vibeLine(for: w), size: .portrait)
            print(try Export.write(poster, to: URL(fileURLWithPath: dir), stem: fileStem(for: w.label)).path)
        } catch { print(error.localizedDescription); exit(1) }
    }

    /// `swift run RecordHighs --lookup <title> <artist>` prints what the Apple Music library says about a song.
    static func lookup(title: String, artist: String) {
        if let m = AppleMusicSource().libraryMatch(title: title, artist: artist) {
            print("FOUND | \(m.title) | \(m.artist) | \(m.album) | \(m.genre) | artwork \(m.artwork?.count ?? 0) bytes")
        } else { print("NOT FOUND") }
    }
}
#endif
