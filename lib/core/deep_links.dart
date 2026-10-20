import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/shell/app_routes.dart';
import 'config.dart';
import 'logger.dart';
import 'navigation.dart';
import 'session.dart';

const deepLinkScheme = 'cedarroots';

/// The link people paste or tap to open a post: `cedarroots://post/123`.
String postLink(int postId) => '$deepLinkScheme://post/$postId';

/// The web link shared outside the app. Chat apps show a preview of the post from it, and its
/// page has a button that opens the app at the post.
String postShareUrl(int postId) => '${AppConfig.apiUrl}/p/$postId';

/// What goes in the system share sheet: who posted, a bit of the text, then the link.
String postShareText({String? author, String? content, required int postId}) {
  final text = (content ?? '').trim();
  final snippet =
      text.length > 140 ? '${text.substring(0, 139).trimRight()}…' : text;
  return [
    '${author ?? 'A post'} on Cedar Roots',
    if (snippet.isNotEmpty) '"$snippet"',
    postShareUrl(postId),
  ].join('\n\n');
}

enum DeepLinkKind { post, event, profile, organization }

class DeepLink {
  const DeepLink(this.kind, this.id);

  final DeepLinkKind kind;
  final int id;
}

/// Understands `cedarroots://post/1`, `/event/2`, `/profile/3` and `/organization/4`.
/// Anything else (another scheme, a bad id) is null.
DeepLink? parseDeepLink(Uri uri) {
  // The shared web link, https://<server>/p/123, opens the same post.
  if ((uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.pathSegments.length == 2 &&
      uri.pathSegments.first == 'p') {
    final id = int.tryParse(uri.pathSegments[1]);
    return id == null || id <= 0 ? null : DeepLink(DeepLinkKind.post, id);
  }
  if (uri.scheme != deepLinkScheme) return null;

  final kind = switch (uri.host) {
    'post' => DeepLinkKind.post,
    'event' => DeepLinkKind.event,
    'profile' => DeepLinkKind.profile,
    'organization' => DeepLinkKind.organization,
    _ => null,
  };
  if (kind == null || uri.pathSegments.isEmpty) return null;

  final id = int.tryParse(uri.pathSegments.first);
  return id == null || id <= 0 ? null : DeepLink(kind, id);
}

Route<void> routeFor(DeepLink link) => switch (link.kind) {
  DeepLinkKind.post => AppRoutes.post(link.id),
  DeepLinkKind.event => AppRoutes.event(link.id),
  DeepLinkKind.profile => AppRoutes.profile(link.id),
  DeepLinkKind.organization => AppRoutes.organization(link.id),
};

/// Opens links that arrive while the app is running or that launched it. A link that arrives
/// while signed out waits until someone signs in. Watch once near the app root.
final deepLinksProvider = Provider<void>((ref) {
  final appLinks = AppLinks();
  DeepLink? pending;
  // The launch link can arrive both as the initial link and on the stream.
  String? lastUri;
  DateTime lastAt = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> open(DeepLink link) async {
    // On a cold start the navigator may not be built yet; give it a moment.
    for (var i = 0; i < 15; i++) {
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        navigator.push(routeFor(link));
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  void handle(Uri uri) {
    final link = parseDeepLink(uri);
    if (link == null) return;
    final now = DateTime.now();
    if (lastUri == '$uri' &&
        now.difference(lastAt) < const Duration(seconds: 2)) {
      return;
    }
    lastUri = '$uri';
    lastAt = now;
    AppLog.d('deep link $uri', 'links');
    if (ref.read(currentUserIdProvider) == null) {
      pending = link;
      return;
    }
    unawaited(open(link));
  }

  final subscription = appLinks.uriLinkStream.listen(handle);
  appLinks.getInitialLink().then((uri) {
    if (uri != null) handle(uri);
  });

  ref.listen<Session?>(sessionProvider, (_, session) {
    final waiting = pending;
    if (session != null && waiting != null) {
      pending = null;
      unawaited(open(waiting));
    }
  });

  ref.onDispose(subscription.cancel);
});
