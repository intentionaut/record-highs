import SwiftUI
import RecordCore

struct PosterView: View {
    let songs: [Song], week: String, dates: String, name: String, vibe: String?, size: PosterSize
    var ground: String = backgroundHex   // the flat background colour

    var body: some View {
        let (header, cells) = gridLayout(size)
        ZStack(alignment: .topLeading) {
            { let c = colour(hex: ground); return Color(red: c.r, green: c.g, blue: c.b) }()
            VStack(alignment: .leading, spacing: 6) {
                Text("RECORD HIGHS").font(.system(size: 26, weight: .semibold)).kerning(4).foregroundStyle(.secondary)
                Text(week).font(.system(size: size == .portrait ? 64 : 52, weight: .bold))
                Text(name.isEmpty ? dates : "\(dates) · \(name)").font(.system(size: 26)).foregroundStyle(.secondary)
                if let v = vibe { Text("Vibe: \(v)").font(.system(size: 30).italic()).lineLimit(3).fixedSize(horizontal: false, vertical: true) }
            }
            .frame(width: header.width, height: header.height, alignment: .bottomLeading)
            .offset(x: header.minX, y: header.minY)
            ForEach(Array(zip(songs.prefix(6), cells)), id: \.0.id) { song, cell in
                let c = colour(hex: frameHex)
                cover(song).frame(width: cell.cover.width, height: cell.cover.height).clipped()
                    .overlay(Rectangle().strokeBorder(Color(red: c.r, green: c.g, blue: c.b), lineWidth: frameWidth))
                    .offset(x: cell.cover.minX, y: cell.cover.minY)
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title).font(.system(size: 24, weight: .semibold)).lineLimit(2)
                    Text(song.artist).font(.system(size: 20)).foregroundStyle(.secondary).lineLimit(1)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: cell.caption.width, alignment: .topLeading)
                .offset(x: cell.caption.minX, y: cell.caption.minY)
            }
        }
        .foregroundStyle(.black)
        .frame(width: size.pixels.width, height: size.pixels.height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(altText(for: { var w = Week(label: week, dates: dates, songs: songs); w.vibeOverride = vibe ?? ""; return w }(), name: name))
    }

    @ViewBuilder func cover(_ song: Song) -> some View {
        if let d = song.cover, let img = NSImage(data: d) { Image(nsImage: img).resizable().scaledToFill() }
        else { Color(white: 0.85) }
    }
}
