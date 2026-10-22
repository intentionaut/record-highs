import SwiftUI
import RecordCore

enum Export {
    /// Renders the 1080x1350 poster at 1x and writes one PNG into `folder`.
    @MainActor static func write(_ poster: PosterView, to folder: URL, stem: String) throws -> URL {
        let r = ImageRenderer(content: poster); r.scale = 1
        guard let cg = r.cgImage,
              let png = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])
        else { throw PlayerError(errorDescription: "Couldn't render the poster.") }
        let url = folder.appendingPathComponent("\(stem).png")
        try png.write(to: url)
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
