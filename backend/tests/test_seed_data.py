from app.models.building import Building
from app.models.campus import Campus
from app.models.route_graph import RouteEdge, RouteNode


def test_seed_creates_campus(test_db_session):
    campus = test_db_session.query(Campus).one()
    assert campus.id == "tongmyong-main"
    assert campus.latitude != 0
    assert campus.longitude != 0


def test_seed_creates_expected_building_count(test_db_session):
    count = test_db_session.query(Building).count()
    assert count == 14


def test_seed_route_graph_is_connected_enough(test_db_session):
    node_count = test_db_session.query(RouteNode).count()
    edge_count = test_db_session.query(RouteEdge).count()
    assert node_count > 0
    assert edge_count > 0
    # Every edge should reference nodes that actually exist.
    node_ids = {n.id for n in test_db_session.query(RouteNode).all()}
    for edge in test_db_session.query(RouteEdge).all():
        assert edge.from_node in node_ids
        assert edge.to_node in node_ids


def test_seed_is_idempotent(test_db_session):
    from app.database.seed import seed_database

    before = test_db_session.query(Campus).count()
    seed_database(test_db_session)  # should be a no-op, already seeded
    after = test_db_session.query(Campus).count()
    assert before == after == 1
