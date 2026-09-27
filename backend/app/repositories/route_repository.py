from sqlalchemy.orm import Session

from app.models.route_graph import RouteEdge, RouteNode


class RouteRepository:
    def __init__(self, db: Session):
        self.db = db

    def all_nodes(self) -> list[RouteNode]:
        return self.db.query(RouteNode).all()

    def all_edges(self) -> list[RouteEdge]:
        return self.db.query(RouteEdge).all()
