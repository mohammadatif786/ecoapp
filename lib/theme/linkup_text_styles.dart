import 'dart:io';

import 'package:flutter/material.dart';

/// Shared text styles so OpenSans never swallows emoji / symbol glyphs on iOS.
///
/// The bundled OpenSans.ttf is a Latin subset (~1k glyphs), so every emoji in
/// the app is resolved through this fallback chain.
///
/// Two ordering rules matter, and getting either wrong shows "?" boxes on iOS:
///
///  * A plain text font must come first. When the colour-emoji font leads the
///    chain, CoreText cascades outward from it and lands on Apple's LastResort
///    face for ordinary characters instead of continuing to a real text font.
///  * No broad symbol font (Apple Symbols, Noto Sans Symbols) belongs in the
///    chain. Fallback is picked from the base codepoint alone, so a symbol font
///    would claim BMP emoji such as U+2764 or U+2600 and render them as flat
///    monochrome glyphs even though the text carries U+FE0F.
///
/// Anything outside this chain still reaches the platform's own per-character
/// fallback, which is why only emoji need to be named explicitly here.
class LinkUpTextStyles {
  static const String openSans = 'OpenSans';

  static List<String> get fallbackFonts {
    if (Platform.isIOS) {
      return const ['Helvetica Neue', 'Apple Color Emoji'];
    }
    if (Platform.isAndroid) {
      return const ['Roboto', 'Noto Color Emoji'];
    }
    return const ['Segoe UI', 'Segoe UI Emoji', 'Noto Color Emoji'];
  }

  static TextStyle openSansStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: openSans,
      fontFamilyFallback: fallbackFonts,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Emoji-first, unlike [fallbackFonts], because callers pass emoji-only text.
  static List<String> get emojiFallbacks {
    if (Platform.isIOS) {
      return const ['Apple Color Emoji', 'Helvetica Neue'];
    }
    if (Platform.isAndroid) {
      return const ['Noto Color Emoji', 'Roboto'];
    }
    return const ['Segoe UI Emoji', 'Noto Color Emoji', 'Apple Color Emoji'];
  }

  /// Leaves [fontFamily] unset on purpose: naming the colour-emoji font as the
  /// primary family makes iOS apply its metrics to the whole run, which blows
  /// up word spacing around any non-emoji character.
  static TextStyle emojiOnly({double fontSize = 18}) {
    return TextStyle(
      fontSize: fontSize,
      fontFamilyFallback: emojiFallbacks,
    );
  }
}

/// Renders emoji with the platform color-emoji font (not OpenSans).
class LinkUpEmojiText extends StatelessWidget {
  final String emoji;
  final double size;

  const LinkUpEmojiText(this.emoji, {super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Text(emoji, style: LinkUpTextStyles.emojiOnly(fontSize: size));
  }
}

/// Material icons used instead of emoji on auth / marketing screens.
class LinkUpFeatureIcons {
  static const events = Icons.celebration_outlined;
  static const live = Icons.live_tv_outlined;
  static const matches = Icons.forum_outlined;
  static const wallet = Icons.account_balance_wallet_outlined;
  static const news = Icons.newspaper_outlined;
  static const marketplace = Icons.shopping_bag_outlined;
  static const security = Icons.lock_outline;
}
