APP_NAME    = D-Switch
BUILD_DIR   = build
BUNDLE      = $(BUILD_DIR)/$(APP_NAME).app
EXECUTABLE  = $(BUNDLE)/Contents/MacOS/$(APP_NAME)
SOURCES     = $(wildcard Sources/*.swift)
TEST_EXECUTABLE = $(BUILD_DIR)/HotkeyConfigurationTests

ARCH       := $(shell uname -m)
TARGET     := $(ARCH)-apple-macos14.0

# Signing identity. A stable identity (even self-signed) keeps the same
# designated requirement across rebuilds, so TCC grants such as Accessibility
# survive recompiles. Ad-hoc ("-") changes identity every build.
# Override: make build SIGN_IDENTITY="Developer ID Application: ..."
SIGN_IDENTITY ?= $(shell security find-identity -v -p codesigning 2>/dev/null \
                   | grep -o '"D-Switch Dev Signing"' | head -1 | tr -d '"')
ifeq ($(strip $(SIGN_IDENTITY)),)
  SIGN_IDENTITY := -
endif
SWIFT_FLAGS = -swift-version 5 -target $(TARGET) -O \
              -framework Cocoa -framework Carbon -framework ServiceManagement

.PHONY: build test run clean signing-identity

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
	@codesign --force --sign "$(SIGN_IDENTITY)" "$(BUNDLE)"
	@echo "Built $(BUNDLE) (signed: $(SIGN_IDENTITY))"

run: build
	@open "$(BUNDLE)"

clean:
	@rm -rf $(BUILD_DIR)

# One-time setup: create and trust a self-signed code-signing identity so the
# app keeps a stable designated requirement across rebuilds (see README).
signing-identity:
	@if security find-identity -v -p codesigning 2>/dev/null | grep -q '"D-Switch Dev Signing"'; then \
	  echo "Identity 'D-Switch Dev Signing' already exists."; exit 0; fi; \
	T=$$(mktemp -d); \
	printf '%s\n' '[req]' 'distinguished_name = dn' 'x509_extensions = ext' 'prompt = no' \
	  '[dn]' 'CN = D-Switch Dev Signing' \
	  '[ext]' 'basicConstraints = critical,CA:false' 'keyUsage = critical,digitalSignature' \
	  'extendedKeyUsage = critical,codeSigning' 'subjectKeyIdentifier = hash' > "$$T/cert.cnf"; \
	openssl req -x509 -newkey rsa:2048 -sha256 -nodes -days 3650 -config "$$T/cert.cnf" \
	  -keyout "$$T/key.pem" -out "$$T/cert.pem" 2>/dev/null; \
	openssl pkcs12 -export -inkey "$$T/key.pem" -in "$$T/cert.pem" -out "$$T/id.p12" -passout pass:tmp -legacy 2>/dev/null \
	  || openssl pkcs12 -export -inkey "$$T/key.pem" -in "$$T/cert.pem" -out "$$T/id.p12" -passout pass:tmp; \
	security import "$$T/id.p12" -k ~/Library/Keychains/login.keychain-db -P tmp -T /usr/bin/codesign -T /usr/bin/security; \
	security add-trusted-cert -r trustRoot -p codeSign -k ~/Library/Keychains/login.keychain-db "$$T/cert.pem"; \
	rm -rf "$$T"; \
	security find-identity -v -p codesigning | grep 'D-Switch Dev Signing' && echo "Done. Run 'make build' to sign with it."
