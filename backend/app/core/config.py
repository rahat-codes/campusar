"""
Application configuration.

Settings are loaded from environment variables (and a local .env file in
development). Never hardcode secrets here — see .env.example for the list
of variables the backend expects.
"""
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    APP_NAME: str = "CampusAR Backend"
    API_V1_PREFIX: str = "/api/v1"
    ENVIRONMENT: str = "development"

    # Default is a local SQLite file so the project runs with zero external
    # services out of the box. For real development/production, set
    # DATABASE_URL to a PostgreSQL DSN, e.g.:
    #   postgresql+psycopg2://campusar:campusar@localhost:5432/campusar
    DATABASE_URL: str = "sqlite:///./campusar.db"

    # Path to the bundled sample campus dataset used to seed the database.
    SEED_DATA_DIR: str = "app/data/seed"

    CAMPUS_ID: str = "tongmyong-main"
    CAMPUS_DATA_VERSION: str = "1.0.0"

    CORS_ORIGINS: list[str] = ["*"]


@lru_cache
def get_settings() -> Settings:
    return Settings()
