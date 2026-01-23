import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// Custom app bar with consistent styling
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final PreferredSizeWidget? bottom;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.bottom,
    this.systemOverlayStyle,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveBackgroundColor = backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final effectiveForegroundColor = foregroundColor ??
        (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface);

    return AppBar(
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: effectiveForegroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null),
      centerTitle: centerTitle,
      backgroundColor: effectiveBackgroundColor,
      foregroundColor: effectiveForegroundColor,
      elevation: elevation,
      surfaceTintColor: Colors.transparent,
      leading: leading ??
          (showBackButton && Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  onPressed: onBackPressed ?? () => Navigator.pop(context),
                )
              : null),
      actions: actions,
      bottom: bottom,
      systemOverlayStyle: systemOverlayStyle ??
          (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark),
    );
  }
}

/// Custom sliver app bar for scrollable pages
class CustomSliverAppBar extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? flexibleSpace;
  final double expandedHeight;
  final bool floating;
  final bool pinned;
  final bool snap;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CustomSliverAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.flexibleSpace,
    this.expandedHeight = 200,
    this.floating = false,
    this.pinned = true,
    this.snap = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveBackgroundColor = backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final effectiveForegroundColor = foregroundColor ??
        (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface);

    return SliverAppBar(
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: effectiveForegroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null),
      expandedHeight: expandedHeight,
      floating: floating,
      pinned: pinned,
      snap: snap,
      backgroundColor: effectiveBackgroundColor,
      foregroundColor: effectiveForegroundColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      actions: actions,
      flexibleSpace: flexibleSpace,
    );
  }
}

/// Custom tab bar for use in app bars
class CustomTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> tabs;
  final TabController? controller;
  final bool isScrollable;
  final Color? indicatorColor;
  final Color? labelColor;
  final Color? unselectedLabelColor;

  const CustomTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.isScrollable = false,
    this.indicatorColor,
    this.labelColor,
    this.unselectedLabelColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveIndicatorColor = indicatorColor ?? AppColors.primaryBlue;
    final effectiveLabelColor = labelColor ?? AppColors.primaryBlue;
    final effectiveUnselectedColor = unselectedLabelColor ??
        (isDark
            ? AppColors.darkOnSurfaceVariant
            : AppColors.lightOnSurfaceVariant);

    return TabBar(
      controller: controller,
      isScrollable: isScrollable,
      indicatorColor: effectiveIndicatorColor,
      labelColor: effectiveLabelColor,
      unselectedLabelColor: effectiveUnselectedColor,
      labelStyle: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: theme.textTheme.titleSmall,
      tabs: tabs.map((tab) => Tab(text: tab)).toList(),
    );
  }
}
