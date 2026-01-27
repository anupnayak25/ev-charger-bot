# EV Charger Bot (Flutter Frontend)

Flutter UI for the EV Charger Bot.

- Text chat (`/api/chat`)
- Voice recording + upload (`/api/voice/ask`)

Backend lives in [../backend](../backend).

## Prerequisites

- Flutter (stable)
- Android Studio / SDK (or your preferred target platform toolchain)

## Install dependencies

```powershell
cd frontend
flutter pub get
```

## Configure backend URL

The app reads the backend base URL from `--dart-define=BACKEND_URL=...`. If not provided, it falls back to the default
in `lib/main.dart`.

Common values:

- Android emulator: `http://10.0.2.2:8000`
- iOS simulator: `http://127.0.0.1:8000`
- Real device: `http://<your-computer-lan-ip>:8000`

Example (Android emulator):

```powershell
cd frontend
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:8000
```

## Run

```powershell
cd frontend
flutter run
```

