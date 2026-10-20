import 'package:flutter/material.dart';

/// The start-up screen: the logo mark where the native splash puts it, with a spinner below so
/// people can tell the app is still loading. The native splash itself cannot animate.
class SplashLoader extends StatelessWidget {
  const SplashLoader({super.key});

  static const background = Color(0xFF0F3D2E);
  static const _ink = Color(0xFFF4EFE0);

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: background,
      child: Stack(
        children: [
          Center(
            child: Image(
              image: AssetImage('assets/icon/logo_mark.png'),
              width: 150,
            ),
          ),
          Align(
            alignment: Alignment(0, 0.62),
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3, color: _ink),
            ),
          ),
        ],
      ),
    );
  }
}
