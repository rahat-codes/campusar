from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.database.session import get_db
from app.repositories.campus_repository import CampusRepository
from app.schemas.campus import CampusSchema, CampusVersionSchema

router = APIRouter(prefix="/campus", tags=["campus"])
settings = get_settings()


@router.get("", response_model=CampusSchema)
def get_campus(db: Session = Depends(get_db)):
    repo = CampusRepository(db)
    campus = repo.get(settings.CAMPUS_ID) or repo.get_first()
    if campus is None:
        raise HTTPException(status_code=404, detail="Campus not found. Has the database been seeded?")
    return campus


@router.get("/version", response_model=CampusVersionSchema)
def get_campus_version(db: Session = Depends(get_db)):
    repo = CampusRepository(db)
    campus = repo.get(settings.CAMPUS_ID) or repo.get_first()
    if campus is None:
        raise HTTPException(status_code=404, detail="Campus not found. Has the database been seeded?")
    version_row = repo.get_latest_version(campus.id)
    version = version_row.version if version_row else campus.version
    return CampusVersionSchema(campus_id=campus.id, version=version)
