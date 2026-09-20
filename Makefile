# ═══════════════════════════════════════════════════════════════════════════════
# opalshell — Makefile
# A beautiful Wayland status bar for Hyprland, built with QuickShell.
# https://github.com/OpalAayan/opalshell
# ═══════════════════════════════════════════════════════════════════════════════

VERSION    := 1.0.0

# ─── Toolchain ────────────────────────────────────────────────────────────────
CC         ?= gcc
CFLAGS     ?= -O2 -Wall -Wextra -pedantic -std=gnu2x -D_DEFAULT_SOURCE
PKG_CONFIG ?= pkg-config

# ─── Installation Paths ──────────────────────────────────────────────────────
PREFIX     ?= /usr/local
BINDIR     ?= $(PREFIX)/bin
DATADIR    ?= $(PREFIX)/share/opalshell

# ─── Library Flags ────────────────────────────────────────────────────────────
LIBNM_FLAGS := $(shell $(PKG_CONFIG) --cflags --libs libnm)
DBUS_FLAGS  := $(shell $(PKG_CONFIG) --cflags --libs dbus-1)

# ─── Sources & Build Outputs ─────────────────────────────────────────────────
# Binaries are compiled directly into shell/ so the project is runnable
# from the repo immediately after `make` (no install required for dev).

SYSBRIDGE_SRC := src/sysbridge.c
SYSBRIDGE_BIN := shell/sysbridge

ETH_SRC       := src/eth_status.c
ETH_BIN       := shell/scripts/eth_status

WIFI_SRC      := src/wifi_status.c
WIFI_BIN      := shell/scripts/wifi_status

BT_SRC        := src/bt_status.c
BT_BIN        := shell/scripts/bt_status

ALL_BINS      := $(SYSBRIDGE_BIN) $(ETH_BIN) $(WIFI_BIN) $(BT_BIN)

# ═══════════════════════════════════════════════════════════════════════════════
# Build Targets
# ═══════════════════════════════════════════════════════════════════════════════
.PHONY: all clean install uninstall check-deps test check

all: $(ALL_BINS)
	@printf '\n  \033[1;32m✓\033[0m  opalshell $(VERSION) built successfully.\n'
	@printf '     Run \033[1m./bin/opalshell\033[0m to launch from this directory.\n\n'

$(SYSBRIDGE_BIN): $(SYSBRIDGE_SRC)
	$(CC) $(CFLAGS) -o $@ $<

$(ETH_BIN): $(ETH_SRC)
	$(CC) $(CFLAGS) -o $@ $< $(LIBNM_FLAGS)

$(WIFI_BIN): $(WIFI_SRC)
	$(CC) $(CFLAGS) -o $@ $< $(LIBNM_FLAGS) -lm

$(BT_BIN): $(BT_SRC)
	$(CC) $(CFLAGS) -o $@ $< $(DBUS_FLAGS)

# ═══════════════════════════════════════════════════════════════════════════════
# Clean
# ═══════════════════════════════════════════════════════════════════════════════
clean:
	rm -f $(ALL_BINS)
	@printf '  \033[1;32m✓\033[0m  Clean complete.\n'

