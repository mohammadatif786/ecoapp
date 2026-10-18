import 'package:flutter/material.dart';

class LinkUpColors {
  static const Color brandBlue = Color(0xFF2FA4E6);
  static const Color ctaStart = Color(0xFF0EA5E9);
  static const Color ctaEnd = Color(0xFF62C8FF);
  static const Color border = Color(0xFFE6EDF7);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDivider = Color(0xFF94A3B8);
  static const Color bgTop = Color(0xFFF8FBFF);
  static const Color bgBottom = Color(0xFFF6F8FC);
  static const Color linkupBlue = Color(0xFF3FA9F5);
  static const Color linkupLime = Color(0xFFD5DE23);
  static const Color securityBg = Color(0x0F2563EB);
  static const Color securityBorder = Color(0x332563EB);
  static const Color securityText = Color(0xFF1E3A8A);
  static const Color securityBold = Color(0xFF1E40AF);
  static const Color badgeAmber = Color(0xFFF59E0B);
  static const Color badgeGreen = Color(0xFF16A34A);
  static const Color badgeRed = Color(0xFFEF4444);
  static const Color badgeBlue = Color(0xFF2563EB);
  static const Color badgeTagBg = Color(0x122FA4E6);
  static const Color badgeTagBorder = Color(0x332FA4E6);
  static const Color badgeTagText = Color(0xFF0B3B57);

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgBottom],
  );

  static const LinearGradient ctaGradient = LinearGradient(
    colors: [ctaStart, ctaEnd],
  );
}
