#!/bin/bash
# ShowPilot postStart — runs every time fppd starts. Must return quickly:
# everything long-running is backgrounded.

. "$(dirname "${BASH_SOURCE[0]}")/showpilot_env.sh"

# Some FPP versions call postStart twice; a second concurrent copy would
# spawn duplicate daemons that interleave writes on the audio relay.
exec 9<"${BASH_SOURCE[0]}"
flock -n 9 || exit 0

# Cloud Link replaces ShowPilot Blackbox; the two share settings, the audio
# port and the FPP event pipe, so they must never run together.
if [ -d "${MEDIADIR}/plugins/showpilot-plugin" ]; then
    plugin_log "ShowPilot Blackbox is also installed — Cloud Link is not starting. Uninstall one of them (Cloud Link is for ShowPilot Cloud shows)."
    exit 0
fi

ensure_runtime_files

stop_listener
stop_audio_daemon

start_listener
start_audio_daemon

# The MultiSync .so is built by fpp_install.sh / fpp_upgrade.sh, never here.
if [ -f "$PLUGIN_DIR/Makefile" ] && [ ! -f "$PLUGIN_DIR/lib${PLUGIN_NAME}.so" ]; then
    plugin_log "WARN: lib${PLUGIN_NAME}.so missing — re-run the plugin's install script to rebuild it"
fi

#postStart
