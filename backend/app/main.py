from __future__ import annotations
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import get_settings
from app.routers.chat import router as chat_router
from app.routers.voice import router as voice_router


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(title=settings.app_name)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    @app.get("/")
    def root():
        return {"message": "EV Charger Bot Backend is running."}
    
    app.include_router(chat_router)
    app.include_router(voice_router)

    return app


app = create_app()
