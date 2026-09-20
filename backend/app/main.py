from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import buildings, campus, health, routes
from app.core.config import get_settings
from app.database.seed import seed_database
from app.database.session import Base, SessionLocal, engine


settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        seed_database(db)
    finally:
        db.close()
    yield


def create_app() -> FastAPI:
    app = FastAPI(title=settings.APP_NAME, lifespan=lifespan)

    @app.get("/")
    def root():
        return {"message": "CampusAR backend is running"}

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(health.router)
    app.include_router(campus.router, prefix=settings.API_V1_PREFIX)
    app.include_router(buildings.router, prefix=settings.API_V1_PREFIX)
    app.include_router(routes.router, prefix=settings.API_V1_PREFIX)

    return app


app = create_app()
