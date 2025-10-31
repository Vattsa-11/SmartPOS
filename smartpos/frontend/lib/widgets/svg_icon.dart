import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgIcon extends StatelessWidget {
  final String iconName;
  final double? width;
  final double? height;
  final Color? color;

  const SvgIcon({
    Key? key,
    required this.iconName,
    this.width = 24,
    this.height = 24,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If you have individual SVG files
    return SvgPicture.asset(
      'assets/images/${iconName}_icon.svg',
      width: width,
      height: height,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}

// Usage:
// SvgIcon(iconName: 'product', width: 32, color: Colors.blue)
