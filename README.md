# ShowPilot Cloud Link

The FPP plugin for shows hosted on **ShowPilot Cloud**.

It's ShowPilot Blackbox plus one thing: it keeps a single outbound connection
open from your FPP to your hosted show, so phones listening to your show get
FPP's live song position and stay in sync with your speakers. Your FPP never
has to be reachable from the internet — no port forwarding, no tunnel.

**Use it instead of ShowPilot Blackbox, never alongside it.** The two share
their settings, audio port and FPP event pipe. If Blackbox is still installed,
Cloud Link won't start (it says so in its log). Self-hosted ShowPilot servers
should keep using Blackbox.

## Install

1. In FPP: **Content Setup → Plugin Manager**, uninstall *ShowPilot Blackbox*
   if it's there. Its settings (Server URL etc.) are kept.
2. Paste this into the Plugin Manager's plugin URL box and click **Retrieve
   Plugin Info**, then **Install**:
   ```
   https://raw.githubusercontent.com/ShowPilotFPP/ShowPilot-Cloud-Link/main/pluginInfo.json
   ```
3. Open the plugin's page. Enter the **ShowPilot URL** and **show token** from
   your show's Manage dialog on ShowPilot Cloud, and save.
4. Click **Sync Now** so your songs and their audio are uploaded to your show.
5. Restart fppd once (FPP's **Restart FPPD** button) so the audio service
   starts with the link.

The plugin's log shows `Cloud link connected to https://…` when it's working.

## Status

Private testing. Built from ShowPilot Blackbox 0.14.22; it will be folded back
into Blackbox once proven. See `PRIMER.md`.
