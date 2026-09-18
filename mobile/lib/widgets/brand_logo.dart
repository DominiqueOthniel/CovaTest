import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 36});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/cova-icon.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.umbrella,
        size: height,
        color: const Color(0xFFF05A28),
      ),
    );
  }
}
