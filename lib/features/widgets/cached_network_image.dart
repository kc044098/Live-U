import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

Widget buildAvatarCircle({
  required String url,
  double radius = 24,
}) {
  final targetW = (radius * 2 * 2).round();
  ImageProvider? fg;
  if (url.isNotEmpty) {
    fg = ResizeImage(
      CachedNetworkImageProvider(url),
      width: targetW,
      height: targetW,
    );
  }

  return CircleAvatar(
    radius: radius,
    backgroundImage: const AssetImage('assets/my_icon_defult.jpeg'),
    foregroundImage: fg,
  );
}
