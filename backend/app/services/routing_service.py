"""
Campus pedestrian routing engine.

Implements A* shortest-path search over the RouteNode/RouteEdge graph
(see section 13 of the product spec). This is intentionally a simple,
swappable implementation: RoutingService only depends on plain node/edge
data structures, not on the database or web framework, so it can later be
replaced by a more sophisticated routing engine (e.g. one that accounts
for elevation, crowding, or indoor floor transitions) without touching
the API layer.
"""
from __future__ import annotations

import heapq
from dataclasses import dataclass, field

from app.core.geo import estimate_walking_time_seconds, haversine_distance_meters


class RouteNotFoundError(Exception):
    """Raised when no path exists between two nodes (e.g. disconnected graph,
    or accessible_only=True with no accessible path available)."""


@dataclass
class GraphNode:
    id: str
    latitude: float
    longitude: float
    type: str


@dataclass
class GraphEdge:
    id: str
    from_node: str
    to_node: str
    distance: float
    accessible: bool = True
    indoor: bool = False
    outdoor: bool = True


@dataclass
class RouteResult:
    node_ids: list[str]
    total_distance_meters: float
    estimated_walking_time_seconds: float


@dataclass
class RoutingGraph:
    """In-memory adjacency representation built from RouteNode/RouteEdge rows."""

    nodes: dict[str, GraphNode] = field(default_factory=dict)
    # adjacency[node_id] = list of (neighbor_id, edge)
    adjacency: dict[str, list[tuple[str, GraphEdge]]] = field(default_factory=dict)

    @classmethod
    def build(cls, nodes: list[GraphNode], edges: list[GraphEdge]) -> "RoutingGraph":
        graph = cls()
        for n in nodes:
            graph.nodes[n.id] = n
            graph.adjacency.setdefault(n.id, [])
        for e in edges:
            # Edges are treated as bidirectional (pedestrian pathways can be
            # walked in either direction).
            graph.adjacency.setdefault(e.from_node, []).append((e.to_node, e))
            graph.adjacency.setdefault(e.to_node, []).append((e.from_node, e))
        return graph

    def nearest_node(self, latitude: float, longitude: float) -> str:
        """Find the graph node closest to an arbitrary lat/lon (e.g. the
        user's current GPS position, which won't sit exactly on a node)."""
        if not self.nodes:
            raise RouteNotFoundError("Routing graph is empty.")
        best_id, best_dist = None, float("inf")
        for node in self.nodes.values():
            d = haversine_distance_meters(
                latitude, longitude, node.latitude, node.longitude
            )
            if d < best_dist:
                best_id, best_dist = node.id, d
        return best_id


class RoutingService:
    def __init__(self, graph: RoutingGraph, walking_speed_mps: float = 1.3):
        self.graph = graph
        self.walking_speed_mps = walking_speed_mps

    def find_route(
        self,
        from_latitude: float,
        from_longitude: float,
        to_node_id: str,
        accessible_only: bool = False,
    ) -> RouteResult:
        start_id = self.graph.nearest_node(from_latitude, from_longitude)
        if to_node_id not in self.graph.nodes:
            raise RouteNotFoundError(f"Destination node '{to_node_id}' not found.")

        node_ids = self._a_star(start_id, to_node_id, accessible_only)
        total_distance = self._path_distance(node_ids)
        return RouteResult(
            node_ids=node_ids,
            total_distance_meters=round(total_distance, 1),
            estimated_walking_time_seconds=round(
                estimate_walking_time_seconds(total_distance, self.walking_speed_mps),
                1,
            ),
        )

    def _heuristic(self, node_id: str, goal_id: str) -> float:
        a = self.graph.nodes[node_id]
        b = self.graph.nodes[goal_id]
        return haversine_distance_meters(a.latitude, a.longitude, b.latitude, b.longitude)

    def _a_star(
        self, start_id: str, goal_id: str, accessible_only: bool
    ) -> list[str]:
        open_heap: list[tuple[float, str]] = [(0.0, start_id)]
        came_from: dict[str, str] = {}
        g_score: dict[str, float] = {start_id: 0.0}
        visited: set[str] = set()

        while open_heap:
            _, current = heapq.heappop(open_heap)
            if current == goal_id:
                return self._reconstruct_path(came_from, current)
            if current in visited:
                continue
            visited.add(current)

            for neighbor_id, edge in self.graph.adjacency.get(current, []):
                if accessible_only and not edge.accessible:
                    continue
                tentative_g = g_score[current] + edge.distance
                if tentative_g < g_score.get(neighbor_id, float("inf")):
                    came_from[neighbor_id] = current
                    g_score[neighbor_id] = tentative_g
                    f_score = tentative_g + self._heuristic(neighbor_id, goal_id)
                    heapq.heappush(open_heap, (f_score, neighbor_id))

        raise RouteNotFoundError(
            f"No route found between '{start_id}' and '{goal_id}'"
            + (" using only accessible paths." if accessible_only else ".")
        )

    @staticmethod
    def _reconstruct_path(came_from: dict[str, str], current: str) -> list[str]:
        path = [current]
        while current in came_from:
            current = came_from[current]
            path.append(current)
        path.reverse()
        return path

    def _path_distance(self, node_ids: list[str]) -> float:
        total = 0.0
        for a_id, b_id in zip(node_ids, node_ids[1:]):
            for neighbor_id, edge in self.graph.adjacency[a_id]:
                if neighbor_id == b_id:
                    total += edge.distance
                    break
        return total
