from sqlalchemy import JSON, Float, String
from sqlalchemy.orm import Mapped, mapped_column

from app.database.session import Base


class Campus(Base):
    __tablename__ = "campuses"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    name: Mapped[str] = mapped_column(String, nullable=False)
    university_name: Mapped[str] = mapped_column(String, nullable=False)
    country: Mapped[str] = mapped_column(String, nullable=False)
    city: Mapped[str] = mapped_column(String, nullable=False)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    map_configuration: Mapped[dict] = mapped_column(JSON, default=dict)
    version: Mapped[str] = mapped_column(String, nullable=False, default="1.0.0")


class CampusVersion(Base):
    """
    Tracks the currently published data version for a campus, so clients
    can decide whether they need to re-sync (see README "Offline architecture").
    """

    __tablename__ = "campus_versions"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    campus_id: Mapped[str] = mapped_column(String, nullable=False, index=True)
    version: Mapped[str] = mapped_column(String, nullable=False)
    published_at: Mapped[str] = mapped_column(String, nullable=False)
