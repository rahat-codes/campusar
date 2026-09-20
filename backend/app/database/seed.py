"""
Seeds the database from the bundled sample campus dataset
(app/data/seed/*.json — see section 26 of the product spec).

This is intentionally file-based rather than hand-written INSERT
statements so the *same* JSON files can be dropped into the Flutter app's
assets/data/ directory for offline-first bundled data (section 7), keeping
backend and mobile in sync from one canonical source. Replace the files in
app/data/seed/ with verified Tongmyong University data to go live with
real campus information — see README "How to Replace Campus Data".
"""
import datetime
import json
from pathlib import Path

from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models.building import Building
from app.models.campus import Campus, CampusVersion
from app.models.entrance import Entrance
from app.models.facility import Facility
from app.models.route_graph import RouteEdge, RouteNode

settings = get_settings()


def _seed_dir() -> Path:
    return Path(__file__).resolve().parents[1] / "data" / "seed"


def _load_json(filename: str) -> dict:
    with open(_seed_dir() / filename, encoding="utf-8") as f:
        return json.load(f)


def is_seeded(db: Session) -> bool:
    return db.query(Campus).count() > 0


def seed_database(db: Session, force: bool = False) -> None:
    if is_seeded(db) and not force:
        return

    if force:
        for model in (Facility, Entrance, RouteEdge, RouteNode, Building, CampusVersion, Campus):
            db.query(model).delete()

    campus_data = _load_json("campus.json")
    buildings_data = _load_json("buildings.json")
    routes_data = _load_json("routes.json")
    facilities_data = _load_json("facilities.json")
    entrances_data = _load_json("entrances.json")

    campus = Campus(
        id=campus_data["id"],
        name=campus_data["name"],
        university_name=campus_data["universityName"],
        country=campus_data["country"],
        city=campus_data["city"],
        latitude=campus_data["latitude"],
        longitude=campus_data["longitude"],
        map_configuration=campus_data["mapConfiguration"],
        version=campus_data["version"],
    )
    db.add(campus)

    db.add(
        CampusVersion(
            campus_id=campus.id,
            version=campus.version,
            published_at=datetime.datetime.now(datetime.UTC).isoformat(),
        )
    )

    for b in buildings_data["buildings"]:
        db.add(
            Building(
                id=b["id"],
                campus_id=b["campusId"],
                name=b["name"],
                short_name=b["shortName"],
                building_number=b["buildingNumber"],
                latitude=b["latitude"],
                longitude=b["longitude"],
                description=b["description"],
                image=b["image"],
                floors=b["floors"],
                entrance_ids=b["entrances"],
                facility_ids=b["facilityIds"],
                accessibility=b["accessibility"],
                destination_node_id=b.get("destinationNodeId"),
                entrance_node_id=b.get("entranceNodeId"),
            )
        )

    for e in entrances_data["entrances"]:
        db.add(
            Entrance(
                id=e["id"],
                building_id=e["buildingId"],
                latitude=e["latitude"],
                longitude=e["longitude"],
                floor=e["floor"],
                name=e["name"],
            )
        )

    for fac in facilities_data["facilities"]:
        db.add(
            Facility(
                id=fac["id"],
                building_id=fac["buildingId"],
                name=fac["name"],
                category=fac["category"],
            )
        )

    for n in routes_data["nodes"]:
        db.add(
            RouteNode(
                id=n["id"],
                latitude=n["latitude"],
                longitude=n["longitude"],
                type=n["type"],
            )
        )

    for e in routes_data["edges"]:
        db.add(
            RouteEdge(
                id=e["id"],
                from_node=e["fromNode"],
                to_node=e["toNode"],
                distance=e["distance"],
                accessible=e["accessible"],
                indoor=e["indoor"],
                outdoor=e["outdoor"],
            )
        )

    db.commit()
