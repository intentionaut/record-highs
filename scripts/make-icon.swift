// Draws the app icon: six framed squares on a warm grey tile. Run by `make icon`.
import AppKit
let size = 1024.0, img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()
NSColor(white: 0.96, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 180, yRadius: 180).fill()
let hues = [0.0, 0.12, 0.33, 0.5, 0.66, 0.83]
for (i, h) in hues.enumerated() {
    let r = NSRect(x: 200 + Double(i % 3) * 215, y: 540 - Double(i / 3) * 255, width: 190, height: 190)
    NSColor(white: 0.12, alpha: 1).setFill(); NSBezierPath(rect: r).fill()
    NSColor(hue: h, saturation: 0.35, brightness: 0.8, alpha: 1).setFill(); NSBezierPath(rect: r.insetBy(dx: 10 + Double(i) * 3, dy: 10 + Double(i) * 3)).fill()
}
img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
