import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/model/user_model.dart';

/// Single source of truth for current signed-in user's display data.
/// Use this anywhere the app needs current user's name/avatar/handle.
class LinkUpCurrentUser {
  LinkUpCurrentUser._();

  static String get _authTag => AuthController().toString();

  static AuthController? get controller {
    try {
      if (Get.isRegistered<AuthController>(tag: _authTag)) {
        return Get.find<AuthController>(tag: _authTag);
      }

      if (Get.isRegistered<AuthController>()) {
        return Get.find<AuthController>();
      }
    } catch (_) {}

    return null;
  }

  static UserModel? get user {
    try {
      final dynamic c = controller;
      final dynamic value = c?.user?.value ?? c?.userModel?.value ?? c?.currentUser?.value;
      if (value is UserModel) return value;
    } catch (_) {}

    return null;
  }

  static dynamic get _rawUser {
    try {
      final dynamic c = controller;
      return c?.user?.value ?? c?.userModel?.value ?? c?.currentUser?.value ?? user;
    } catch (_) {
      return user;
    }
  }

  static String _firstNonEmpty(
    List<String? Function(dynamic user)> readers, {
    String fallback = '',
  }) {
    final dynamic u = _rawUser;
    if (u == null) return fallback;

    for (final read in readers) {
      try {
        final value = read(u);
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      } catch (_) {}
    }

    return fallback;
  }

  static String firstName({String fallback = 'Guest'}) {
    final full = displayName(fallback: '');
    final direct = _firstNonEmpty(
      [
        (u) => u.firstName,
        (u) => u.firstname,
        (u) => u.first_name,
        (u) => u.fName,
        (u) => u.fname,
      ],
      fallback: '',
    );

    if (direct.isNotEmpty) return direct;
    if (full.isNotEmpty) return full.split(' ').first;

    return fallback;
  }

  static String lastName({String fallback = ''}) {
    final direct = _firstNonEmpty(
      [
        (u) => u.lastName,
        (u) => u.lastname,
        (u) => u.last_name,
        (u) => u.lName,
        (u) => u.lname,
      ],
      fallback: '',
    );

    if (direct.isNotEmpty) return direct;

    final full = displayName(fallback: '');
    final parts = full.split(' ').where((e) => e.trim().isNotEmpty).toList();
    if (parts.length > 1) return parts.skip(1).join(' ');

    return fallback;
  }

  static String displayName({String fallback = 'Guest User'}) {
    final direct = _firstNonEmpty(
      [
        (u) => u.fullName,
        (u) => u.fullname,
        (u) => u.full_name,
        (u) => u.name,
        (u) => u.displayName,
        (u) => u.userName,
        (u) => u.username,
      ],
      fallback: '',
    );

    if (direct.isNotEmpty) return direct;

    final first = _firstNonEmpty(
      [
        (u) => u.firstName,
        (u) => u.firstname,
        (u) => u.first_name,
        (u) => u.fName,
        (u) => u.fname,
      ],
      fallback: '',
    );

    final last = _firstNonEmpty(
      [
        (u) => u.lastName,
        (u) => u.lastname,
        (u) => u.last_name,
        (u) => u.lName,
        (u) => u.lname,
      ],
      fallback: '',
    );

    final name = '$first $last'.trim();
    return name.isNotEmpty ? name : fallback;
  }

  static String handle({String fallback = '@cassius'}) {
    final value = _firstNonEmpty(
      [
        (u) => u.handle,
        (u) => u.username,
        (u) => u.userName,
        (u) => u.linkupId,
        (u) => u.linkUpId,
        (u) => u.linkup_id,
        (u) => u.idName,
        (u) => u.tag,
      ],
      fallback: '',
    );

    if (value.isEmpty) return fallback;
    return value.startsWith('@') ? value : '@$value';
  }

  static String email({String fallback = ''}) {
    return _firstNonEmpty(
      [
        (u) => u.email,
        (u) => u.userEmail,
      ],
      fallback: fallback,
    );
  }

  static String phone({String fallback = ''}) {
    return _firstNonEmpty(
      [
        (u) => u.phone,
        (u) => u.phoneNumber,
        (u) => u.mobile,
        (u) => u.mobileNumber,
      ],
      fallback: fallback,
    );
  }

