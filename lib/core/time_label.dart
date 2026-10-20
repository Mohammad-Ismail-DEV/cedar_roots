import 'package:intl/intl.dart';

/// "2 HOURS AGO" style label under a post. Falls back to a date after a week.
String timeAgoLabel(DateTime? when, {DateTime? now}) {
  if (when == null) return '';
  final current = now ?? DateTime.now();
  final diff = current.difference(when);

  String unit(int n, String one) => '$n ${n == 1 ? one : '${one}S'} AGO';

  if (diff.inSeconds < 60) return 'JUST NOW';
  if (diff.inMinutes < 60) return unit(diff.inMinutes, 'MINUTE');
  if (diff.inHours < 24) return unit(diff.inHours, 'HOUR');
  if (diff.inDays < 7) return unit(diff.inDays, 'DAY');

  final format =
      when.year == current.year
          ? DateFormat('MMMM d')
          : DateFormat('MMMM d, y');
  return format.format(when).toUpperCase();
}

/// Compact "2h" / "3d" form for story headers and notification rows.
String shortAgo(DateTime? when, {DateTime? now}) {
  if (when == null) return '';
  final diff = (now ?? DateTime.now()).difference(when);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${(diff.inDays / 7).floor()}w';
}
