# ShowPilot Cloud Link — Primer

> Sanitization rule: never put personal names, machine names, IP addresses,
> real show URLs or show names in this file.

## What it is

A fork of the **ShowPilot Blackbox** FPP plugin (`ShowPilotFPP/ShowPilot-plugin`)
for shows hosted on **ShowPilot Cloud**. Forked from Blackbox **v0.14.22**
(commit `65503b3`). Everything Blackbox does is unchanged; Cloud Link adds an
**outbound link** from the FPP's audio daemon to the hosted show.

It exists as a separate plugin only so live Blackbox installs can't be
affected during the 2026 season. **Parked (2026-11-07):** testers are existing
ShowPilot users on Blackbox, so swapping plugins mid-season isn't workable.
After the season, fold the link into Blackbox behind a **Self-hosted /
ShowPilot Cloud** setting (decided 2026-11-07): Self-hosted keeps today's
behavior exactly with no outbound link; Cloud turns the link on. Then merge
ShowPilot's `cloud-link` branch and retire this repo.

## Why the link is needed

A self-hosted ShowPilot server sits on the show's LAN and dials **into** the
daemon (`ws://<fpp>:8090`) for live song position
(`lib/audio-position-relay.js` in ShowPilot). A hosted server can't reach a
home network, so the daemon dials **out** to `<Server URL>/api/plugin/link`.
Audio files already reach the server over the internet: the plugin uploads
them on **Sync Now**, and listeners are served from that cache.

## The link (`showpilot_audio.js`, section "Cloud link")

- Reads `serverUrl` from the plugin config (`SP_CONFIG_FILE`, URL-decoded) and
  the show token from `SP_TOKEN_FILE` on **every** attempt, so settings changes
  apply without restarting fppd. Both paths are passed by
  `start_audio_daemon` in `scripts/showpilot_env.sh`.
- Connects with `Authorization: Bearer <token>` using the vendored `ws`
  client. On open, the socket is added to `wsClients`, so it receives exactly
  what local clients get (position ~2/s, syncPoint ~1/s, heartbeat 5 s) and
  the 30 s protocol pings. The server pings every 5 s to measure RTT; `ws`
  answers automatically.
- Reconnect: 1 s after a working link drops; otherwise exponential from 2 s
  to 60 s. HTTP 401 (wrong token), 403 (audio is off for the show) or 404
  (server has no link endpoint) → wait 5 minutes. Not configured → check
  again every 30 s.
- `scripts/postStart.sh` refuses to start anything if
  `<media>/plugins/showpilot-plugin` (Blackbox) exists: the two share the
  settings key `config/plugin.showpilot`, port 8090 and `/tmp/SHOWPILOT_FIFO`.

## Server side (ShowPilot main, hosted mode only)

`lib/plugin-link.js` accepts the upgrade at `/api/plugin/link` (timing-safe
show-token check; 403 while audio is off) and hands the socket to
`audio-position-relay.attachIncoming()`, which uses the same message, clock
mapping and RTT code as the dial-out path. In hosted mode `getConfig()`
blanks `plugin_fpp_host`, so no LAN path ever runs.

## Differences from Blackbox (keep this list current)

- `showpilot_audio.js`: Cloud link section; header env docs.
- `scripts/showpilot_env.sh`: passes `SP_CONFIG_FILE`, `SP_TOKEN_FILE`.
- `scripts/postStart.sh`, `scripts/restart-daemon.sh`: Blackbox-installed guard.
- `commands/restart_listener.php`: also restarts the audio daemon (cloud-2).
- `showpilot_ui.html` title and listener log lines say Cloud Link.
- `pluginInfo.json`: repoName `showpilot-cloud-link`, name, description, URLs,
  privacy entry for the live-position connection.
- `showpilot_ui.html`: source link; Server URL hint points at the Cloud
  dashboard's ShowPilot URL.
- `README.md`, this primer. (Blackbox's PRIMER.md/CLAUDE.md not copied.)

`version.php` stays at the Blackbox version it's based on so the server's
update notice compares correctly. When Blackbox changes, merge them in and
keep this list accurate.

## Testing

Tested locally (2026-11-07): daemon against a hosted ShowPilot build with
simulated FPP FIFO events — positions and sync points reach a Socket.io
viewer on time; reconnects ~3 s after a server restart; wrong token → 401
and 5-minute wait; audio-locked show → 403.

Field test (2026-11-07): a real Raspberry Pi on FPP 10.3 with Cloud Link,
linked to a Cloud test show on the `cloud-link` ShowPilot branch. Phone audio
played in sync with the show from a phone on cellular and a computer on a
different network — nothing on the FPP's network was reachable from outside.

## Version history

- **cloud-1** (based on Blackbox 0.14.22) — Outbound link for hosted shows.
- **cloud-2** (based on Blackbox 0.14.22) — Bug fix: **Restart Listener**
  now restarts the audio daemon too. The daemon (which holds the outbound
  link) only starts when a Server URL is set, and before this it only ever
  started with FPP itself — so on an FPP that booted before the URL was
  entered, saving the URL and clicking Restart Listener brought back
  check-ins and requests but never the link, and phones fell back to the
  rough start position ("no syncPoint"). Found in the field: the log had no
  daemon lines after "Audio daemon not started: no Server URL configured
  yet". `restart-daemon.sh` also gets the Blackbox guard. Branding: the
  config page title and listener log lines now say ShowPilot Cloud Link.
  Checked: `php -l`, `bash -n`.