  static String location({String fallback = 'The Valley, Anguilla 🇦🇮'}) {
    return _firstNonEmpty(
      [
        (u) => u.location,
        (u) => u.city,
        (u) => u.address,
        (u) => u.country,
      ],
      fallback: fallback,
    );
  }

  static String avatarUrl({String fallback = ''}) {
    return _firstNonEmpty(
      [
        (u) => u.avatar,
        (u) => u.avatarUrl,
        (u) => u.avatarURL,
        (u) => u.image,
        (u) => u.imageUrl,
        (u) => u.imageURL,
        (u) => u.photo,
        (u) => u.photoUrl,
        (u) => u.photoURL,
        (u) => u.profileImage,
        (u) => u.profileImageUrl,
        (u) => u.profileImageURL,
        (u) => u.profilePicture,
        (u) => u.profilePictureUrl,
        (u) => u.profilePictureURL,
        (u) => u.picture,
        (u) => u.pictureUrl,
        (u) => u.pictureURL,
      ],
      fallback: fallback,
    );
  }

  static String fullName({String fallback = 'Guest User'}) {
  return displayName(fallback: fallback);
}

static ImageProvider avatarProvider({
  String fallback =
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300&h=300&fit=crop&crop=face',
}) {
  final value = avatarUrl(fallback: fallback).trim();

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return NetworkImage(value);
  }

  if (value.startsWith('assets/')) {
    return AssetImage(value);
  }

  if (value.isNotEmpty) {
    return FileImage(File(value));
  }

  return NetworkImage(fallback);
}

  static String initials({String fallback = 'GU'}) {
    final name = displayName(fallback: '');
    if (name.trim().isEmpty) return fallback;

    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class LinkUpCurrentUserAvatar extends StatelessWidget {
  final double radius;
  final double? innerRadius;
  final double borderWidth;
  final Color borderColor;
  final Color backgroundColor;
  final Color initialsColor;
  final VoidCallback? onTap;

  const LinkUpCurrentUserAvatar({
    super.key,
    this.radius = 22,
    this.innerRadius,
    this.borderWidth = 2,
    this.borderColor = Colors.white,
    this.backgroundColor = const Color(0xff1f2a44),
    this.initialsColor = Colors.white,
    this.onTap,
  });

  ImageProvider? _imageProvider(String path) {
    final value = path.trim();
    if (value.isEmpty) return null;

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return NetworkImage(value);
    }

    if (value.startsWith('assets/')) {
      return AssetImage(value);
    }

    try {
      return FileImage(File(value));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarPath = LinkUpCurrentUser.avatarUrl();
    final image = _imageProvider(avatarPath);
    final safeInnerRadius = innerRadius ?? (radius - borderWidth).clamp(1.0, radius);

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: borderColor,
      child: CircleAvatar(
        radius: safeInnerRadius,
        backgroundColor: backgroundColor,
        backgroundImage: image,
        child: image == null
            ? Text(
                LinkUpCurrentUser.initials(),
                style: TextStyle(
                  color: initialsColor,
                  fontSize: safeInnerRadius * 0.58,
                  fontWeight: FontWeight.w900,
                ),
              )
            : null,
      ),
    );

    if (onTap == null) return avatar;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: avatar,
    );
  }
}

class LinkUpCurrentUserName extends StatelessWidget {
  final TextStyle? style;
  final String fallback;
  final int? maxLines;
  final TextOverflow overflow;

  const LinkUpCurrentUserName({
    super.key,
    this.style,
    this.fallback = 'Guest User',
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      LinkUpCurrentUser.displayName(fallback: fallback),
      maxLines: maxLines,
      overflow: overflow,
      style: style,
    );
  }
}

class LinkUpCurrentUserHandle extends StatelessWidget {
  final TextStyle? style;
  final String fallback;
  final int? maxLines;
  final TextOverflow overflow;

  const LinkUpCurrentUserHandle({
    super.key,
    this.style,
    this.fallback = '@cassius',
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      LinkUpCurrentUser.handle(fallback: fallback),
      maxLines: maxLines,
      overflow: overflow,
      style: style,
    );
  }
}