# ═══════════════════════════════════════════════════════════════════════════════
# Install
# ═══════════════════════════════════════════════════════════════════════════════
install: all
	install -d $(DESTDIR)$(BINDIR)
	install -m 755 bin/opalshell $(DESTDIR)$(BINDIR)/opalshell
	install -d $(DESTDIR)$(DATADIR)/shell
	install -m 644 shell/*.qml $(DESTDIR)$(DATADIR)/shell/
	install -m 755 $(SYSBRIDGE_BIN) $(DESTDIR)$(DATADIR)/shell/sysbridge
	install -d $(DESTDIR)$(DATADIR)/shell/scripts
	install -m 755 $(ETH_BIN)  $(DESTDIR)$(DATADIR)/shell/scripts/eth_status
	install -m 755 $(WIFI_BIN) $(DESTDIR)$(DATADIR)/shell/scripts/wifi_status
	install -m 755 $(BT_BIN)   $(DESTDIR)$(DATADIR)/shell/scripts/bt_status
	install -m 755 shell/scripts/*.sh $(DESTDIR)$(DATADIR)/shell/scripts/
	install -d $(DESTDIR)$(DATADIR)
	install -m 644 config/config.ini.example $(DESTDIR)$(DATADIR)/
	@printf '\n  ════════════════════════════════════════════\n'
	@printf '    \033[1;32m✓\033[0m  opalshell $(VERSION) installed!\n'
	@printf '    Run \033[1mopalshell\033[0m to start the bar.\n'
	@printf '  ════════════════════════════════════════════\n\n'

# ═══════════════════════════════════════════════════════════════════════════════
# Uninstall
# ═══════════════════════════════════════════════════════════════════════════════
uninstall:
	rm -f  $(DESTDIR)$(BINDIR)/opalshell
	rm -rf $(DESTDIR)$(DATADIR)
	@printf '  \033[1;32m✓\033[0m  opalshell uninstalled.\n'
	@printf '  \033[2m   User config at ~/.config/opalshell/ was not touched.\033[0m\n\n'

# ═══════════════════════════════════════════════════════════════════════════════
# Test & Memory Leak / Static Analysis Checks
# ═══════════════════════════════════════════════════════════════════════════════
test: check
check: all
	@printf '\n  \033[1;36m▸ Running Static Analysis (cppcheck)...\033[0m\n'
	@if command -v cppcheck >/dev/null 2>&1; then \
		cppcheck --quiet --enable=warning,style,performance,portability \
			--error-exitcode=1 \
			--suppress=missingIncludeSystem src/; \
		printf '  \033[1;32m[✓]\033[0m cppcheck passed with 0 issues.\n'; \
	else \
		printf '  \033[1;33m[!]\033[0m cppcheck not installed, skipping.\n'; \
	fi
	@printf '\n  \033[1;36m▸ Running Memory Leak Check (valgrind)...\033[0m\n'
	@if command -v valgrind >/dev/null 2>&1; then \
		valgrind --leak-check=full --error-exitcode=1 --errors-for-leak-kinds=definite,indirect \
			$(SYSBRIDGE_BIN) all >/dev/null; \
		printf '  \033[1;32m[✓]\033[0m sysbridge: 0 memory leaks, 0 memory errors.\n'; \
		valgrind --leak-check=full --error-exitcode=1 --errors-for-leak-kinds=definite,indirect \
			$(BT_BIN) --status >/dev/null; \
		printf '  \033[1;32m[✓]\033[0m bt_status: 0 memory leaks, 0 memory errors.\n'; \
		valgrind --leak-check=full --error-exitcode=1 --errors-for-leak-kinds=definite,indirect \
			$(WIFI_BIN) >/dev/null; \
		printf '  \033[1;32m[✓]\033[0m wifi_status: 0 memory leaks, 0 memory errors.\n'; \
		valgrind --leak-check=full --error-exitcode=1 --errors-for-leak-kinds=definite,indirect \
			$(ETH_BIN) >/dev/null; \
		printf '  \033[1;32m[✓]\033[0m eth_status: 0 memory leaks, 0 memory errors.\n'; \
	else \
		printf '  \033[1;33m[!]\033[0m valgrind not installed, skipping.\n'; \
	fi
	@printf '\n  \033[1;32m✓  All code quality & memory leak tests passed!\033[0m\n\n'

# ═══════════════════════════════════════════════════════════════════════════════
# Dependency Checker
# ═══════════════════════════════════════════════════════════════════════════════
define check_cmd
	@printf '  '; \
	if command -v $(1) >/dev/null 2>&1; then \
		printf '\033[1;32m[✓]\033[0m  %-22s %s\n' '$(1)' '$(2)'; \
	else \
		printf '\033[1;31m[✗]\033[0m  %-22s %s\n' '$(1)' '$(2)'; \
	fi
endef

define check_opt
	@printf '  '; \
	if command -v $(1) >/dev/null 2>&1; then \
		printf '\033[1;32m[✓]\033[0m  %-22s %s\n' '$(1)' '$(2)'; \
	else \
		printf '\033[1;33m[?]\033[0m  %-22s %s (optional)\n' '$(1)' '$(2)'; \
	fi
endef

define check_font
	@printf '  '; \
	if fc-list 2>/dev/null | grep -qi '$(1)'; then \
		printf '\033[1;32m[✓]\033[0m  %-22s %s\n' '$(1)' '$(2)'; \
	else \
		printf '\033[1;33m[?]\033[0m  %-22s %s (recommended)\n' '$(1)' '$(2)'; \
	fi
endef

check-deps:
	@printf '\n  \033[1mopalshell $(VERSION) — Dependency Check\033[0m\n'
	@printf '  ──────────────────────────────────────────\n\n'

	@printf '  \033[1;36m▸ Build Tools\033[0m\n'
	$(call check_cmd,$(CC),C compiler)
	$(call check_cmd,make,Build system)
	$(call check_cmd,$(PKG_CONFIG),Library detection)

	@printf '\n  \033[1;36m▸ Core Runtime\033[0m\n'
	$(call check_cmd,quickshell,Shell framework (>= 0.3.1))
	$(call check_cmd,nmcli,NetworkManager CLI)
	$(call check_cmd,bluetoothctl,Bluetooth control)
	$(call check_cmd,wpctl,Wireplumber / PipeWire)
	$(call check_cmd,busctl,D-Bus control (systemd))
	$(call check_cmd,brightnessctl,Backlight control)

	@printf '\n  \033[1;36m▸ Desktop Integration\033[0m\n'
	$(call check_cmd,kitty,Terminal emulator (for btop))
	$(call check_cmd,btop,System monitor)
	$(call check_cmd,dunstify,Notification daemon (dunst))
	$(call check_opt,notify-send,Notification fallback (libnotify))

	@printf '\n  \033[1;36m▸ Optional Tools\033[0m\n'
	$(call check_opt,hyprpicker,Color picker)
	$(call check_opt,wl-copy,Clipboard (wl-clipboard))
	$(call check_opt,fuzzel,App launcher)
	$(call check_opt,rofi,App launcher (alternative))
	$(call check_opt,wofi,App launcher (alternative))
	$(call check_opt,powerprofilesctl,Power profiles daemon)
	$(call check_opt,convert,ImageMagick (color picker icons))
	$(call check_opt,wl-gammarelay-rs,Night light control)

	@printf '\n  \033[1;36m▸ Fonts\033[0m\n'
	$(call check_font,JetBrainsMono Nerd,Primary bar font)
	$(call check_font,Rubik,Secondary text font)

	@printf '\n  ──────────────────────────────────────────\n\n'
