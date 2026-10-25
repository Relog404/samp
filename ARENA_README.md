# NEON // ARENA — SA-MP gamemode

## What is implemented
- Unity Station hub at Los Santos, dispatcher actor, ALT and `/arena` interaction.
- Complete duel flow: configure a lobby, choose one of five battlefield locations, armor (50/100/150), weapon, and either find a human opponent (`/join`) or fight a moving AI opponent.
- AI opponent is a visible, damageable SA-MP actor. It tracks the player, walks toward them, attacks at close range, takes weapon damage, and can be defeated. Battle damage, countdown, return-to-hub and `/leave` are handled server-side.
- Per-player arena props and separate virtual worlds for duels. No NPC client is needed for AI.
- CEF/Chromium HUD page is `cef/assets/arena/index.html`; Pawn integration is available behind `ARENA_WITH_CEF`. A native TextDraw HUD remains as a fallback.

## Chromium setup (optional, requires client install)
CEF is not part of the base SA-MP client. The server-side API and HUD page are integrated, but the binary plugin and Chromium runtime must be installed separately; they could not be bundled from this environment. Use the `samp-cef` v1.4.1 release by ZOTTCE/Pycckue-Bnepeg:

1. On the Windows SA-MP server, put the release's `server.dll` in `plugins/` and add `plugins server` to `server.cfg`.
2. Compile `gamemodes/arena.pwn` with the same Pawn compiler and `-D ARENA_WITH_CEF` (or define `ARENA_WITH_CEF` in the script). The provided `pawno/include/cef.inc` contains the matching native declarations.
3. Players need the matching CEF client package: `cef.asi` in GTA's root and the full `cef/` runtime directory. Put `cef/assets/arena/index.html` under each player's GTA directory at `cef/assets/arena/index.html`.
4. Connect; when CEF initializes, the HUD is created and receives live lobby/map/weapon/AI-health updates. Without the client package, the normal SA-MP game remains usable with the TextDraw fallback.

CEF source/release: https://github.com/Pycckue-Bnepeg/samp-cef (v1.4.1). The client runtime is large and has to be distributed to players separately.

## Run without CEF
A ready-to-load `gamemodes/arena.amx` is included and `server.cfg` already selects it with `gamemode0 arena 1`. On Windows, start `start-server.bat` from the server folder; it sets the correct working directory and keeps the console open if startup fails. The base game mode does not require extra plugins.

Controls: ALT near the dispatcher or `/arena`; `/join` joins a human lobby; `/leave` exits the current match.
