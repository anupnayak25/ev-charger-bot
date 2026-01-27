# EV Charger Bot

EV Charger Bot is a simple **Flutter** chat app (text + voice) backed by a **FastAPI** server. It’s intended as an “EV
charging support assistant” UI that can:

- Send text messages to the backend (`POST /api/chat`)
- Record a short voice message and send it to the backend (`POST /api/voice/ask`)

Repo structure:

- `backend/` — FastAPI server (Python)
- `frontend/` — Flutter app

## Prerequisites

- **Python 3.10+** (recommended) + `pip`
- **Flutter (stable)** + Android toolchain (Android Studio / SDK)
- An **OpenAI API key** (used by the backend)

## Backend (FastAPI)

Detailed backend notes live in [backend/README.md](backend/README.md).

### Setup (Windows PowerShell)

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
```

Create `.env`:

- Copy `.env.example` → `.env`
- Set `OPENAI_API_KEY`
- Optional: `OPENAI_MODEL`, `OPENAI_TEMPERATURE`

### Run

```powershell
cd backend
.\.venv\Scripts\activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Health check:

- `GET http://localhost:8000/`

## Frontend (Flutter)

The app lives in `frontend/`.

### Install deps

```powershell
cd frontend
flutter pub get
```

### Configure backend URL

The frontend reads `BACKEND_URL` from `--dart-define`. If you don’t pass it, it falls back to the default defined in
`frontend/lib/main.dart`.

Run against local backend:

```powershell
cd frontend
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:8000
```

Notes:

- Android emulator → use `http://10.0.2.2:8000`
- Real device → use your machine’s LAN IP (example `http://192.168.1.10:8000`)
- iOS simulator → usually `http://127.0.0.1:8000`

### Run

```powershell
cd frontend
flutter run
```

## API Summary

Backend endpoints:

- `POST /api/chat` (JSON)
- `POST /api/voice/ask` (multipart form upload with field `audio`)

The backend is stateless: the UI sends the current conversation `turns[]` each time.
