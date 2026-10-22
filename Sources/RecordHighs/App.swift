import SwiftUI
import RecordCore
import UniformTypeIdentifiers

@main struct RecordHighsApp: App {
    init() {
        #if DEBUG   // developer options; compiled out of the release app that `make app` builds
        let args = CommandLine.arguments
        // `swift run RecordHighs --samples <dir>` renders the sample poster and quits
        if let i = args.firstIndex(of: "--samples"), i + 1 < args.count { Samples.render(into: URL(fileURLWithPath: args[i + 1])); exit(0) }
        // `swift run RecordHighs --render <week.json> <dir> [name]` prints a saved week as a PNG and quits
        if let i = args.firstIndex(of: "--render"), i + 2 < args.count { Samples.render(week: args[i + 1], into: args[i + 2], name: i + 3 < args.count ? args[i + 3] : ""); exit(0) }
        #endif
    }
    var body: some Scene { WindowGroup("Record Highs") { EditorView().navigationSubtitle("Your week in music, as a weather report.") } }
}

struct EditorView: View {
    @State private var w = Store.load()
        ?? Week(label: "Week \(Calendar.current.component(.weekOfYear, from: .now))", dates: EditorView.thisWeek())
    @AppStorage("name") private var name = ""
    @AppStorage("lookupEnabled") private var lookupEnabled = false
    @AppStorage("exportFolder") private var folderBookmark = Data()
    @State private var status = ""
    @State private var edits = 0
    @State private var confirmClear = false
    @State private var showPaste = false
    @State private var pasted = ""
    @State private var beforeClear: Week?     // one level of undo for Clear all             // bumps on every change; the PNG autosaves a moment after the last one
    private let player: PlayerSource = AppleMusicSource()

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Form {
                Section {
                    HStack {
                        Button("Fill from my week", action: fillFromWeek).buttonStyle(.borderedProminent)
                            .disabled(!hasEmptySlot)
                            .accessibilityHint("Fills the empty song slots from what you played this week. Nothing leaves your Mac.")
                        Button("Add now playing", action: addNowPlaying).disabled(!hasEmptySlot)
                            .accessibilityHint("Puts the track playing in \(player.name) into the first empty slot")
                        Button("Paste a list…") { showPaste = true }.disabled(!hasEmptySlot)
                            .accessibilityHint("Opens a box to paste song titles and artists, one per line")
                    }
                } header: { Text("Add songs") } footer: {
                    Text("\(player.name) only logs plays of songs in your library, so for streamed songs or Shazams use Paste a list. Only empty slots are filled, and nothing leaves your Mac.")
                }
                ForEach(w.songs.indices, id: \.self) { i in slot($w.songs[i], number: i + 1) }
                Section("Poster") {
                    TextField("Week", text: $w.label, prompt: Text("Week 43"))
                    TextField("Dates", text: $w.dates, prompt: Text("19 – 25 Oct"))
                    TextField("Your name", text: $name, prompt: Text("Optional"))
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Vibe", text: Binding(get: { vibeLine(for: w) ?? "" }, set: { w.vibeOverride = $0 }),
                                  prompt: Text("Add songs for a forecast"), axis: .vertical)
                            .lineLimit(1...3)
                        HStack {
                            Text(w.vibeOverride == nil ? "Forecast from your songs" : "Your words").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Button("Regenerate") { w.vibeOverride = nil; w.vibeSeed = (w.vibeSeed ?? 0) + 1 }
                                .controlSize(.small).accessibilityHint("Replaces the vibe line with a new forecast from your songs")
                        }
                    }
                }
                Section("Settings") {
                    Toggle(isOn: $lookupEnabled) {
                        Text("Allow Find cover")
                        Text("Sends a song's title and artist to the iTunes Search API, once per press.")
                    }
                    HStack {
                        Button("Clear all songs…", role: .destructive) { confirmClear = true }
                            .disabled(w.songs.allSatisfy { $0.title.isEmpty && $0.cover == nil })
                        Spacer()
                        if let before = beforeClear {
                            Button("Undo clear") { w = before; beforeClear = nil; status = "Songs restored." }
                        }
                    }
                }
                .confirmationDialog("Clear all six songs?", isPresented: $confirmClear) {
                    Button("Clear all songs", role: .destructive) {
                        beforeClear = w; w = cleared(w); status = "Cleared. Press Undo clear to bring them back."
                    }
                } message: { Text("Titles, artists, covers and your vibe line go. The week, dates and your name stay.") }
            }
            .formStyle(.grouped).frame(width: 420)
            VStack(spacing: 12) {
                // Lay out at full size, then shrink: scaleEffect alone doesn't change the space a view takes.
                poster
                    .scaleEffect(0.45, anchor: .topLeading)
                    .frame(width: 1080 * 0.45, height: 1350 * 0.45, alignment: .topLeading)
                    .clipShape(RoundedRectangle(cornerRadius: 6)).shadow(radius: 8, y: 2)
                Text(status).foregroundStyle(.secondary).lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Button(folderName.map { "Saving to \($0)" } ?? "Choose save folder…", action: chooseFolder)
                    Spacer()
                    Button("Copy alt text") { Export.copy(altText(for: w, name: name)); status = "Alt text copied. Paste it into Buffer's image description." }
                    Button("Open Buffer", action: openBuffer).keyboardShortcut("e").buttonStyle(.borderedProminent)
                }
            }
            .padding(20).frame(width: 1080 * 0.45 + 40)
        }
        .frame(minHeight: 1350 * 0.45 + 80)
        .sheet(isPresented: $showPaste) { pasteSheet }
        .onChange(of: w) { Store.save(w); edits += 1 }
        .onChange(of: name) { edits += 1 }
        .task(id: edits) {
            guard edits > 0, (try? await Task.sleep(for: .seconds(1.5))) != nil else { return }
            if let f = try? savePNG() { status = "Autosaved \(f.lastPathComponent)" }
        }
    }

    var poster: PosterView { PosterView(songs: w.songs, week: w.label, dates: w.dates, name: name, vibe: vibeLine(for: w), size: .portrait) }

    func slot(_ song: Binding<Song>, number: Int) -> some View {
        Section("Song \(number)") {
            HStack(spacing: 12) {
                Group {
                    if let d = song.wrappedValue.cover, let img = NSImage(data: d) { Image(nsImage: img).resizable().scaledToFill() }
                    else { RoundedRectangle(cornerRadius: 4).strokeBorder(style: .init(lineWidth: 1, dash: [4])).overlay(Text("Drop\ncover").font(.caption)) }
                }
                .frame(width: 56, height: 56).clipped().foregroundStyle(.secondary)
                .accessibilityElement().accessibilityLabel(song.wrappedValue.cover == nil ? "No cover for song \(number). Drop an image here." : "Cover for song \(number)")
                .dropDestination(for: URL.self) { urls, _ in   // local files only, so a link dragged from a browser is never fetched
                    guard let d = urls.first(where: \.isFileURL).flatMap({ try? Data(contentsOf: $0) }), NSImage(data: d) != nil else { return false }
                    song.wrappedValue.cover = d; return true
                }
                VStack {
                    TextField("Title", text: song.title, prompt: Text("Title")).labelsHidden()
                    TextField("Artist", text: song.artist, prompt: Text("Artist")).labelsHidden()
                }
                .textFieldStyle(.roundedBorder)
            }
            if lookupEnabled {
                HStack {
                    Spacer()
                    Button("Find cover") { find(song) }.disabled(song.wrappedValue.title.isEmpty).controlSize(.small)
                }
            }
        }
    }

    var pasteSheet: some View {
        let found = parseSongList(pasted).count, free = w.songs.filter { $0.title.isEmpty }.count
        return VStack(alignment: .leading, spacing: 12) {
            Text("Paste a list").font(.headline)
            Text("One song per line, as Title - Artist or Title by Artist. Numbers are fine. Only empty slots are filled.")
                .font(.callout).foregroundStyle(.secondary)
            TextEditor(text: $pasted).font(.body).frame(minHeight: 170)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.separator))
                .accessibilityLabel("Songs to add, one per line")
            Text("\(count(found, "song")) found, \(count(free, "empty slot"))").font(.caption).foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Cancel") { showPaste = false; pasted = "" }.keyboardShortcut(.cancelAction)
                Button("Add songs", action: addPasted).keyboardShortcut(.defaultAction).disabled(found == 0)
            }
        }
        .padding(20).frame(width: 440)
    }

    func count(_ n: Int, _ noun: String) -> String { "\(n) \(noun)\(n == 1 ? "" : "s")" }

    func addPasted() {
        let r = place(parseSongList(pasted), into: w.songs)
        w.songs = r.songs
        status = "Added \(count(r.added, "song"))." + (r.duplicates > 0 ? " \(r.duplicates) already on the week." : "")
            + (r.noRoom > 0 ? " \(r.noRoom) didn't fit." : "")
            + (lookupEnabled ? " Press Find cover on each for artwork." : " Drop images on the slots, or turn on Find cover in Settings.")
        pasted = ""; showPaste = false
    }

    var hasEmptySlot: Bool { w.songs.contains { $0.title.isEmpty } }

    func addNowPlaying() {
        guard let i = w.songs.firstIndex(where: { $0.title.isEmpty }) else { return }
        fromPlayer($w.songs[i])
    }

    func fromPlayer(_ song: Binding<Song>) {
        do {
            let now = try player.nowPlaying()
            song.wrappedValue.title = now.title; song.wrappedValue.artist = now.artist; song.wrappedValue.genre = now.genre; song.wrappedValue.album = now.album
            if let art = now.artwork { song.wrappedValue.cover = art }
            status = "From \(player.name): \(now.album)"
        } catch { status = error.localizedDescription }
    }

    func fillFromWeek() {
        status = "Reading this week from \(player.name)…"
        do {
            let empty = w.songs.indices.filter { w.songs[$0].title.isEmpty }
            let picks = pickForWeek(try player.recent(since: .now.addingTimeInterval(-7 * 86_400)), existing: w.songs, free: empty.count)
            for (slot, pick) in zip(empty, picks) {
                w.songs[slot].title = pick.title; w.songs[slot].artist = pick.artist
                w.songs[slot].album = pick.album; w.songs[slot].genre = pick.genre
                w.songs[slot].cover = player.artwork(id: pick.id)
            }
            let shazams = picks.filter { $0.source == .shazam }.count
            let latest = picks.filter { $0.source == .played }.map(\.when).max()
            let day = DateFormatter(); day.dateFormat = "d MMM"
            status = picks.isEmpty ? "Nothing new in \(player.name) this week. It only logs songs in your library, so try Paste a list."
                : "Filled \(picks.count) from \(player.name)" + (latest.map { " (latest play \(day.string(from: $0)))" } ?? "")
                + (shazams > 0 ? ", \(shazams) from Shazam" : "") + "."
        } catch { status = error.localizedDescription }
    }

    func find(_ song: Binding<Song>) {
        let s = song.wrappedValue
        Task {
            do {
                let found = try await CoverLookup.find(title: s.title, artist: s.artist)
                song.wrappedValue.cover = found.cover
                if !found.genre.isEmpty { song.wrappedValue.genre = found.genre }
                if let a = found.album { song.wrappedValue.album = a }
                status = "Cover found."
            }
            catch { status = error.localizedDescription }
        }
    }

    var folder: URL? {
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: folderBookmark, options: .withSecurityScope, bookmarkDataIsStale: &stale) else { return nil }
        if stale, url.startAccessingSecurityScopedResource() {   // folder moved or renamed: refresh the link so autosave keeps working
            defer { url.stopAccessingSecurityScopedResource() }
            if let fresh = try? url.bookmarkData(options: .withSecurityScope) { DispatchQueue.main.async { folderBookmark = fresh } }
        }
        return url
    }
    var folderName: String? { folderBookmark.isEmpty ? nil : folder?.lastPathComponent }

    func chooseFolder() {
        let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.prompt = "Save posters here"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        folderBookmark = (try? url.bookmarkData(options: .withSecurityScope)) ?? Data()
        if let f = try? savePNG() { status = "Saved \(f.lastPathComponent)" }
    }

    /// Writes this week's PNG into the chosen folder, replacing the previous save of the same week.
    func savePNG() throws -> URL {
        guard let folder, folder.startAccessingSecurityScopedResource() else { throw PlayerError(errorDescription: "Choose a save folder first.") }
        defer { folder.stopAccessingSecurityScopedResource() }
        return try Export.write(poster, to: folder, stem: fileStem(for: w.label))
    }

    func openBuffer() {
        if folder == nil { chooseFolder() }
        do {
            Export.handOffToBuffer(try savePNG(), caption: caption(for: w))
            status = "Caption copied and Buffer opened. Drag the PNG in, paste, then Copy alt text for the image description."
        } catch { status = error.localizedDescription }
    }

    static func thisWeek() -> String {
        let cal = Calendar.current, f = DateFormatter(); f.dateFormat = "d MMM"
        guard let w = cal.dateInterval(of: .weekOfYear, for: .now) else { return "" }
        return "\(f.string(from: w.start)) – \(f.string(from: w.end.addingTimeInterval(-1)))"
    }
}
