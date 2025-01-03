VERSION := v0.0.6

RELEASE_DIR = dist
DMG_NAME = mypwbox_$(VERSION).dmg

.PHONY: clean
clean: ## Remove release binaries
	rm -rf $(RELEASE_DIR)

.PHONY: build-dirs
build-dirs: clean
	mkdir -p $(RELEASE_DIR)

.PHONY: build
build: build-dirs
	flutter build macos --release

.PHONY: dmg
dmg: build
	# copy mypwbox.app
	cp -r ./build/macos/Build/Products/Release/mypwbox.app ./dist/
	# build dmg file
	create-dmg \
	  --volname "mypwbox" \
	  --window-size 500 300 \
	  --icon "mypwbox.app" 125 125 \
	  --app-drop-link 375 125 \
	  "./$(DMG_NAME)" \
	  "./dist/"



