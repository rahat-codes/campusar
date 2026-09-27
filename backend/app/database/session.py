"""
Database engine and session management.

Works against either SQLite (default, zero-config) or PostgreSQL
(recommended for real development / production — see docker-compose.yml
and README "Backend setup"). The rest of the app never imports
sqlalchemy.create_engine directly; everything goes through get_db().
"""
from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from app.core.config import get_settings

settings = get_settings()

connect_args = {}
if settings.DATABASE_URL.startswith("sqlite"):
    # Needed for SQLite when used from multiple threads (FastAPI's TestClient
    # and Uvicorn workers both do this).
    connect_args = {"check_same_thread": False}

engine = create_engine(settings.DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


def get_db() -> Generator:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
