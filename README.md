# cedar_roots

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Running against the server

The server is exposed through a static ngrok domain (`ngrok http --url=heavily-primary-mallard.ngrok-free.app 3000`), and its address lives in `env/dev.json`. Pass that file to any run or build:

```
flutter run --dart-define-from-file=env/dev.json
flutter build apk --dart-define-from-file=env/dev.json
```

Without it the app uses `http://localhost:3000` (`http://10.0.2.2:3000` on the Android emulator).
