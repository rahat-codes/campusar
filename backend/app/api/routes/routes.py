from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database.session import get_db
from app.repositories.building_repository import BuildingRepository
from app.repositories.route_repository import RouteRepository
from app.schemas.route import RouteNodeSchema, RouteRequestSchema, RouteResponseSchema
from app.services.routing_service import (
    GraphEdge,
    GraphNode,
    RouteNotFoundError,
    RoutingGraph,
    RoutingService,
)

router = APIRouter(prefix="/routes", tags=["routes"])


def _load_graph(db: Session) -> RoutingGraph:
    route_repo = RouteRepository(db)
    nodes = [
        GraphNode(id=n.id, latitude=n.latitude, longitude=n.longitude, type=n.type)
        for n in route_repo.all_nodes()
    ]
    edges = [
        GraphEdge(
            id=e.id,
            from_node=e.from_node,
            to_node=e.to_node,
            distance=e.distance,
            accessible=e.accessible,
            indoor=e.indoor,
            outdoor=e.outdoor,
        )
        for e in route_repo.all_edges()
    ]
    return RoutingGraph.build(nodes, edges)


@router.get("")
def get_route_graph(db: Session = Depends(get_db)):
    """
    Returns the full pedestrian route graph (nodes + edges) so an offline
    client can sync it and run routing locally (see README "Offline
    architecture"). For an on-demand server-calculated route, use POST
    /api/v1/routes/calculate instead.
    """
    route_repo = RouteRepository(db)
    nodes = route_repo.all_nodes()
    edges = route_repo.all_edges()
    return {
        "nodes": [
            {"id": n.id, "latitude": n.latitude, "longitude": n.longitude, "type": n.type}
            for n in nodes
        ],
        "edges": [
            {
                "id": e.id,
                "fromNode": e.from_node,
                "toNode": e.to_node,
                "distance": e.distance,
                "accessible": e.accessible,
                "indoor": e.indoor,
                "outdoor": e.outdoor,
            }
            for e in edges
        ],
    }


@router.post("/calculate", response_model=RouteResponseSchema)
def calculate_route(request: RouteRequestSchema, db: Session = Depends(get_db)):
    building_repo = BuildingRepository(db)
    building = building_repo.get(request.to_building_id)
    if building is None:
        raise HTTPException(
            status_code=404, detail=f"Building '{request.to_building_id}' not found."
        )
    if not building.destination_node_id:
        raise HTTPException(
            status_code=422,
            detail=f"Building '{request.to_building_id}' has no destination node configured.",
        )

    graph = _load_graph(db)
    service = RoutingService(graph)

    try:
        result = service.find_route(
            from_latitude=request.from_latitude,
            from_longitude=request.from_longitude,
            to_node_id=building.destination_node_id,
            accessible_only=request.accessible_only,
        )
    except RouteNotFoundError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc

    nodes = [
        RouteNodeSchema(
            id=graph.nodes[node_id].id,
            latitude=graph.nodes[node_id].latitude,
            longitude=graph.nodes[node_id].longitude,
            type=graph.nodes[node_id].type,
        )
        for node_id in result.node_ids
    ]

    return RouteResponseSchema(
        destination_building_id=building.id,
        destination_building_name=building.name,
        nodes=nodes,
        total_distance_meters=result.total_distance_meters,
        estimated_walking_time_seconds=result.estimated_walking_time_seconds,
        estimated_walking_time_minutes=round(result.estimated_walking_time_seconds / 60, 1),
    )
