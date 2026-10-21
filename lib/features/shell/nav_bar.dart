import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../shared/widgets/user_avatar.dart';
import '../events/events_screen.dart';
import '../feed/home_screen.dart';
import '../profile/profile_provider.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import 'app_routes.dart';

/// The app shell: Home, Search, Create (opens the post composer), Events and Profile.
class NavBar extends ConsumerStatefulWidget {
  const NavBar({super.key, this.initialIndex = 0});

  /// Which tab to start on: 0 Home, 1 Search, 2 Events, 3 Profile.
  final int initialIndex;

  @override
  ConsumerState<NavBar> createState() => _NavBarState();
}

class _NavBarState extends ConsumerState<NavBar> {
  late int _tab = widget.initialIndex;
  late final PageController _pages = PageController(initialPage: _tab);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Switches tab with a slide; swiping sideways between the pages does the same.
  void _go(int index) {
    if (index == _tab) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  static const _screens = <Widget>[
    HomeScreen(),
    SearchScreen(),
    EventsScreen(),
    ProfileScreen(),
  ];

  DateTime? _lastBack;

  /// Back goes to Home from the other tabs; on Home a second press within two seconds exits.
  void _onBack() {
    if (_tab != 0) {
      _go(0);
      return;
    }
    final now = DateTime.now();
    final last = _lastBack;
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _lastBack = now;
    showSnack(context, 'Press back again to exit');
  }

  Future<void> _create() async {
    if (ref.read(currentUserIdProvider) == null) {
      showSnack(context, 'Login to create a post');
      return;
    }
    await Navigator.push(context, AppRoutes.createPost());
  }

  Widget _item({
    required String label,
    required Widget icon,
    required VoidCallback onTap,
    required bool selected,
  }) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkResponse(
          onTap: onTap,
          radius: 32,
          child: SizedBox(height: 52, child: Center(child: icon)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = Theme.of(context).colorScheme.onSurface;
    final me = ref.watch(currentUserIdProvider);
    final user =
        me == null ? null : ref.watch(profileProvider(me)).valueOrNull?.user;

    Widget glyph(IconData outline, IconData filled, bool selected) =>
        Icon(selected ? filled : outline, size: 27, color: color);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        body: PageView(
          controller: _pages,
          // On my Saved tab a sideways swipe goes back to Posts, not to another tab.
          physics:
              _tab == 3 && ref.watch(savedTabProvider)
                  ? const NeverScrollableScrollPhysics()
                  : null,
          onPageChanged: (index) {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _tab = index);
          },
          children: [for (final screen in _screens) _KeepAlive(child: screen)],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: palette.border)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                _item(
                  label: 'Home',
                  selected: _tab == 0,
                  icon: glyph(
                    Icons.home_outlined,
                    Icons.home_filled,
                    _tab == 0,
                  ),
                  onTap: () => _go(0),
                ),
                _item(
                  label: 'Search',
                  selected: _tab == 1,
                  icon: Icon(
                    Icons.search,
                    size: _tab == 1 ? 30 : 27,
                    color: color,
                    weight: _tab == 1 ? 800 : 400,
                  ),
                  onTap: () => _go(1),
                ),
                _item(
                  label: 'Create a post',
                  selected: false,
                  icon: Icon(Icons.add_box_outlined, size: 27, color: color),
                  onTap: _create,
                ),
                _item(
                  label: 'Events',
                  selected: _tab == 2,
                  icon: glyph(
                    Icons.calendar_month_outlined,
                    Icons.calendar_month,
                    _tab == 2,
                  ),
                  onTap: () => _go(2),
                ),
                _item(
                  label: 'Profile',
                  selected: _tab == 3,
                  icon: Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          _tab == 3
                              ? Border.all(color: color, width: 1.5)
                              : null,
                    ),
                    child: UserAvatar(
                      name: user?.name ?? '?',
                      imageUrl: user?.profilePic,
                      blob: user?.profilePicBlob,
                      radius: 12,
                      backgroundColor: palette.avatarBg,
                    ),
                  ),
                  onTap: () => _go(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps a tab's state (scroll position, loaded data) while it is off screen, as the old
/// IndexedStack did.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
