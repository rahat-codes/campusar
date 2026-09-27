/// Where a survey record sits in the raw → reviewed → verified →
/// production pipeline (section 22 of the V1.1 spec). Survey Mode never
/// promotes a record automatically — a human always moves it from
/// [raw] to [reviewed] to [verified] via the Review Data screen, and only
/// [verified] records are eligible for export into the production
/// dataset (see SurveyExportService).
enum SurveyStatus {
  raw,
  reviewed,
  verified,
  deprecated;

  static SurveyStatus fromString(String value) {
    return SurveyStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => SurveyStatus.raw,
    );
  }

  String get label => switch (this) {
        SurveyStatus.raw => 'Raw',
        SurveyStatus.reviewed => 'Reviewed',
        SurveyStatus.verified => 'Verified',
        SurveyStatus.deprecated => 'Deprecated',
      };
}
