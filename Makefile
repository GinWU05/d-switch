APP_NAME    = D-Switch
BUILD_DIR   = build
BUNDLE      = $(BUILD_DIR)/$(APP_NAME).app
EXECUTABLE  = $(BUNDLE)/Contents/MacOS/$(APP_NAME)
SOURCES     = $(wildcard Sources/*.swift)
TEST_EXECUTABLE = $(BUILD_DIR)/HotkeyConfigurationTests

ARCH       := $(shell uname -m)
TARGET     := $(ARCH)-apple-macos14.0
SWIFT_FLAGS = -swift-version 5 -target $(TARGET) -O \
              -framework Cocoa -framework Carbon -framework ServiceManagement

.PHONY: build test run clean

build: $(EXECUTABLE)

test:
	@mkdir -p "$(BUILD_DIR)"
	swiftc Sources/HotkeyManager.swift Sources/DisplayManager.swift Tests/HotkeyConfigurationTests.swift \
		-o "$(TEST_EXECUTABLE)" -framework Cocoa -framework Carbon
	@"$(TEST_EXECUTABLE)"

$(EXECUTABLE): $(SOURCES) Info.plist
	@mkdir -p "$(BUNDLE)/Contents/MacOS"
	@mkdir -p "$(BUNDLE)/Contents/Resources"
	@cp Info.plist "$(BUNDLE)/Contents/"
	@cp AppIcon.icns "$(BUNDLE)/Contents/Resources/"
	swiftc $(SOURCES) -o "$(EXECUTABLE)" $(SWIFT_FLAGS)
	@codesign --force --sign - "$(BUNDLE)"
	@echo "Built $(BUNDLE)"

run: build
	@open "$(BUNDLE)"

clean:
	@rm -rf $(BUILD_DIR)
