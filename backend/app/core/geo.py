"""
Shared geographic utilities.

These are pure functions with no framework dependencies so they can be
unit tested in isolation and mirrored easily in the Flutter client
(see mobile core/utilities/geo_utils.dart).
"""
import math

EARTH_RADIUS_METERS = 6371000.0


def haversine_distance_meters(
    lat1: float, lon1: float, lat2: float, lon2: float
) -> float:
    """Great-circle distance between two lat/lon points, in meters."""
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lambda = math.radians(lon2 - lon1)

    a = (
        math.sin(d_phi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(d_lambda / 2) ** 2
    )
    c = 2 * math.asin(math.sqrt(a))
    return EARTH_RADIUS_METERS * c


def bearing_degrees(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Initial compass bearing (0-360, 0 = true north) from point 1 to point 2.

    This is the same calculation the AR navigation service uses (see
    mobile features/ar/services) to compare against device heading and
    decide which way the directional indicator should point.
    """
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    d_lambda = math.radians(lon2 - lon1)

    x = math.sin(d_lambda) * math.cos(phi2)
    y = math.cos(phi1) * math.sin(phi2) - math.sin(phi1) * math.cos(phi2) * math.cos(
        d_lambda
    )
    theta = math.atan2(x, y)
    return (math.degrees(theta) + 360) % 360


def estimate_walking_time_seconds(
    distance_meters: float, walking_speed_mps: float = 1.3
) -> float:
    """
    Estimate walking time from distance using an average adult walking
    speed (~1.3 m/s, roughly 4.7 km/h). This is a simple, transparent
    model — no hidden fudge factors — documented so it can be tuned per
    campus (e.g. slower on stairs/indoor segments) later.
    """
    if distance_meters <= 0:
        return 0.0
    return distance_meters / walking_speed_mps
