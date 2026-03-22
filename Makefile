GODOT ?= godot
PROJECT_PATH ?= .
BUILD_DIR ?= build
GAME_NAME ?= cat-chaos

# Export preset names from Godot.
WINDOWS ?= Windows Desktop
LINUX ?= Linux/X11
WEB ?= Web

# Output files.
WIN_OUT := $(BUILD_DIR)/windows/$(GAME_NAME).exe
LINUX_OUT := $(BUILD_DIR)/linux/$(GAME_NAME).x86_64
WEB_OUT := $(BUILD_DIR)/web/index.html

.PHONY: all clean windows linux web

# The repository currently ships with a Linux/X11 preset in export_presets.cfg.
all: clean linux

clean:
	rm -rf $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)

windows:
	mkdir -p $(BUILD_DIR)/windows
	$(GODOT) --headless --path $(PROJECT_PATH) \
		--export-release "$(WINDOWS)" $(WIN_OUT)

linux:
	mkdir -p $(BUILD_DIR)/linux
	$(GODOT) --headless --path $(PROJECT_PATH) \
		--export-release "$(LINUX)" $(LINUX_OUT)

web:
	mkdir -p $(BUILD_DIR)/web
	$(GODOT) --headless --path $(PROJECT_PATH) \
		--export-release "$(WEB)" $(WEB_OUT)
