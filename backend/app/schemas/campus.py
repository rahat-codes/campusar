from pydantic import BaseModel, ConfigDict


class CampusSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    university_name: str
    country: str
    city: str
    latitude: float
    longitude: float
    map_configuration: dict
    version: str


class CampusVersionSchema(BaseModel):
    campus_id: str
    version: str
