from sqlalchemy import Float, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.database.session import Base


class Entrance(Base):
    __tablename__ = "entrances"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    building_id: Mapped[str] = mapped_column(String, index=True, nullable=False)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    floor: Mapped[int] = mapped_column(Integer, default=1)
    name: Mapped[str] = mapped_column(String, default="Main Entrance")
