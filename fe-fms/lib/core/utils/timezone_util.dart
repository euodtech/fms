/// Manila timezone utility (Asia/Manila, UTC+8, no DST).
class ManilaTimezone {
  static const Duration offset = Duration(hours: 8);

  /// Converts a [DateTime] to Manila timezone (UTC+8).
  static DateTime convert(DateTime dt) {
    final utc = dt.toUtc();
    return utc.add(offset);
  }

  /// Returns the current time in Manila timezone.
  static DateTime now() {
    return DateTime.now().toUtc().add(offset);
  }
}
