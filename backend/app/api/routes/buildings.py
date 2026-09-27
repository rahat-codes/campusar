from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.core.geo import haversine_distance_meters
from app.database.session import get_db
from app.repositories.building_repository import BuildingRepository
from app.schemas.building import BuildingDetailSchema, BuildingSchema

router = APIRouter(prefix="/buildings", tags=["buildings"])


@router.get("", response_model=list[BuildingSchema])
def list_buildings(
    q: str | None = Query(
        default=None,
        description="Free-text search across name, short name, building number, and facilities.",
    ),
    db: Session = Depends(get_db),
):
    repo = BuildingRepository(db)
    if q:
        return repo.search(q)
    return repo.list_all()


@router.get("/{building_id}", response_model=BuildingDetailSchema)
def get_building(
    building_id: str,
    latitude: float | None = Query(default=None, description="User's current latitude, to compute distance."),
    longitude: float | None = Query(default=None, description="User's current longitude, to compute distance."),
    db: Session = Depends(get_db),
):
    repo = BuildingRepository(db)
    building = repo.get(building_id)
    if building is None:
        raise HTTPException(status_code=404, detail=f"Building '{building_id}' not found.")

    entrances = repo.entrances_for(building_id)
    facilities = repo.facilities_for(building_id)

    distance = None
    if latitude is not None and longitude is not None:
        distance = round(
            haversine_distance_meters(latitude, longitude, building.latitude, building.longitude),
            1,
        )

    return BuildingDetailSchema(
        **BuildingSchema.model_validate(building).model_dump(),
        entrances=entrances,
        facilities=facilities,
        distance_from_user_meters=distance,
    )
