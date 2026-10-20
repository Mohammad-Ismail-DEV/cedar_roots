import 'package:flutter/material.dart';

const _eventGradients = [
  [Color(0xFF11998E), Color(0xFF38EF7D)],
  [Color(0xFFFC466B), Color(0xFF3F5EFB)],
  [Color(0xFF36D1DC), Color(0xFF5B86E5)],
  [Color(0xFFF2994A), Color(0xFFF2C94C)],
  [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
];

/// A stable colourful gradient for an event (so it looks the same every time).
LinearGradient eventGradient(int eventId) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: _eventGradients[eventId.abs() % _eventGradients.length],
);
