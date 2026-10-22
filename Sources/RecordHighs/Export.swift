import SwiftUI
import RecordCore

enum Export {
    /// Renders any view at 1x and writes it as a PNG at `url`. The only place the app writes an image.
    @MainActor static func save<V: View>(_ view: V, to url: URL) throws {
        let r = ImageRenderer(content: view); r.scale = 1
        guard let cg = r.cgImage,
              let png = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])
        else { throw PlayerError(errorDescription: "Couldn't render the image.") }
        try png.write(to: url)
    }

    /// Renders the 1080x1350 poster and writes one PNG into `folder`.
    @MainActor static func write(_ poster: PosterView, to folder: URL, stem: String) throws -> URL {
        let url = folder.appendingPathComponent("\(stem).png")
        try save(poster, to: url)
        return url
    }

    /// Hands off to Buffer without posting: shows the PNG in Finder, copies the caption, opens Buffer in the browser.
    /// The browser makes that request, not this app.
    static func handOffToBuffer(_ file: URL, caption: String) {
        NSWorkspace.shared.activateFileViewerSelecting([file])
        copy(caption)
        NSWorkspace.shared.open(URL(string: "https://publish.buffer.com")!)
    }

    static func copy(_ text: String) { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(text, forType: .string) }
}
