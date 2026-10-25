import AppKit

/// The menubar glyph: the app icon's sunrise record in one colour, as a template image so macOS tints it for the bar.
/// Drawn in the icon's 24-unit space (record radius 320 of 1024 -> 7.4), so the two stay in proportion.
enum MenuGlyph {
    static let image: NSImage = {
        let img = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.scaleBy(x: rect.width / 24, y: rect.width / 24)
            NSColor.black.set()
            let c = NSPoint(x: 12, y: 6)   // record centre, y up
            let record = NSBezierPath()
            record.appendArc(withCenter: c, radius: 7.4, startAngle: 0, endAngle: 180); record.close()
            record.appendArc(withCenter: c, radius: 2.8, startAngle: 0, endAngle: 180); record.close()
            record.windingRule = .evenOdd   // the label is cut out of the record
            record.fill()
            let marks = NSBezierPath()
            marks.lineWidth = 2; marks.lineCapStyle = .round
            marks.move(to: NSPoint(x: 2, y: 5.1)); marks.line(to: NSPoint(x: 22, y: 5.1))   // horizon
            for deg in [18.0, 54, 90, 126, 162] {
                let a = deg * .pi / 180
                marks.move(to: NSPoint(x: c.x + 9.48 * cos(a), y: c.y + 9.48 * sin(a)))
                marks.line(to: NSPoint(x: c.x + 11.33 * cos(a), y: c.y + 11.33 * sin(a)))
            }
            marks.stroke()
            return true
        }
        img.isTemplate = true
        return img
    }()
}
