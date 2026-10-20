import 'package:flutter/material.dart';

/// Colours the Material theme has no slot for. Read with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.muted,
    required this.border,
    required this.inputBg,
    required this.heart,
    required this.danger,
    required this.avatarBg,
    required this.avatarInk,
  });

  /// Secondary text and inactive icons.
  final Color muted;

  /// Hairline dividers and outlines.
  final Color border;

  /// Search boxes, chips and secondary buttons.
  final Color inputBg;

  /// Liked hearts and notification badges.
  final Color heart;

  /// Destructive text (delete, sign out of a dangerous action).
  final Color danger;

  /// Placeholder avatar and tile backgrounds.
  final Color avatarBg;
  final Color avatarInk;

  static const light = AppPalette(
    muted: Color(0xFF737373),
    border: Color(0xFFDBDBDB),
    inputBg: Color(0xFFEFEFEF),
    heart: Color(0xFFED4956),
    danger: Color(0xFFC62828),
    avatarBg: Color(0xFFE4E4E4),
    avatarInk: Color(0xFF262626),
  );

  static const dark = AppPalette(
    muted: Color(0xFFA8A8A8),
    border: Color(0xFF363636),
    inputBg: Color(0xFF262626),
    heart: Color(0xFFFF3040),
    danger: Color(0xFFFF8F85),
    avatarBg: Color(0xFF3A3A3A),
    avatarInk: Color(0xFFF5F5F5),
  );

  @override
  AppPalette copyWith({
    Color? muted,
    Color? border,
    Color? inputBg,
    Color? heart,
    Color? danger,
    Color? avatarBg,
    Color? avatarInk,
  }) => AppPalette(
    muted: muted ?? this.muted,
    border: border ?? this.border,
    inputBg: inputBg ?? this.inputBg,
    heart: heart ?? this.heart,
    danger: danger ?? this.danger,
    avatarBg: avatarBg ?? this.avatarBg,
    avatarInk: avatarInk ?? this.avatarInk,
  );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
      heart: Color.lerp(heart, other.heart, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      avatarBg: Color.lerp(avatarBg, other.avatarBg, t)!,
      avatarInk: Color.lerp(avatarInk, other.avatarInk, t)!,
    );
  }
}

extension PaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

/// The signature ring around an author with something new.
const storyRingGradient = LinearGradient(
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
  colors: [Color(0xFFF9CE34), Color(0xFFEE2A7B), Color(0xFF6228D7)],
);

const accentBlue = Color(0xFF0077D9);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final palette = dark ? AppPalette.dark : AppPalette.light;
  final bg = dark ? Colors.black : Colors.white;
  final text = dark ? const Color(0xFFF5F5F5) : const Color(0xFF262626);

  final scheme = ColorScheme.fromSeed(
    seedColor: accentBlue,
    brightness: brightness,
  ).copyWith(
    primary: accentBlue,
    onPrimary: Colors.white,
    surface: bg,
    onSurface: text,
    error: palette.danger,
    outline: palette.border,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    dividerColor: palette.border,
    dividerTheme: DividerThemeData(
      color: palette.border,
      thickness: 1,
      space: 1,
    ),
    extensions: [palette],
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: text,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.inputBg,
      hintStyle: TextStyle(color: palette.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: palette.muted, width: 1),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentBlue,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        minimumSize: const Size(44, 44),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: dark ? const Color(0xFF262626) : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? const Color(0xFF262626) : Colors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: text,
      contentTextStyle: TextStyle(color: bg, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: dark ? const Color(0xFF262626) : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: accentBlue),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoLikeTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoLikeTransitionsBuilder(),
      },
    ),
  );
}

/// Plain horizontal slide, no Material zoom, to match the Instagram-style flow.
class CupertinoLikeTransitionsBuilder extends PageTransitionsBuilder {
  const CupertinoLikeTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    );
  }
}
