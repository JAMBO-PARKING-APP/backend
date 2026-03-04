import 'package:flutter/material.dart';
import 'package:parking_user_app/features/home/screens/sidebar_navigation.dart';

class BaseScaffold extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final int currentIndex;
  final Function(int)? onTabChanged;
  final bool showDrawer;
  final Color? backgroundColor;
  final Color? appBarBackgroundColor;
  final Color? appBarForegroundColor;

  const BaseScaffold({
    super.key,
    this.title,
    this.titleWidget,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.currentIndex = 0,
    this.onTabChanged,
    this.showDrawer = true,
    this.backgroundColor,
    this.appBarBackgroundColor,
    this.appBarForegroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: (showDrawer && !Navigator.canPop(context))
            ? null // Scaffold will automatically add the drawer icon
            : (Navigator.canPop(context) ? const BackButton() : null),
        title: titleWidget ?? Text(title ?? ''),
        actions: actions,
        backgroundColor: appBarBackgroundColor,
        foregroundColor: appBarForegroundColor,
      ),
      drawer: showDrawer
          ? SidebarNavigation(
              currentIndex: currentIndex,
              onTabChanged:
                  onTabChanged ??
                  (index) {
                    // Default behavior if no callback provided:
                    // Navigation logic might need to be handled by the parent or a provider.
                  },
            )
          : null,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
