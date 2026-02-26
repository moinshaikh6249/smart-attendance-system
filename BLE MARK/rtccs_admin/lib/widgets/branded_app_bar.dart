import 'package:flutter/material.dart';

class BrandedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const BrandedAppBar({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Image.asset('assets/images/logo.png', height: 36),
          const SizedBox(width: 12),
          Text(title, style: Theme.of(context).appBarTheme.titleTextStyle),
        ],
      ),
      centerTitle: false,
      elevation: 4,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
} 