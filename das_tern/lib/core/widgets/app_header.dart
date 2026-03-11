import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.onBackPressed,
    this.actions,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBackButton)
          IconButton(
            onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        if (actions != null) ...actions!,
      ],
    );
  }
}
