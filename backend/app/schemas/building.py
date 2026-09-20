from pydantic import BaseModel, ConfigDict


class EntranceSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    building_id: str
    latitude: float
    longitude: float
    floor: int
    name: str


class FacilitySchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    building_id: str
    name: str
    category: str


class BuildingSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    campus_id: str
    name: str
    short_name: str
    building_number: str
    latitude: float
    longitude: float
    description: str
    image: str
    floors: int
    accessibility: dict


class BuildingDetailSchema(BuildingSchema):
    """Building plus its resolved entrances and facilities."""

    entrances: list[EntranceSchema] = []
    facilities: list[FacilitySchema] = []
    distance_from_user_meters: float | None = None
