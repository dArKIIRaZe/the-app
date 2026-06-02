# RazeVoice

iOS voice client + relay server for Raze.

## Structure

- `RazeVoice/` — SwiftUI iOS app (Xcode project)
- `relay/` — Python FastAPI relay (Groq STT → Hermes → ElevenLabs TTS)

## iOS App

Opens. Starts listening. Tap to stop. Sends audio to relay. Plays response.

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

**Config:** Edit `HermesService.swift` → `baseURL` to your relay address.

## Relay Server

Deploy to any VPS or your home server. The iPhone needs to reach it over the internet.

```bash
cd relay
cp .env.example .env
# edit .env with your keys
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```

**Required:**
- `GROQ_API_KEY` — STT (Whisper)
- `ELEVENLABS_API_KEY` — TTS
- `HERMES_URL` — your Hermes gateway (use Cloudflare Tunnel or Tailscale if local)

## Security Note

Relay holds your API keys. Lock it down to your IP or use a simple token if exposing to the internet.
