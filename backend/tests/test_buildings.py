def test_list_buildings(client):
    response = client.get("/api/v1/buildings")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 14
    numbers = {b["building_number"] for b in data}
    assert "17" in numbers


def test_search_by_number(client):
    response = client.get("/api/v1/buildings", params={"q": "17"})
    assert response.status_code == 200
    data = response.json()
    assert any(b["building_number"] == "17" for b in data)


def test_search_by_facility(client):
    response = client.get("/api/v1/buildings", params={"q": "library"})
    assert response.status_code == 200
    data = response.json()
    assert any("Library" in b["name"] for b in data)


def test_search_by_short_name(client):
    response = client.get("/api/v1/buildings", params={"q": "gymnasium"})
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 1


def test_get_building_detail(client):
    response = client.get("/api/v1/buildings/bldg_17")
    assert response.status_code == 200
    data = response.json()
    assert data["building_number"] == "17"
    assert len(data["entrances"]) >= 1
    assert len(data["facilities"]) >= 1


def test_get_building_detail_with_distance(client):
    response = client.get(
        "/api/v1/buildings/bldg_17",
        params={"latitude": 35.0952, "longitude": 129.1004},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["distance_from_user_meters"] is not None
    assert data["distance_from_user_meters"] > 0


def test_get_building_not_found(client):
    response = client.get("/api/v1/buildings/does-not-exist")
    assert response.status_code == 404
