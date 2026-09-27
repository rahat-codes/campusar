from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.models.building import Building
from app.models.entrance import Entrance
from app.models.facility import Facility


class BuildingRepository:
    def __init__(self, db: Session):
        self.db = db

    def list_all(self, campus_id: str | None = None) -> list[Building]:
        query = self.db.query(Building)
        if campus_id:
            query = query.filter(Building.campus_id == campus_id)
        return query.order_by(Building.building_number).all()

    def get(self, building_id: str) -> Building | None:
        return self.db.get(Building, building_id)

    def entrances_for(self, building_id: str) -> list[Entrance]:
        return (
            self.db.query(Entrance)
            .filter(Entrance.building_id == building_id)
            .all()
        )

    def facilities_for(self, building_id: str) -> list[Facility]:
        return (
            self.db.query(Facility)
            .filter(Facility.building_id == building_id)
            .all()
        )

    def search(self, query_text: str, campus_id: str | None = None) -> list[Building]:
        """
        Search by name, short name, building number, or facility name
        (section 10 of the spec). Matching buildings are returned in a
        stable order: exact building-number matches first, then name
        matches, then facility matches.
        """
        q = query_text.strip().lower()
        if not q:
            return self.list_all(campus_id)

        base = self.db.query(Building)
        if campus_id:
            base = base.filter(Building.campus_id == campus_id)

        like = f"%{q}%"
        direct_matches = base.filter(
            or_(
                Building.name.ilike(like),
                Building.short_name.ilike(like),
                Building.building_number.ilike(like),
            )
        ).all()

        matched_ids = {b.id for b in direct_matches}

        facility_building_ids = (
            self.db.query(Facility.building_id)
            .filter(Facility.name.ilike(like))
            .distinct()
            .all()
        )
        facility_building_ids = [row[0] for row in facility_building_ids]

        extra = [
            b
            for b in base.filter(Building.id.in_(facility_building_ids)).all()
            if b.id not in matched_ids
        ]

        return direct_matches + extra
