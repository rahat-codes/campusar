from sqlalchemy import JSON, Float, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.database.session import Base


class Building(Base):
    __tablename__ = "buildings"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    campus_id: Mapped[str] = mapped_column(String, index=True, nullable=False)
    name: Mapped[str] = mapped_column(String, nullable=False)
    short_name: Mapped[str] = mapped_column(String, nullable=False)
    building_number: Mapped[str] = mapped_column(String, index=True, nullable=False)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    description: Mapped[str] = mapped_column(String, default="")
    image: Mapped[str] = mapped_column(String, default="")
    floors: Mapped[int] = mapped_column(Integer, default=1)
    # entrance/facility ids are stored as JSON arrays of foreign string ids
    # rather than a many-to-many table, to keep V1 simple; entrances and
    # facilities each also carry their own building_id for direct queries.
    entrance_ids: Mapped[list] = mapped_column(JSON, default=list)
    facility_ids: Mapped[list] = mapped_column(JSON, default=list)
    accessibility: Mapped[dict] = mapped_column(JSON, default=dict)
    destination_node_id: Mapped[str] = mapped_column(String, nullable=True)
    entrance_node_id: Mapped[str] = mapped_column(String, nullable=True)
