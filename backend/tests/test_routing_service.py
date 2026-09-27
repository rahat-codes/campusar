import pytest

from app.services.routing_service import (
    GraphEdge,
    GraphNode,
    RouteNotFoundError,
    RoutingGraph,
    RoutingService,
)


def build_simple_graph():
    # A --5m-- B --5m-- C  (a straight line, 10m total A->C)
    #          |
    #          10m (inaccessible)
    #          |
    #          D
    nodes = [
        GraphNode("A", 35.0, 129.0, "pathway"),
        GraphNode("B", 35.00004, 129.0, "intersection"),
        GraphNode("C", 35.00009, 129.0, "destination"),
        GraphNode("D", 35.00004, 129.0001, "destination"),
    ]
    edges = [
        GraphEdge("e1", "A", "B", distance=5.0, accessible=True),
        GraphEdge("e2", "B", "C", distance=5.0, accessible=True),
        GraphEdge("e3", "B", "D", distance=10.0, accessible=False),
    ]
    return RoutingGraph.build(nodes, edges)


def test_find_route_simple_path():
    graph = build_simple_graph()
    service = RoutingService(graph)
    result = service.find_route(35.0, 129.0, "C")
    assert result.node_ids == ["A", "B", "C"]
    assert result.total_distance_meters == 10.0
    assert result.estimated_walking_time_seconds > 0


def test_find_route_snaps_to_nearest_node():
    graph = build_simple_graph()
    service = RoutingService(graph)
    # Start slightly off of node A but still closest to it.
    result = service.find_route(35.000001, 129.000001, "C")
    assert result.node_ids[0] == "A"
    assert result.node_ids[-1] == "C"


def test_find_route_accessible_only_excludes_inaccessible_edge():
    graph = build_simple_graph()
    service = RoutingService(graph)
    with pytest.raises(RouteNotFoundError):
        service.find_route(35.0, 129.0, "D", accessible_only=True)

    # Without the accessibility restriction the same destination is reachable.
    result = service.find_route(35.0, 129.0, "D", accessible_only=False)
    assert result.node_ids == ["A", "B", "D"]


def test_find_route_unknown_destination_raises():
    graph = build_simple_graph()
    service = RoutingService(graph)
    with pytest.raises(RouteNotFoundError):
        service.find_route(35.0, 129.0, "Z")
