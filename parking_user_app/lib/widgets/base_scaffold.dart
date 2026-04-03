import 'package:flutter/material.dart';
import 'package:parking_user_app/core/app_theme.dart';
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
    this.showDrawer = false,
    this.backgroundColor,
    this.appBarBackgroundColor,
    this.appBarForegroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppTheme.surfaceLight,
      appBar: AppBar(
        leading: (showDrawer && !Navigator.canPop(context))
            ? null 
            : (Navigator.canPop(context) ? const BackButton() : null),
        title: titleWidget ?? Text(title ?? ''),
        actions: actions,
        backgroundColor: appBarBackgroundColor ?? Colors.white,
        foregroundColor: appBarForegroundColor ?? AppTheme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      drawer: showDrawer
          ? SidebarNavigation(
              currentIndex: currentIndex,
              onTabChanged:
                  onTabChanged ??
                  (index) {
                  
                  },
            )
          : null,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
