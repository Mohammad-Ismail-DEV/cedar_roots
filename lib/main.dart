import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers.dart';
import 'firebase_options.dart';
import 'shared/widgets/splash_loader.dart';

// Screens that have not been migrated yet still import these from main.dart.
export 'core/navigation.dart';

Future<SharedPreferences> _start() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  return SharedPreferences.getInstance();
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Boot());
}

/// Shows the loading screen straight away and swaps in the app once Firebase and the saved
/// settings are ready.
class _Boot extends StatefulWidget {
  const _Boot();

  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  late final Future<SharedPreferences> _ready = _start();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _ready,
      builder: (context, snapshot) {
        final prefs = snapshot.data;
        if (prefs != null) {
          return ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: const CedarRootsApp(),
          );
        }
        return const Directionality(
          textDirection: TextDirection.ltr,
          child: SplashLoader(),
        );
      },
    );
  }
}
