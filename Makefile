SDK_PLIST=Configs/MapirLiveTracker.plist
VERSION_STRING=$(shell /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$(SDK_PLIST)")



.PHONY: documentation
documentation:
		./Scripts/Documentation.sh

.PHONY: sdk_version
sdk_version:
		@echo $(VERSION_STRING)

