def test_get_campus(client):
    response = client.get("/api/v1/campus")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == "tongmyong-main"
    assert data["university_name"] == "Tongmyong University"
    assert data["city"] == "Busan"


def test_get_campus_version(client):
    response = client.get("/api/v1/campus/version")
    assert response.status_code == 200
    data = response.json()
    assert data["campus_id"] == "tongmyong-main"
    assert data["version"] == "1.0.0"
