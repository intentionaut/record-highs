APP = build/Record Highs.app

.PHONY: app test samples check icon install

app:
	swift build -c release
	rm -rf "$(APP)" && mkdir -p "$(APP)/Contents/MacOS"
	cp Info.plist "$(APP)/Contents/"
	mkdir -p "$(APP)/Contents/Resources" && cp AppIcon.icns "$(APP)/Contents/Resources/"
	cp .build/release/RecordHighs "$(APP)/Contents/MacOS/"
	codesign --force --options runtime --sign - --entitlements RecordHighs.entitlements "$(APP)"

test:
	swift test

samples:
	swift run RecordHighs --samples samples

check: app
	scripts/check-promises.sh

icon:   # redraws AppIcon.icns from assets/icon.svg; needs rsvg-convert (brew install librsvg)
	rm -rf build/AppIcon.iconset && mkdir -p build/AppIcon.iconset
	for s in 16 32 128 256 512; do \
	  rsvg-convert -w $$s -h $$s assets/icon.svg -o build/AppIcon.iconset/icon_$${s}x$${s}.png; \
	  rsvg-convert -w $$((s*2)) -h $$((s*2)) assets/icon.svg -o build/AppIcon.iconset/icon_$${s}x$${s}@2x.png; done
	iconutil -c icns build/AppIcon.iconset -o AppIcon.icns

install: app
	rm -rf "/Applications/Record Highs.app"
	cp -R "$(APP)" /Applications/
