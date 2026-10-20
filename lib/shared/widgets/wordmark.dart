import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Cedar Roots" in the script face used across the app's header and sign-in.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Cedar Roots',
      style: GoogleFonts.grandHotel(
        fontSize: size,
        height: 1,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
