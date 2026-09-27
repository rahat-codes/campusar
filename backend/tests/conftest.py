import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database.seed import seed_database
from app.database.session import Base, get_db
from app.main import app


@pytest.fixture()
def test_db_session():
    # StaticPool is required for SQLite ":memory:" databases in tests: without
    # it, every new connection checked out of the pool gets its own blank
    # in-memory database, so tables created in one connection would be
    # invisible to queries made through another.
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base.metadata.create_all(bind=engine)

    db = TestingSessionLocal()
    seed_database(db)
    yield db
    db.close()


@pytest.fixture()
def client(test_db_session):
    def override_get_db():
        try:
            yield test_db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()
