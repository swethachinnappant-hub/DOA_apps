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
  /// Square-ish photo tile used by the storefront category rail. Kept large
  /// enough to make the jewellery recognizable on phones while the carousel
  /// still fits five categories across a typical handset.
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
    this.itemExtent = 112,
    this.itemSpacing = 8,
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
  /// Repetitions of the page cycle. The viewport starts mid-cycle so the
  /// rail scrolls forward and backward forever without ever showing a
  /// blank end page (page 0's content = cycle content).
  static const int _cycles = 1000;

  PageController? _controller;
  Timer? _timer;
  int _page = 0;
  int _pageCount = 1;
  int _total = 1;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
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
    _controller?.dispose();
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
    final next = _page + 1;
    if (next >= _total) return;
    _controller!.animateToPage(
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
        // Never show a tile twice on one page (would duplicate a label)
        // and never leave empty slots (would show white space): the row
        // shows at most one full set of items, all pages wrap around.
        final perPage = resolved < 1
            ? 1
            : (resolved > widget.items.length ? widget.items.length : resolved);
        // Keep the photo frame square at every breakpoint. Previously the
        // fixed image height was much taller than a five-column tile was wide.
        final tileWidth =
            (usable - (perPage - 1) * widget.itemSpacing) / perPage;
        final imageExtent = tileWidth.clamp(0.0, widget.itemExtent);
        _pageCount = (widget.items.length / perPage).ceil();
        _total = _pageCount * _cycles;
        _controller ??= PageController(
          viewportFraction: 1.0,
          initialPage: _total ~/ 2,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: imageExtent + _labelBlockHeight + AppSpacing.sm,
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
                  itemCount: _total,
                  onPageChanged: _onPageChanged,
                  physics: const PageScrollPhysics(),
                  padEnds: false,
                  itemBuilder: (context, page) {
                    final start = page * perPage;
                    final slice = [
                      for (var i = 0; i < perPage; i++)
                        widget.items[(start + i) % widget.items.length],
                    ];
                    return Padding(
                      padding: widget.padding,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < perPage; i++)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: i == perPage - 1
                                      ? 0
                                      : widget.itemSpacing,
                                ),
                                child: _CategoryTile(
                                  item: slice[i],
                                  height: imageExtent,
                                ),
                              ),
                            ),
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
                active: _page % _pageCount,
                color: widget.primaryColor,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryCarouselItem item;
  final double height;

  const _CategoryTile({required this.item, required this.height});

  @override
  Widget build(BuildContext context) {
    const tileSurface = AppPalette.surface;
    final cacheWidth = (height * MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(1, 2048)
        .toInt();
    return Semantics(
      button: true,
      label: 'Shop ${item.label}',
      child: InkWell(
        onTap: item.onTap,
        borderRadius: AppRadius.allMd,
        child: SizedBox(
          width: double.infinity,
          child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
            width: height,
            height: height,
            decoration: BoxDecoration(
              borderRadius: AppRadius.allMd,
              color: tileSurface,
              border: Border.all(color: AppPalette.border),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: item.imageUrl != null
                ? (item.imageUrl!.startsWith('assets/')
                      ? Image.asset(
                          item.imageUrl!,
                          width: double.infinity,
                          height: height,
                          cacheWidth: cacheWidth,
                          // cover so every tile is filled edge-to-edge at the
                          // same size — contain letterboxed each photo to a
                          // different visual scale on a white pad.
                          fit: BoxFit.cover,
                          frameBuilder: (context, child, frame, syncLoaded) =>
                              frame != null || syncLoaded
                                  ? child
                                  : _imageFallback(),
                          errorBuilder: (_, _, _) => _imageFallback(),
                        )
                      : Image.network(
                          item.imageUrl!,
                          width: double.infinity,
                          height: height,
                          cacheWidth: cacheWidth,
                          fit: BoxFit.cover,
                          frameBuilder: (context, child, frame, syncLoaded) =>
                              frame != null || syncLoaded
                                  ? child
                                  : _imageFallback(),
                          errorBuilder: (_, _, _) => _imageFallback(),
                        ))
                : item.icon != null
                ? Icon(
                    item.icon,
                    size: height * 0.42,
                    color: AppPalette.textSecondary,
                  )
                : Text(
                    item.emoji ?? '',
                    style: TextStyle(fontSize: height * 0.40),
                    textAlign: TextAlign.center,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // §11.5: keep the label inside the fixed cell even when
          // Dynamic Type doubles the font — it shrinks and ellipsizes.
          Flexible(
            child: Text(
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
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback() => Container(
    color: AppPalette.surfaceMuted,
    alignment: Alignment.center,
    child: item.icon != null
        ? Icon(item.icon, size: height * 0.42, color: AppPalette.textSecondary)
        : Text(
            item.emoji ?? '',
            style: TextStyle(fontSize: height * 0.40),
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
      itemBuilder: (context, index) =>
          _CategoryTile(item: items[index], height: itemExtent),
    );
  }
}
