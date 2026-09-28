import 'dart:async';

import 'package:flutter/material.dart';
import '../core/design_tokens.dart';

const double _labelFontSize = 11;
const double _labelLineHeight = 1.25;
const int _labelMaxLines = 2;
const double _labelBlockHeight =
    _labelMaxLines * _labelFontSize * _labelLineHeight;

class CategoryCarouselItem {
  final String label;
  final String? emoji;
  final IconData? icon;

  /// When set the circle shows this photo instead of the glyph, so a category
  /// can be illustrated with a real product shot from the catalogue.
  final String? imageUrl;
  final VoidCallback? onTap;

  const CategoryCarouselItem({
    required this.label,
    this.emoji,
    this.icon,
    this.imageUrl,
    this.onTap,
  }) : assert(
         emoji != null || icon != null || imageUrl != null,
         'Provide emoji, icon or imageUrl',
       );
}

class CategoryCarousel extends StatefulWidget {
  final List<CategoryCarouselItem> items;
  final Color primaryColor;
  final Color? accentColor;
  final double itemExtent;
  final double itemSpacing;
  final int? perPage;
  final bool autoSlide;
  final Duration interval;
  final bool showIndicator;
  final EdgeInsets padding;

  const CategoryCarousel({
    super.key,
    required this.items,
    required this.primaryColor,
    this.accentColor,
    this.itemExtent = 68,
    this.itemSpacing = AppSpacing.md,
    this.perPage,
    this.autoSlide = true,
    this.interval = AppDurations.carousel,
    this.showIndicator = true,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
  });

  @override
  State<CategoryCarousel> createState() => _CategoryCarouselState();
}

class _CategoryCarouselState extends State<CategoryCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _page = 0;
  int _pageCount = 1;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 1.0);
    if (widget.autoSlide) _startTimer();
  }

  @override
  void didUpdateWidget(CategoryCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoSlide != oldWidget.autoSlide) {
      if (widget.autoSlide) {
        _startTimer();
      } else {
        _stopTimer();
      }
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(widget.interval, (_) => _advance());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _advance() {
    if (!mounted || _dragging || _pageCount <= 1) return;
    final next = (_page + 1) % _pageCount;
    _controller.animateToPage(
      next,
      duration: AppDurations.slow,
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int index) {
    if (!mounted) return;
    setState(() => _page = index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final usable = width - widget.padding.horizontal;
        final resolved =
            widget.perPage ??
            ((usable + widget.itemSpacing) /
                    (widget.itemExtent + widget.itemSpacing))
                .floor()
                .clamp(3, 5);
        final perPage = resolved < 1 ? 1 : resolved;
        _pageCount = (widget.items.length / perPage).ceil();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: widget.itemExtent + _labelBlockHeight + AppSpacing.sm,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification &&
                      notification.dragDetails != null) {
                    _dragging = true;
                    _stopTimer();
                  } else if (notification is ScrollEndNotification) {
                    _dragging = false;
                    if (widget.autoSlide) _startTimer();
                  }
                  return false;
                },
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pageCount,
                  onPageChanged: _onPageChanged,
                  physics: const PageScrollPhysics(),
                  padEnds: false,
                  itemBuilder: (context, page) {
                    final start = page * perPage;
                    final end = (start + perPage).clamp(0, widget.items.length);
                    final slice = widget.items.sublist(start, end);
                    return Padding(
                      padding: widget.padding,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < perPage; i++) ...[
                            if (i < slice.length)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: i == perPage - 1
                                        ? 0
                                        : widget.itemSpacing,
                                  ),
                                  child: _CategoryCircle(
                                    item: slice[i],
                                    diameter: widget.itemExtent,
                                    primaryColor: widget.primaryColor,
                                    accentColor: widget.accentColor,
                                  ),
                                ),
                              )
                            else
                              const Expanded(child: SizedBox.shrink()),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            if (widget.showIndicator && _pageCount > 1) ...[
              const SizedBox(height: AppSpacing.xs),
              _Indicator(
                count: _pageCount,
                active: _page,
                color: widget.primaryColor,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CategoryCircle extends StatelessWidget {
  final CategoryCarouselItem item;
  final double diameter;
  final Color primaryColor;
  final Color? accentColor;

  const _CategoryCircle({
    required this.item,
    required this.diameter,
    required this.primaryColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final tint = accentColor ?? primaryColor.withValues(alpha: 0.10);
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint,
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: item.imageUrl != null
                ? ClipOval(
                    child: item.imageUrl!.startsWith('assets/')
                        ? Image.asset(
                            item.imageUrl!,
                            width: diameter,
                            height: diameter,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _imageFallback(tint),
                          )
                        : Image.network(
                            item.imageUrl!,
                            width: diameter,
                            height: diameter,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _imageFallback(tint),
                          ),
                  )
                : item.icon != null
                ? Icon(item.icon, size: diameter * 0.42, color: primaryColor)
                : Text(
                    item.emoji ?? '',
                    style: TextStyle(fontSize: diameter * 0.40),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: _labelMaxLines,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              fontSize: _labelFontSize,
              fontWeight: FontWeight.w500,
              color: AppPalette.textPrimary,
              height: _labelLineHeight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback(Color tint) => Container(
    color: tint,
    alignment: Alignment.center,
    child: item.icon != null
        ? Icon(item.icon, size: diameter * 0.42, color: primaryColor)
        : Text(
            item.emoji ?? '',
            style: TextStyle(fontSize: diameter * 0.40),
            textAlign: TextAlign.center,
          ),
  );
}

class _Indicator extends StatelessWidget {
  final int count;
  final int active;
  final Color color;

  const _Indicator({
    required this.count,
    required this.active,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: AppDurations.normal,
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: isActive ? 18 : 6,
          decoration: BoxDecoration(
            color: isActive ? color : color.withValues(alpha: 0.22),
            borderRadius: AppRadius.allPill,
          ),
        );
      }),
    );
  }
}

class CategoryGrid extends StatelessWidget {
  final List<CategoryCarouselItem> items;
  final Color primaryColor;
  final Color? accentColor;
  final int crossAxisCount;
  final double itemExtent;
  final double spacing;
  final EdgeInsets padding;

  const CategoryGrid({
    super.key,
    required this.items,
    required this.primaryColor,
    this.accentColor,
    this.crossAxisCount = 4,
    this.itemExtent = 68,
    this.spacing = AppSpacing.lg,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.lg,
        childAspectRatio: 0.70,
      ),
      itemBuilder: (context, index) => _CategoryCircle(
        item: items[index],
        diameter: itemExtent,
        primaryColor: primaryColor,
        accentColor: accentColor,
      ),
    );
  }
}
