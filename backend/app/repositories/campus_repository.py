from sqlalchemy.orm import Session

from app.models.campus import Campus, CampusVersion


class CampusRepository:
    def __init__(self, db: Session):
        self.db = db

    def get(self, campus_id: str) -> Campus | None:
        return self.db.get(Campus, campus_id)

    def get_first(self) -> Campus | None:
        return self.db.query(Campus).first()

    def get_latest_version(self, campus_id: str) -> CampusVersion | None:
        return (
            self.db.query(CampusVersion)
            .filter(CampusVersion.campus_id == campus_id)
            .order_by(CampusVersion.id.desc())
            .first()
        )
