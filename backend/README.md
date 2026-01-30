# Backend (FastAPI)

## Setup

1. Create env file:
   - Copy `.env.example` to `.env`
   - Set `OPENAI_API_KEY`
   - (Optional) Set `OPENAI_MODEL` and `OPENAI_TEMPERATURE`

2. Install dependencies (uses backend/.venv):

```powershell
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

## Run

```powershell
cd backend
.\.venv\Scripts\activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Tests

Install dev dependencies:

```powershell
cd backend
.\.venv\Scripts\python -m pip install -r requirements-dev.txt
```

Run tests:

```powershell
cd backend
.\.venv\Scripts\python -m pytest
```

## Endpoints

- `GET /`(health check)
- `POST /api/chat` (JSON)
- `POST /api/voice/ask` (multipart file upload) — speech → assistant reply

### `/api/voice/ask` payload

- Content-Type: `multipart/form-data`
- Field: `audio` (file)
- Optional fields: `summary` (text), `system_prompt` (text)
- Response: `{ "reply": "..." }`

## Chat behavior (no history stored)

The backend is stateless: it does not store chat history. Your UI should send the full `messages[]` for the _current_
conversation each time you call `/api/chat`.

The `/api/chat` endpoint accepts `turns[]` (each turn is `{ user, assistant? }`). The backend converts this into
role-based messages internally.

### Keeping chats efficient

To avoid sending very long histories, you can maintain a short running `summary` on the client and send it with each
request. The backend will include it as context.

Example request payload:

```json
{
  "summary": "User at Station #12, AC Type2 wallbox. Error E12 persists. Tried: rebooted charger, re-plugged cable.",
  "turns": [{ "user": "It still shows E12. What next?" }]
}
```

If you don’t pass `system_prompt`, the backend prepends an EV-charging support system prompt (configurable via
`EV_ASSISTANT_SYSTEM_PROMPT`).
