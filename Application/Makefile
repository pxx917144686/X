.PHONY: all clean build_clean

all: X.ipa

X.ipa: build/Build/Products/Debug-iphoneos/X.app
	@echo Ad-Hoc signing X
	xattr -rc build/Build/Products/Debug-iphoneos/X.app
	ldid -SX/X.entitlements build/Build/Products/Debug-iphoneos/X.app/X
	ldid -s build/Build/Products/Debug-iphoneos/X.app
	rm -rf Payload X.ipa
	mkdir Payload
	cp -r build/Build/Products/Debug-iphoneos/X.app Payload/X.app
	zip -Ar X.ipa Payload
	rm -rf Payload
	rm -rf X.tipa
	cp X.ipa X.tipa

ifeq ($(NIGHTLY), 1)
build/Build/Products/Debug-iphoneos/X.app: FORCE
	xcodebuild -scheme X -derivedDataPath build -destination 'generic/platform=iOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO GCC_PREPROCESSOR_DEFINITIONS='NIGHTLY=1 COMMIT_HASH=\"$(COMMIT_HASH)\"'
else
build/Build/Products/Debug-iphoneos/X.app: FORCE
	xcodebuild -scheme X -derivedDataPath build -destination 'generic/platform=iOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
endif

clean:
	rm -rf build Payload X.ipa X.tipa

build_clean:
	rm -rf Payload build

FORCE: ;