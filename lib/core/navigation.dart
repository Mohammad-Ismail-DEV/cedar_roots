import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Lets screens refresh themselves when a route above them is popped.
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
