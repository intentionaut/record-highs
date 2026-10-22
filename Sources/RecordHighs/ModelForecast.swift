import Foundation
import RecordCore
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Writes the vibe line with the Mac's built-in language model, which Apple documents as running on the device.
/// It only exists on macOS 26 with Apple Intelligence turned on; everywhere else `isAvailable` is false and the
/// app's own forecast is all there is. Whatever the model writes goes through `tidyForecast` before it is used.
enum ModelForecast {
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
        }
        #endif
        return false
    }

    /// The line, tidied, or nil if the model wasn't available or wrote something unusable.
    static func write(for songs: [Song]) async throws -> String? {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            guard isAvailable else { return nil }
            let instructions = """
                You write one-sentence weather forecasts for the mood of a week of music. Use weather words such as \
                skies, fronts, showers, pressure and breeze, and give a percent chance of something playful a person \
                might do while listening. Write exactly one sentence of at most 25 words. Describe the weather only: \
                never address the reader, never say you, your, I or we, never use dashes, never use a list. Example: \
                Overcast and dreamy, 70% chance of staring out of windows.
                """
            let list = songs.filter { !$0.title.isEmpty }.enumerated().map { i, s in
                "\(i + 1). \(s.title)" + (s.artist.isEmpty ? "" : " by \(s.artist)") + (s.genre.isEmpty ? "" : " (\(s.genre))")
            }.joined(separator: "\n")
            let session = LanguageModelSession(instructions: instructions)
            let reply = try await session.respond(to: "This week's songs:\n\(list)\n\nWrite the forecast.")
            return tidyForecast(reply.content)
        }
        #endif
        return nil
    }
}
