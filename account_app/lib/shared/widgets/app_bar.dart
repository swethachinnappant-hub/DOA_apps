import 'package:flutter/material.dart';
import '../../core/responsive.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool centerTitle;
  final double? elevation;
  final Widget? bottom;
  final double? bottomHeight;

  const AppBarWidget({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBack = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle = true,
    this.elevation = 0,
    this.bottom,
    this.bottomHeight,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom != null ? (bottomHeight ?? 56) : 0),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: Responsive.fontSize(context, mobile: 18, tablet: 20, desktop: 22),
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: leading ?? (showBack ? _buildBackButton(context) : null),
      actions: actions,
      backgroundColor: backgroundColor ?? theme.primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
      centerTitle: centerTitle,
      elevation: elevation,
      bottom: bottom != null
          ? PreferredSize(
              preferredSize: Size.fromHeight(bottomHeight ?? 56),
              child: bottom!,
            )
          : null,
    );
  }

  Widget? _buildBackButton(BuildContext context) {
    if (!showBack) return null;

    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
      onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
    );
  }
}

class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String hintText;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onFilterPressed;
  final List<Widget>? actions;

  const SearchAppBar({
    super.key,
    required this.title,
    this.hintText = 'Search...',
    this.onSearchChanged,
    this.onFilterPressed,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 60);

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();
}

class _SearchAppBarState extends State<SearchAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: widget.actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: Responsive.horizontalPadding(context, mobile: 16),
          child: TextField(
            onChanged: widget.onSearchChanged,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: widget.onFilterPressed != null
                  ? IconButton(
                      icon: const Icon(Icons.filter_list, size: 20),
                      onPressed: widget.onFilterPressed,
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SliverAppBarWidget extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? flexibleSpace;
  final double expandedHeight;
  final bool pinned;
  final bool floating;

  const SliverAppBarWidget({
    super.key,
    required this.title,
    this.actions,
    this.flexibleSpace,
    this.expandedHeight = 200,
    this.pinned = true,
    this.floating = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: actions,
      flexibleSpace: flexibleSpace,
      expandedHeight: expandedHeight,
      pinned: pinned,
      floating: floating,
    );
  }
}

