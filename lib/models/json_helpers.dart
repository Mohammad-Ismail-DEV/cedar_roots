int asInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

int? asIntOrNull(Object? value) => value == null ? null : asInt(value);

DateTime? asDate(Object? value) =>
    value == null ? null : DateTime.tryParse('$value')?.toLocal();

String? asStringOrNull(Object? value) => value?.toString();

Map<String, dynamic>? asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

List<Map<String, dynamic>> asMapList(Object? value) =>
    value is List
        ? value
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList()
        : const [];
