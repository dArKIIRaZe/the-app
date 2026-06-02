# RazeVoice

iOS voice client + relay server for Raze.

## Structure

- `RazeVoice/` — SwiftUI iOS app (Xcode project)
- `relay/` — Python FastAPI relay (Groq STT → Hermes → Groq TTS)

## iOS App

Opens. Auto-listens via mic. Tap big red button to stop. Sends audio to relay. Plays response.

**Build:**
1. Copy `RazeVoice/` to your MacBook 2019
2. Open `RazeVoice.xcodeproj` in Xcode
3. Signing → Personal Team (free)
4. Build to your iPhone 16

**Perpetual install:** Use AltStore to refresh weekly automatically.

**Shortcuts:**
- Create Shortcut → Open App → RazeVoice
- Name: "Talk to Raze"
- Invoke via: Hey Siri, Talk to Raze — or Action Button

**Config:** `HermesService.swift` → `baseURL` is set to `https://voice.razetech.co.uk`.

## Relay Server

Deployed on your VPS. The iPhone hits it over the internet.

```bash
cd relay
cp .env.example .env
# edit .env with your keys (already configured on the VPS)
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```

**Required:**
- `GROQ_API_KEY` — STT (Whisper) + TTS (Orpheus)
- `HERMES_URL` — your Hermes gateway (localhost if relay is on same box)

**Groq TTS voices:** autumn, diana, hannah, austin, daniel
Default: `hannah`

**Cloudflare tunnel:**
Add `voice.razetech.co.uk` → `http://127.0.0.1:8000` in your Cloudflare Zero Trust dashboard.

## Stack

- **STT:** Groq Whisper (`whisper-large-v3-turbo`)
- **Chat:** Hermes gateway (`kimi-k2.6`)
- **TTS:** Groq Orpheus (`canopylabs/orpheus-v1-english`)
