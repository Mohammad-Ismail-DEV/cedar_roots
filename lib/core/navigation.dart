import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Lets screens refresh themselves when a route above them is popped.
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

/// Flutter gives focus back to the text field that had it when a screen is popped, which opens
/// the keyboard again on its own. Dropping focus whenever a route comes or goes stops that.
class DismissKeyboardObserver extends NavigatorObserver {
  void _dismiss() {
    void drop() => FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) => drop());
    // Focus is handed back when the pop animation ends, so drop it again after that.
    Future<void>.delayed(const Duration(milliseconds: 400), drop);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _dismiss();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _dismiss();
}
