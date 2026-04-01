import 'package:flutter/material.dart';
import 'package:mikomi/shared/theme_extensions.dart';

class ProfileBackground extends StatelessWidget {
  final double height;

  const ProfileBackground({super.key, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return Container(height: height, color: context.colors.surfaceVariant);
  }
}
