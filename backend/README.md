# Backend (FastAPI)

## Setup

1. Create env file:
   - Copy `.env.example` to `.env`
   - Set `OPENAI_API_KEY`

2. Install dependencies (uses backend/.venv):

```powershell
cd backend
.\.venv\Scripts\python.exe -m pip install -U pip
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

## Run

```powershell
cd backend
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Endpoints

- `GET /healthz`
- `POST /api/chat` (JSON)
- `POST /api/voice/transcribe` (multipart file upload)
- `POST /api/voice/speak` (JSON -> audio)

## Chat behavior (no history stored)

The backend is stateless: it does not store chat history. Your UI should send the full `messages[]` for the _current_
conversation each time you call `/api/chat`.

If you do **not** include any `system` or `developer` message in `messages[]`, the backend automatically prepends an
EV-charging support system prompt (configurable via `EV_ASSISTANT_SYSTEM_PROMPT`).
