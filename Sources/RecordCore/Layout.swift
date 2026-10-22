import CoreGraphics

public enum PosterSize: CaseIterable {
    case portrait, square
    public var pixels: CGSize { self == .portrait ? CGSize(width: 1080, height: 1350) : CGSize(width: 1080, height: 1080) }
    public var name: String { self == .portrait ? "1080x1350" : "1080x1080" }
}

public struct Cell: Equatable { public let cover: CGRect; public let caption: CGRect }

/// 3 columns x 2 rows under a header band. Covers are square and centred in each cell.
public func gridLayout(_ size: PosterSize, margin: CGFloat = 48, gap: CGFloat = 32) -> (header: CGRect, cells: [Cell]) {
    let s = size.pixels
    let headerH: CGFloat = 270   // room for a three-line vibe at 30pt
    let captionH: CGFloat = 94   // two-line title plus artist
    let colW = (s.width - 2 * margin - 2 * gap) / 3
    let rowH = (s.height - 2 * margin - headerH - 2 * gap) / 2
    let side = min(colW, rowH - captionH)
    // Centre header and grid together in whatever height is left over.
    let slack = s.height - 2 * margin - headerH - gap - 2 * (side + captionH) - gap
    let header = CGRect(x: margin, y: margin + slack / 2, width: s.width - 2 * margin, height: headerH)
    let top = header.maxY + gap
    var cells: [Cell] = []
    for row in 0..<2 {
        for col in 0..<3 {
            let x = margin + CGFloat(col) * (colW + gap) + (colW - side) / 2
            let y = top + CGFloat(row) * (side + captionH + gap)
            cells.append(Cell(cover: CGRect(x: x, y: y, width: side, height: side),
                              caption: CGRect(x: x, y: y + side + 8, width: side, height: captionH - 8)))
        }
    }
    return (header, cells)
}
