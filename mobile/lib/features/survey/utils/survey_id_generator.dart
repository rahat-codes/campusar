import 'dart:math';

/// Generates locally-unique IDs without pulling in a `uuid` package
/// dependency (section 27 of the V1.1 spec: "Do not introduce
/// unnecessary third-party dependencies"). Timestamp + a short random
/// suffix is sufficient here — survey records are created by one
/// surveyor's device at a time, not across a distributed system.
class SurveyIdGenerator {
  SurveyIdGenerator._();
  static final _random = Random();

  static String generate(String prefix) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final suffix = _random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '${prefix}_${timestamp}_$suffix';
  }
}
