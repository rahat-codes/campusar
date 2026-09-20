from sqlalchemy import Boolean, Float, String
from sqlalchemy.orm import Mapped, mapped_column

from app.database.session import Base


class RouteNode(Base):
    __tablename__ = "route_nodes"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    # One of: pathway | intersection | entrance | destination
    type: Mapped[str] = mapped_column(String, nullable=False, default="pathway")


class RouteEdge(Base):
    __tablename__ = "route_edges"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    from_node: Mapped[str] = mapped_column(String, index=True, nullable=False)
    to_node: Mapped[str] = mapped_column(String, index=True, nullable=False)
    distance: Mapped[float] = mapped_column(Float, nullable=False)
    accessible: Mapped[bool] = mapped_column(Boolean, default=True)
    indoor: Mapped[bool] = mapped_column(Boolean, default=False)
    outdoor: Mapped[bool] = mapped_column(Boolean, default=True)
