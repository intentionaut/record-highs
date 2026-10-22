<p align="center"><img src="assets/logo.svg" width="320" alt="Record Highs: a vinyl record rising over a horizon like a sunrise, above the words Record Highs"></p>

# Record Highs

*Your week in music, as a weather report.*

A small macOS app by [Saielle DaSilva](https://intentionaut.com) that turns six songs into a weekly music recap: a 3x2 grid of album covers, a one-line vibe forecast worked out from their genres, and the week's dates. It exports a 1080x1350 PNG for Instagram, LinkedIn or Bluesky, with the post text and alt text ready to paste into Buffer. It never posts for you.

Built in Swift and SwiftUI for macOS 14 and later, with no dependencies. Apple Music is the only player in v1; other players are a later item.

![A sample Record Highs poster](samples/sample.png)

## Commands

| Command | What it does |
| --- | --- |
| `make app` | Builds `build/Record Highs.app` |
| `make install` | Copies the app to `/Applications` |
| `make test` | Runs the unit tests (vibe, layout, alt text, saving) |
| `make check` | Builds, then checks the promises below |
| `make samples` | Redraws the sample poster with placeholder covers |
| `make icon` | Redraws `AppIcon.icns` from `assets/icon.svg` (needs `rsvg-convert`) |

## Using it

- **Start from Apple Music.** At the top, **Fill from my week** fills the empty slots with your most played tracks of the last 7 days, then your Shazams (if Shazam saves to Apple Music). **Add now playing** puts the current track in the first empty slot. Library tracks only, and nothing leaves your Mac.
- **Paste a list.** One song per line, as `Title - Artist` or `Title by Artist`, numbered or not. It works from any source, including a Shazam history or a Buffer caption from an earlier week. The covers, albums and genres fill in by themselves: first from your Apple Music library on this Mac, then, with the lookup switch on (it is on by default), from Apple's public search.
- **Or add songs by hand.** Type a title and artist and press **Find cover** to look one up, or drag an image onto the slot.
- **Read the vibe.** A one-line forecast worked out from your songs' genres, such as "Mostly overcast, brooding later on, 70% chance of staring out of windows." The 109 genre names Apple Music uses are grouped into 18 families, each with its own skies, feelings and activities, and the wording changes from week to week. A week with five genres reads "changeable", an artist who appears twice can get named, and the chance is out of all your songs, so a song without a genre lowers it. Type over the line, or press **Regenerate** for another; there are hundreds of combinations.
- **Post it.** Choose a save folder once and the PNG saves itself after each change. **Open Buffer** copies the post text and opens Buffer in your browser; **Copy alt text** gives you an image description that covers every word on the poster.

Everything you enter is saved as you go, so quitting loses nothing. **Clear all songs** starts the six slots afresh (with one Undo); the week, dates and your name stay.

## Layout

- `Sources/RecordCore/` - the parts with no UI: vibe forecast, grid layout, post text, alt text
- `Sources/RecordCore/Style.swift` - background and frame colours, frame thickness, and the weather words for each genre family; edit this to change the wording
- `Sources/RecordCore/Forecast.swift` - how a week becomes a forecast: the sentence shapes and the stable choice of words
- `Sources/RecordHighs/` - the app: editor, poster, Apple Music, cover lookup, export
- `Tests/RecordCoreTests/` - unit tests
- `scripts/check-promises.sh` - the promise checks
- `assets/` - the logo and app icon (SVG); the lettering is outlined from Jost, which is under the SIL Open Font License
- `samples/` - the sample poster

## Promises

Record Highs is built to get you to a finished poster with as little effort as possible, so it looks things up for you. These promises say exactly what it does, and what it never does. Each is checked by `scripts/check-promises.sh`, which searches the source and inspects the signed app, so it is evidence rather than proof. The macOS sandbox and hardened runtime are what enforce them while the app runs.

- **It looks songs up for you, and says how.** For each song you add, it checks your Apple Music library on this Mac first. If the cover or genre is still missing and **Look up covers and genres online** is on (it is on by default, and you can turn it off in Settings), it asks Apple's public search (`itunes.apple.com`) with the song's title and artist, then downloads the cover it names from `*.mzstatic.com`. That is one request per song plus the image. *Check:* network code exists only in `CoverLookup.swift`, those are the only hosts, the switch exists and defaults to on.
- **Nothing else leaves your Mac.** No accounts, no analytics, no uploads, and never your poster, your week, your name or your covers. A cover you drop on a slot must be a file on your Mac; a link dragged from a browser is ignored, not fetched. *Check:* no analytics, telemetry, upload or POST code in the source, and every `contentsOf:` read is a local file.
- **Apple Music is read, never changed, and what you type never becomes a script.** The Apple Events entitlement is limited to `com.apple.Music`, and a song's title and artist go to Apple Music as parameters, not as part of the script's text, so nothing pasted into the app can run as a command. *Check:* the signed app's exception names Music and nothing else, and no title or artist is spliced into script text.
- **Nothing is written except your poster, your week and settings.** The app can write only to the folder you choose and its own container. File names are made from the week label's letters and digits only, so a label can't point outside the folder. *Check:* file writes exist only in `Export.swift` and `Store.swift`, and every export name goes through `fileStem`.
- **No way in for other code.** The app is signed with the hardened runtime, and the developer options (`--samples`, `--render`, `--lookup`) exist only in debug builds. *Check:* the signature carries the runtime flag, and the release app contains no developer code.
- **Buffer is opened, never contacted.** *Check:* `publish.buffer.com` appears only in a call that opens your browser.

## Who made it

Record Highs is made by Saielle DaSilva at [Intentionaut](https://intentionaut.com): product, design, data and AI.

## Support

Record Highs is free to use for non-commercial purposes. Tips go toward the time I spend building and maintaining it: [ko-fi.com/intentionaut](https://ko-fi.com/intentionaut)

## License

Source available for non-commercial use.

- **Code:** [PolyForm Noncommercial 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0). Use it, change it and share it for anything that isn't commercial. See `LICENSE`.
- **Sample poster and docs:** [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). Credit Saielle DaSilva, non-commercial, share alike. See `LICENSE-CONTENT.md`.

For commercial use, get in touch through [intentionaut.com](https://intentionaut.com).
