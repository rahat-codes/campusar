from pydantic import BaseModel


class RouteNodeSchema(BaseModel):
    id: str
    latitude: float
    longitude: float
    type: str


class RouteRequestSchema(BaseModel):
    """
    Request to compute a walking route.

    from_latitude/from_longitude represent the user's current GPS position;
    to_building_id is the destination building. Set accessible_only=True to
    restrict the route to accessible (wheelchair-friendly) edges only.
    """

    from_latitude: float
    from_longitude: float
    to_building_id: str
    accessible_only: bool = False


class RouteResponseSchema(BaseModel):
    destination_building_id: str
    destination_building_name: str
    nodes: list[RouteNodeSchema]
    total_distance_meters: float
    estimated_walking_time_seconds: float
    estimated_walking_time_minutes: float
