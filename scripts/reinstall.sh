#!/bin/bash
# Quit Record Highs, rebuild, replace the copy in /Applications, reopen, and show the saved week.
set -euo pipefail
cd "$(dirname "$0")/.."

week_json="$HOME/Library/Containers/org.soundoftheweek.app/Data/Library/Application Support/week.json"
show() { python3 -c 'import json,sys; w=json.load(open(sys.argv[1])); print(w["label"], "|", w["dates"], "|", sum(1 for s in w["songs"] if s["title"]), "songs")' "$week_json"; }

before=$([ -f "$week_json" ] && show || echo "none")
echo "Before: $before"

osascript -e 'tell application "Record Highs" to quit' 2>/dev/null || true
sleep 1
make install
open "/Applications/Record Highs.app"
sleep 3

after=$(show)
echo "After:  $after"
[ "$before" != "$after" ] && echo "Week changed." || echo "Week unchanged: already current, or the new build did not run."
