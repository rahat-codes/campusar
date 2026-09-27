import 'package:campusar/core/constants/app_constants.dart';

/// Coarse walking direction derived from a relative bearing (section 18
/// of the product spec: "Convert relative bearing into: left / slightly
/// left / straight / slightly right / right / U-turn"). Kept in
/// `core/utilities` (not inside features/ar) so both the AR screen and
/// the plain map-based Navigation screen can show the same instruction
/// wording from one source of truth.
enum RelativeDirection {
  straight,
  slightlyLeft,
  left,
  slightlyRight,
  right,
  uTurn;

  String get label => switch (this) {
        RelativeDirection.straight => 'Straight ahead',
        RelativeDirection.slightlyLeft => 'Slightly left',
        RelativeDirection.left => 'Turn left',
        RelativeDirection.slightlyRight => 'Slightly right',
        RelativeDirection.right => 'Turn right',
        RelativeDirection.uTurn => 'Turn around',
      };
}

/// Configurable thresholds (in degrees) for bucketing a signed relative
/// bearing (-180..180, 0 = straight ahead) into a [RelativeDirection].
/// Deliberately not hardcoded to one "unrealistic universal" set of
/// numbers — see section 18: "Use configurable thresholds."
class DirectionThresholds {
  const DirectionThresholds({
    this.straightMaxDegrees = 15,
    this.slightMaxDegrees = 45,
    this.uTurnMinDegrees = 150,
  });

  /// |relativeBearing| at or below this is "straight ahead".
  final double straightMaxDegrees;

  /// |relativeBearing| at or below this (and above [straightMaxDegrees])
  /// is "slightly left/right"; above it, a full "left/right".
  final double slightMaxDegrees;

  /// |relativeBearing| at or above this is treated as a U-turn.
  final double uTurnMinDegrees;

  static const defaults = DirectionThresholds();

  RelativeDirection classify(double relativeBearingDegrees) {
    final magnitude = relativeBearingDegrees.abs();
    final isRight = relativeBearingDegrees > 0;

    if (magnitude >= uTurnMinDegrees) return RelativeDirection.uTurn;
    if (magnitude <= straightMaxDegrees) return RelativeDirection.straight;
    if (magnitude <= slightMaxDegrees) {
      return isRight ? RelativeDirection.slightlyRight : RelativeDirection.slightlyLeft;
    }
    return isRight ? RelativeDirection.right : RelativeDirection.left;
  }
}

/// Arrival detection (section 19): "distance < configurable threshold".
/// [thresholdMeters] defaults to [AppConstants.arrivalThresholdMeters] so
/// every screen agrees on the same distance without duplicating the
/// number, but callers can override it (e.g. a larger threshold for a
/// building with a wide plaza entrance).
bool hasArrivedAtDestination(
  double distanceMeters, {
  double thresholdMeters = AppConstants.arrivalThresholdMeters,
}) {
  return distanceMeters <= thresholdMeters;
}
