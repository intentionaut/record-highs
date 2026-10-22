import Foundation

/// The only network code in the app. Off by default; runs once per "Find cover" press.
/// It sends the title and artist to the iTunes Search API, then downloads the artwork it names.
/// The genre comes from the same search result, so it costs no extra request.
enum CoverLookup {
    static func find(title: String, artist: String) async throws -> (cover: Data, genre: String, album: String?) {
        var q = URLComponents(string: "https://itunes.apple.com/search")!
        q.queryItems = [.init(name: "term", value: "\(artist) \(title)"), .init(name: "entity", value: "song"), .init(name: "limit", value: "1")]
        struct Result: Decodable { let results: [Item]; struct Item: Decodable { let artworkUrl100: String; let primaryGenreName: String?; let collectionName: String? } }
        let (body, _) = try await URLSession.shared.data(from: q.url!)
        guard let item = try JSONDecoder().decode(Result.self, from: body).results.first,
              let small = Optional(item.artworkUrl100),
              let big = URL(string: small.replacingOccurrences(of: "100x100", with: "600x600")),
              big.host?.hasSuffix(".mzstatic.com") == true
        else { throw PlayerError(errorDescription: "No cover found.") }
        return (try await URLSession.shared.data(from: big).0, item.primaryGenreName ?? "", item.collectionName)
    }
}
