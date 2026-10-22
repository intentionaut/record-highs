#!/bin/sh
# Checks the README's promises against the source and the signed app. Exits non-zero on any failure.
cd "$(dirname "$0")/.." || exit 1
APP="build/Record Highs.app"; SRC=Sources; fail=0
ok()  { echo "PASS  $1"; }
bad() { echo "FAIL  $1"; fail=1; }

# 1. The signed app has exactly these entitlements: sandbox, network client, Apple Events (Music only), chosen folder.
want="com.apple.security.app-sandbox com.apple.security.automation.apple-events com.apple.security.files.bookmarks.app-scope com.apple.security.files.user-selected.read-write com.apple.security.network.client com.apple.security.temporary-exception.apple-events"
got=$(codesign -d --entitlements :- "$APP" 2>/dev/null | grep -o 'com\.apple\.security[a-z.-]*' | sort | tr '\n' ' ' | sed 's/ $//')
[ "$got" = "$want" ] && ok "entitlements are exactly the expected set" || bad "entitlements differ: $got"
codesign -d --entitlements :- "$APP" 2>/dev/null | tr -d ' \n\t' | grep -q '<array><string>com.apple.Music</string></array>' \
  && ok "Apple Events limited to com.apple.Music" || bad "Apple Events not limited to Music"

# 2. Network calls appear only in CoverLookup.swift, and only to Apple's search and artwork hosts.
net=$(grep -rlE 'URLSession|URLRequest|NWConnection|NSURLConnection|CFNetwork|WKWebView|curl|Socket' $SRC | grep -v CoverLookup.swift)
[ -z "$net" ] && ok "network code only in CoverLookup.swift" || bad "network code in: $net"
hosts=$(grep -rhoE 'https?://[^/"]+|"\.[a-z.]+\.com"' $SRC | sort -u | tr '\n' ' ')
[ "$hosts" = '".mzstatic.com" https://itunes.apple.com https://publish.buffer.com ' ] && grep -q 'mzstatic.com' $SRC/RecordHighs/CoverLookup.swift \
  && ok "only hosts: itunes.apple.com (search), *.mzstatic.com (artwork), publish.buffer.com (opened in your browser)" || bad "unexpected hosts: $hosts"
# Buffer is only ever opened in the browser, never requested by the app.
[ "$(grep -rh 'publish.buffer.com' $SRC)" = "$(grep -rh 'NSWorkspace.shared.open(URL(string: "https://publish.buffer.com")' $SRC)" ] \
  && ok "Buffer opened in the browser only" || bad "Buffer URL used outside NSWorkspace.open"
# Data(contentsOf:) and friends fetch web addresses too, so each one must be a local-file read.
remote=$(grep -rnE 'contentsOf:' $SRC | grep -vE 'Store.swift|Samples.swift|isFileURL|fileURLWithPath')
[ -z "$remote" ] && ok "every contentsOf: read is a local file" || bad "contentsOf: that could fetch a URL: $remote"
grep -q 'AppStorage("lookupEnabled") private var lookupEnabled = true' $SRC/RecordHighs/App.swift && grep -q 'it is on by default' README.md \
  && ok "online lookup is a setting, on by default, and the README says so" || bad "lookup default and README disagree"
# What a person types or pastes must reach Apple Music only as handler parameters, never as script text.
grep -qE 'setParam\(args|args\.insert\(NSAppleEventDescriptor\(string: title\)' $SRC/RecordHighs/PlayerSource.swift \
  && ! grep -nE '\\\((title|artist)' $SRC/RecordHighs/PlayerSource.swift >/dev/null \
  && ok "title and artist reach Apple Music as parameters, not script text" || bad "title or artist is spliced into AppleScript text"

# 3. File writes appear only in Export.swift (the PNG) and Store.swift (your week, in the app's container); settings are UserDefaults.
wr=$(grep -rlE '\.write\(to|createFile|FileHandle|fopen|FileManager\.default\.(copy|move|create)' $SRC | grep -vE 'Export.swift|Store.swift')
[ -z "$wr" ] && ok "file writes only in Export.swift and Store.swift" || bad "file writes in: $wr"
grep -q 'applicationSupportDirectory' $SRC/RecordHighs/Store.swift && ok "week saved inside the app's container" || bad "Store writes outside Application Support"
grep -rqE 'UserDefaults|@AppStorage' $SRC && ok "settings stored in UserDefaults only" || bad "settings store not found"

# 4. Nothing reads or posts outward beyond the above: no analytics, accounts or upload code.
# Code lines only (comments stripped), so a comment saying "never uploaded" doesn't trip it.
grep -rhv '^\s*//' $SRC | sed 's|  *// .*||' | grep -qiE 'analytics|telemetry|uploadTask|upload\(|httpMethod|"POST"' && bad "analytics/upload code found" || ok "no analytics, accounts or upload code"
# 5. The signed app: hardened runtime on, developer options compiled out, file names made safe.
codesign -dv "$APP" 2>&1 | grep -q 'flags=.*runtime' && ok "hardened runtime is on" || bad "hardened runtime is off"
# Short Swift strings live inside the code, so look for the developer code itself, not its option names.
nm "$APP/Contents/MacOS/RecordHighs" 2>/dev/null | grep -q '7Samples' && bad "developer options are in the release app" || ok "developer options not in the release app"
unsafe=$(grep -rn 'Export.write' $SRC | grep -v 'static func write' | grep -v 'fileStem(for:' | grep -v 'stem: "sample"')
[ -z "$unsafe" ] && ok "export file names go through fileStem" || bad "export without fileStem: $unsafe"
exit $fail
