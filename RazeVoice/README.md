# RazeVoice — iOS Client

Native iOS voice client for Raze. Opens, starts recording, sends audio to relay, plays response.

## Build & Run

1. Pull this repo to your MacBook 2019
2. Open `RazeVoice.xcodeproj` in Xcode
3. Select your iPhone 16 as target
4. Signing & Capabilities → Team → Personal Team (free provisioning)
5. Build & Run (⌘R)

For free perpetual install, use **AltStore** after first build:
- Install AltServer on your Mac
- Plug in iPhone, AltStore installs the app
- Auto-refresh over WiFi

## Shortcuts Integration

Create a Shortcut:
- Open App → RazeVoice
- Name it "Talk to Raze"
- Now: Hey Siri, Talk to Raze → opens app → auto-listens

Map Action Button (Settings → Action Button → Shortcut → Talk to Raze).

## Relay Server

The app talks to a relay server (not localhost). Deploy `relay/` to your VPS or home server.
