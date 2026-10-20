import 'dart:async';

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

/// Keeps the loading screen up until the first screen has its content (or a few seconds pass),
/// so there is never a blank or half-empty frame after the logo.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.ready, required this.child});

  /// True once the first screen can show real content.
  final bool ready;
  final Widget child;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _gaveUp = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _gaveUp = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showApp = widget.ready || _gaveUp;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child:
          showApp
              ? KeyedSubtree(key: const ValueKey('app'), child: widget.child)
              : const SplashLoader(key: ValueKey('splash')),
    );
  }
}
