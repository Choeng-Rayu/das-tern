import 'package:das_tern/core/widgets/app_bottom_nav.dart';
import 'package:das_tern/core/widgets/app_header.dart';
import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    this.title,
    this.subtitle,
    this.actions,
    this.currentIndex,
    this.showBackButton = false,
    this.floatingActionButton,
    super.key,
  });

  final Widget body;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final int? currentIndex;
  final bool showBackButton;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final bool showHeader = title != null && title!.isNotEmpty;
    return Scaffold(
      appBar: showHeader
          ? AppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: 76,
              title: AppHeader(
                title: title!,
                subtitle: subtitle,
                showBackButton: showBackButton,
                actions: actions,
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.all(16), child: body),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: currentIndex == null
          ? null
          : AppBottomNav(currentIndex: currentIndex!),
    );
  }
}
