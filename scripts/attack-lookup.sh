#!/bin/sh
# Tries to run a command by pasting AppleScript into a song title or artist. Run it on a Mac with the Music app;
# it opens Music if it is not running. Passes if none of the payloads creates its marker file.
cd "$(dirname "$0")/.." || exit 1
M=$(mktemp -d); fail=0
look() { swift run RecordHighs --lookup "$1" "$2" >/dev/null 2>&1; }
look "x\" & (do shell script \"touch $M/one\") & \"" "a"
look "Apocalypse" "z\" & (do shell script \"touch $M/two\") & \""
look "x\"
end tell
do shell script \"touch $M/three\"
tell application \"Music\" to \"" "a"
for f in one two three; do [ -e "$M/$f" ] && { echo "FAIL  payload $f ran as AppleScript"; fail=1; }; done
[ $fail = 0 ] && echo "PASS  no pasted text ran as AppleScript"
# Control: splicing the same text into a script does run it, so a pass above means something.
osascript -e "set t to \"x\" & (do shell script \"touch $M/control\") & \"\"" >/dev/null 2>&1
[ -e "$M/control" ] && echo "PASS  control: spliced text does run, so the test can fail" || { echo "FAIL  control did not run"; fail=1; }
rm -rf "$M"; exit $fail
