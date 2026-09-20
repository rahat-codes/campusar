import math

from app.core.geo import (
    bearing_degrees,
    estimate_walking_time_seconds,
    haversine_distance_meters,
)


def test_haversine_distance_zero_for_same_point():
    d = haversine_distance_meters(35.0952, 129.1004, 35.0952, 129.1004)
    assert d == 0


def test_haversine_distance_known_value():
    # ~111.32 km per degree of latitude at the equator-ish scale; one full
    # degree of latitude difference should be roughly 111km regardless of longitude.
    d = haversine_distance_meters(0.0, 0.0, 1.0, 0.0)
    assert math.isclose(d, 111195, rel_tol=0.01)


def test_bearing_due_north():
    b = bearing_degrees(35.0, 129.0, 35.001, 129.0)
    assert math.isclose(b, 0.0, abs_tol=1.0)


def test_bearing_due_east():
    b = bearing_degrees(35.0, 129.0, 35.0, 129.001)
    assert math.isclose(b, 90.0, abs_tol=1.0)


def test_estimate_walking_time_seconds():
    t = estimate_walking_time_seconds(130, walking_speed_mps=1.3)
    assert t == 100.0


def test_estimate_walking_time_zero_distance():
    assert estimate_walking_time_seconds(0) == 0.0
