def test_get_route_graph(client):
    response = client.get("/api/v1/routes")
    assert response.status_code == 200
    data = response.json()
    assert len(data["nodes"]) == 40
    assert len(data["edges"]) == 45


def test_calculate_route_to_building(client):
    response = client.post(
        "/api/v1/routes/calculate",
        json={
            "from_latitude": 35.0952,
            "from_longitude": 129.1004,
            "to_building_id": "bldg_17",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["destination_building_id"] == "bldg_17"
    assert data["total_distance_meters"] > 0
    assert data["estimated_walking_time_minutes"] > 0
    assert len(data["nodes"]) >= 2
    # Path should end at building 17's destination node
    assert data["nodes"][-1]["type"] == "destination"


def test_calculate_route_accessible_only(client):
    response = client.post(
        "/api/v1/routes/calculate",
        json={
            "from_latitude": 35.0952,
            "from_longitude": 129.1004,
            "to_building_id": "bldg_4",  # non-accessible entrance in sample data
            "accessible_only": True,
        },
    )
    # Building 4's entrance edge is marked not accessible in sample data,
    # so an accessible-only route should fail to reach the final entrance edge.
    assert response.status_code == 422


def test_calculate_route_unknown_building(client):
    response = client.post(
        "/api/v1/routes/calculate",
        json={
            "from_latitude": 35.0952,
            "from_longitude": 129.1004,
            "to_building_id": "does-not-exist",
        },
    )
    assert response.status_code == 404
