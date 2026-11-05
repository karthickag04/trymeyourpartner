import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'l10n.dart';

/// Locale-aware dates, times and numbers. Always format through these (or
/// intl with the current locale) so Tamil users see Tamil month names.
extension LocaleFormatting on BuildContext {
  String get _localeName => Localizations.localeOf(this).toString();

  /// "5 minutes ago", "Yesterday", "3 weeks ago".
  String relativeTime(DateTime when) {
    final l = l10n;
    final diff = DateTime.now().difference(when);
    if (diff.inSeconds < 60) return l.timeJustNow;
    if (diff.inMinutes < 60) return l.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l.timeHoursAgo(diff.inHours);
    if (diff.inDays == 1) return l.timeYesterday;
    if (diff.inDays < 7) return l.timeDaysAgo(diff.inDays);
    if (diff.inDays < 30) return l.timeWeeksAgo(diff.inDays ~/ 7);
    return l.timeMonthsAgo(diff.inDays ~/ 30);
  }

  /// Compact age of a timestamp for list rows: "5m", "3h", "2d", then a date.
  String shortTimeAgo(DateTime when) {
    final l = l10n;
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return l.timeJustNow;
    if (diff.inMinutes < 60) return l.timeMinutesShort(diff.inMinutes);
    if (diff.inHours < 24) return l.timeHoursShort(diff.inHours);
    if (diff.inDays < 7) return l.timeDaysShort(diff.inDays);
    return formatDate(when);
  }

  /// "5 Nov 2026" (or the locale's equivalent).
  String formatDate(DateTime when) =>
      DateFormat.yMMMd(_localeName).format(when.toLocal());

  /// "14:05" / "2:05 PM" depending on the locale.
  String formatTime(DateTime when) =>
      DateFormat.jm(_localeName).format(when.toLocal());

  /// Date and time together.
  String formatDateTime(DateTime when) =>
      DateFormat.yMMMd(_localeName).add_jm().format(when.toLocal());

  /// Grouped digits for counts.
  String formatNumber(num value) =>
      NumberFormat.decimalPattern(_localeName).format(value);

  /// Money, e.g. "₹1,499".
  String formatCurrency(num value, {String symbol = '₹'}) =>
      NumberFormat.currency(
        locale: _localeName,
        symbol: symbol,
        decimalDigits: value % 1 == 0 ? 0 : 2,
      ).format(value);
}
