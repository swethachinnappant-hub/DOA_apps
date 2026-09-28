import 'dart:async';

import 'package:flutter/material.dart';

import '../core/design_tokens.dart';

/// A dot indicator that reads well on top of photography.
class CarouselDots extends StatelessWidget {
  final int count;
  final int activeIndex;
  final Color activeColor;
  final Color inactiveColor;

  const CarouselDots({
    super.key,
    required this.count,
    required this.activeIndex,
    this.activeColor = Colors.white,
    this.inactiveColor = const Color(0x99FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: AppDurations.normal,
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: active ? 18 : 6,
          decoration: BoxDecoration(
            color: active ? activeColor : inactiveColor,
            borderRadius: AppRadius.allPill,
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Image with a branded placeholder shown while loading and when the network
/// image is unavailable, so cards never render as empty grey boxes.
class ProductImageTile extends StatelessWidget {
  final String url;
  final IconData placeholderIcon;
  final Color placeholderColor;
  final Color placeholderAccent;
  final BoxFit fit;

  const ProductImageTile({
    super.key,
    required this.url,
    this.placeholderIcon = Icons.image_outlined,
    this.placeholderColor = AppPalette.surfaceMuted,
    this.placeholderAccent = AppPalette.textHint,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = _Placeholder(
      icon: placeholderIcon,
      color: placeholderColor,
      accent: placeholderAccent,
    );

    if (url.isEmpty) return placeholder;

    final isRemote = url.startsWith('https://') || url.startsWith('http://');
    if (isRemote) {
      return Image.network(
        url,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholder,
      );
    }
    return Image.asset(
      url,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

class _Placeholder extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color accent;

  const _Placeholder({
    required this.icon,
    required this.color,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.white, 0.55)!],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 34, color: accent.withValues(alpha: 0.5)),
      ),
    );
  }
}

/// Horizontally auto-advancing, manually swipeable product image carousel.
///
/// Mirrors the behaviour shoppers expect from Myntra/Ajio product cards and
/// detail pages: several angles of the same product, a dot indicator, swipe to
/// browse, and a tap to zoom.
class ProductImageCarousel extends StatefulWidget {
  final List<String> images;
  final IconData placeholderIcon;
  final Color placeholderColor;
  final Color placeholderAccent;

  /// Auto-advance only applies when there is more than one image.
  final bool autoSlide;
  final Duration interval;
  final bool showDots;
  final bool showCounter;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final VoidCallback? onImageTap;

  /// Reports the visible image, so an external thumbnail rail can follow a
  /// direct swipe.
  final ValueChanged<int>? onPageChanged;

  const ProductImageCarousel({
    super.key,
    required this.images,
    this.placeholderIcon = Icons.image_outlined,
    this.placeholderColor = AppPalette.surfaceMuted,
    this.placeholderAccent = AppPalette.textHint,
    this.autoSlide = true,
    this.interval = AppDurations.carousel,
    this.showDots = true,
    this.showCounter = false,
    this.fit = BoxFit.contain,
    this.borderRadius = BorderRadius.zero,
    this.onImageTap,
    this.onPageChanged,
  });

  @override
  State<ProductImageCarousel> createState() => ProductImageCarouselState();
}

class ProductImageCarouselState extends State<ProductImageCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;
  bool _dragging = false;

  int get _count => widget.images.length;
  bool get _isMulti => _count > 1;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    if (widget.autoSlide && _isMulti) _start();
  }

  @override
  void didUpdateWidget(covariant ProductImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.images.length != oldWidget.images.length) {
      _controller.jumpToPage(0);
      _index = 0;
    }
    if (widget.autoSlide != oldWidget.autoSlide || _count <= 1) {
      _start();
    }
  }

  @override
  void dispose() {
    _stop();
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    _stop();
    if (widget.autoSlide && _isMulti) {
      _timer = Timer.periodic(widget.interval, (_) => _advance());
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _advance() {
    if (!mounted || !_controller.hasClients) return;
    // A tick that lands mid-transition would restart the animation before it
    // can commit, leaving the carousel stuck on the same image.
    if (_controller.position.isScrollingNotifier.value) return;

    final next = _index + 1;
    if (next >= _count) {
      _controller.jumpToPage(0);
    } else {
      _controller.nextPage(
        duration: AppDurations.slow,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  /// Jumps to a specific image, e.g. from a thumbnail rail.
  void goTo(int index) {
    if (index < 0 || index >= _count) return;
    _controller.animateToPage(
      index,
      duration: AppDurations.normal,
      curve: Curves.easeOut,
    );
  }

  int get currentIndex => _index;

  @override
  Widget build(BuildContext context) {
    if (_count == 0) {
      return ProductImageTile(
        url: '',
        placeholderIcon: widget.placeholderIcon,
        placeholderColor: widget.placeholderColor,
        placeholderAccent: widget.placeholderAccent,
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFFF8F5EF)),
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                // Pause auto-advance while the shopper is browsing manually.
                _dragging = true;
                _stop();
              } else if (notification is ScrollEndNotification) {
                if (_dragging) _dragging = false;
                _start();
              }
              return false;
            },

            child: PageView.builder(
              controller: _controller,
              itemCount: _count,
              onPageChanged: (i) {
                if (mounted) setState(() => _index = i);
                widget.onPageChanged?.call(i);
              },
              itemBuilder: (context, i) {
                final image = ProductImageTile(
                  url: widget.images[i],
                  placeholderIcon: widget.placeholderIcon,
                  placeholderColor: widget.placeholderColor,
                  placeholderAccent: widget.placeholderAccent,
                  fit: widget.fit,
                );
                if (widget.onImageTap == null) return image;
                return GestureDetector(
                  onTap: () => widget.onImageTap!(),
                  child: image,
                );
              },
            ),
          ),
          if (widget.showDots && _isMulti)
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.sm,
              child: Center(
                child: CarouselDots(count: _count, activeIndex: _index),
              ),
            ),
          if (widget.showCounter && _isMulti)
            Positioned(
              right: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .52),
                  borderRadius: AppRadius.allPill,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    '${_index + 1} / $_count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Vertical thumbnail rail for a product detail page. Tapping a thumbnail
/// moves the main carousel to that image.
class ProductThumbnailRail extends StatelessWidget {
  final List<String> images;
  final int activeIndex;
  final IconData placeholderIcon;
  final Color placeholderAccent;
  final ValueChanged<int> onSelected;
  final double itemExtent;

  const ProductThumbnailRail({
    super.key,
    required this.images,
    required this.activeIndex,
    required this.onSelected,
    this.placeholderIcon = Icons.image_outlined,
    this.placeholderAccent = AppPalette.textHint,
    this.itemExtent = 64,
  });

  @override
  Widget build(BuildContext context) {
    if (images.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: itemExtent,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final selected = i == activeIndex;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              height: itemExtent,
              width: itemExtent,
              decoration: BoxDecoration(
                borderRadius: AppRadius.allSm,
                border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : AppPalette.border,
                  width: selected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: AppRadius.allXs,
                child: ProductImageTile(
                  url: images[i],
                  placeholderIcon: placeholderIcon,
                  placeholderAccent: placeholderAccent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Full-screen pinch/pan viewer, the way Myntra and Amazon zoom product shots.
void showImageViewer(
  BuildContext context, {
  required String url,
  IconData placeholderIcon = Icons.image_outlined,
  Color placeholderAccent = AppPalette.textHint,
}) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (_, animation, _) => FadeTransition(
        opacity: animation,
        child: _ImageViewer(
          url: url,
          placeholderIcon: placeholderIcon,
          placeholderAccent: placeholderAccent,
        ),
      ),
    ),
  );
}

class _ImageViewer extends StatelessWidget {
  final String url;
  final IconData placeholderIcon;
  final Color placeholderAccent;

  const _ImageViewer({
    required this.url,
    required this.placeholderIcon,
    required this.placeholderAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: ProductImageTile(
                  url: url,
                  placeholderIcon: placeholderIcon,
                  placeholderColor: const Color(0xFF1F2937),
                  placeholderAccent: Colors.white70,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            right: AppSpacing.md,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
