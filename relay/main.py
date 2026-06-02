import os
import io
import wave
import httpx
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import StreamingResponse
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
HERMES_URL = os.getenv("HERMES_URL", "http://localhost:8642/v1/chat/completions")
GROQ_TTS_MODEL = os.getenv("GROQ_TTS_MODEL", "canopylabs/orpheus-v1-english")
GROQ_TTS_VOICE = os.getenv("GROQ_TTS_VOICE", "hannah")

HEADERS_GROQ = {"Authorization": f"Bearer {GROQ_API_KEY}", "Content-Type": "application/json"}
HEADERS_HERMES = {"Content-Type": "application/json"}


@app.post("/chat")
async def chat(audio: UploadFile = File(...)):
    if not GROQ_API_KEY:
        raise HTTPException(status_code=500, detail="GROQ_API_KEY not set")

    # 1. Read uploaded audio and ensure WAV
    audio_bytes = await audio.read()
    wav_bytes = ensure_wav(audio_bytes)

    # 2. STT via Groq Whisper
    transcription = await groq_stt(wav_bytes)
    if not transcription:
        raise HTTPException(status_code=400, detail="STT failed")

    # 3. Chat via Hermes
    reply_text = await hermes_chat(transcription)
    if not reply_text:
        raise HTTPException(status_code=500, detail="Hermes returned no response")

    # 4. TTS via Groq Orpheus
    tts_audio = await groq_tts(reply_text)
    if not tts_audio:
        raise HTTPException(status_code=500, detail="TTS failed")

    return StreamingResponse(io.BytesIO(tts_audio), media_type="audio/wav")


def ensure_wav(data: bytes) -> bytes:
    """If data already has RIFF header, return as-is. Otherwise wrap raw PCM."""
    if data[:4] == b"RIFF":
        return data
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(16000)
        wf.writeframes(data)
    return buf.getvalue()


async def groq_stt(audio_bytes: bytes) -> str:
    url = "https://api.groq.com/openai/v1/audio/transcriptions"
    files = {"file": ("audio.wav", io.BytesIO(audio_bytes), "audio/wav")}
    data = {"model": "whisper-large-v3-turbo", "language": "en"}
    async with httpx.AsyncClient() as client:
        r = await client.post(url, headers={"Authorization": f"Bearer {GROQ_API_KEY}"}, data=data, files=files, timeout=30.0)
    r.raise_for_status()
    return r.json().get("text", "").strip()


async def hermes_chat(user_text: str) -> str:
    payload = {
        "model": "kimi-k2.6",
        "messages": [{"role": "user", "content": user_text}],
        "max_tokens": 512,
    }
    async with httpx.AsyncClient() as client:
        r = await client.post(HERMES_URL, headers=HEADERS_HERMES, json=payload, timeout=30.0)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"].strip()


async def groq_tts(text: str) -> bytes:
    url = "https://api.groq.com/openai/v1/audio/speech"
    payload = {
        "model": GROQ_TTS_MODEL,
        "input": text,
        "voice": GROQ_TTS_VOICE,
        "response_format": "wav",
    }
    async with httpx.AsyncClient() as client:
        r = await client.post(url, headers=HEADERS_GROQ, json=payload, timeout=60.0)
    r.raise_for_status()
    return r.content


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
