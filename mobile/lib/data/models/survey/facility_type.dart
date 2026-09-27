/// Suggested facility types (section 7 of the V1.1 spec). This is
/// deliberately a plain list of strings, not an enum — [SurveyFacility.type]
/// accepts any string, so a surveyor can type a new category in the field
/// without an app update ("make facility types extensible").
class SurveyFacilityTypes {
  SurveyFacilityTypes._();

  static const List<String> suggested = [
    'restroom',
    'elevator',
    'stairs',
    'ramp',
    'cafe',
    'restaurant',
    'convenience_store',
    'atm',
    'parking',
    'bus_stop',
    'prayer_room',
    'office',
    'classroom',
    'library',
    'emergency',
    'other',
  ];

  static String displayLabel(String type) {
    return type
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
