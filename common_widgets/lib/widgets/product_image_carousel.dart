import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
    this.fit = BoxFit.contain,
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
  final VoidCallback? onZoomRequested;

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
    this.onZoomRequested,
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
  bool _userInteracted = false;

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
    if (widget.autoSlide && _isMulti && !_userInteracted) {
      _timer = Timer.periodic(widget.interval, (_) => _advance());
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _pauseForInteraction() {
    _userInteracted = true;
    _stop();
  }

  void _advance() {
    if (!mounted || !_controller.hasClients) return;
    // A tick that lands mid-transition would restart the animation before it
    // can commit, leaving the carousel stuck on the same image.
    if (_controller.position.isScrollingNotifier.value) return;
    if (!_isMostlyVisible()) {
      // Start a fresh dwell period after an off-screen interval so a gallery
      // never advances immediately as a shopper scrolls it into view.
      _start();
      return;
    }

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

  bool _isMostlyVisible() {
    final object = context.findRenderObject();
    if (object is! RenderBox || !object.hasSize) return false;
    var visible = object.localToGlobal(Offset.zero) & object.size;
    visible = visible.intersect(Offset.zero & MediaQuery.sizeOf(context));
    if (visible.isEmpty) return false;
    context.visitAncestorElements((element) {
      final ancestor = element.findRenderObject();
      if (ancestor is RenderAbstractViewport &&
          ancestor is RenderBox &&
          (ancestor as RenderBox).hasSize) {
        final viewport = ancestor as RenderBox;
        visible = visible.intersect(
          viewport.localToGlobal(Offset.zero) & viewport.size,
        );
      }
      return !visible.isEmpty;
    });
    return !visible.isEmpty &&
        visible.width * visible.height >=
            object.size.width * object.size.height * .5;
  }

  /// Jumps to a specific image, e.g. from a thumbnail rail.
  void goTo(int index) {
    if (index < 0 || index >= _count) return;
    _pauseForInteraction();
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

    final showNavigationArrows = MediaQuery.sizeOf(context).width >= 600;
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
                _pauseForInteraction();
              } else if (notification is ScrollEndNotification) {
                if (_dragging) _dragging = false;
                if (!_userInteracted) _start();
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
                return MouseRegion(
                  cursor: SystemMouseCursors.zoomIn,
                  child: GestureDetector(
                    onTap: () {
                      _pauseForInteraction();
                      widget.onImageTap!();
                    },
                    child: image,
                  ),
                );
              },
            ),
          ),
          if (showNavigationArrows && _isMulti && _index > 0)
            Positioned(
              left: AppSpacing.sm,
              top: 0,
              bottom: 0,
              child: Center(
                child: _GalleryArrow(
                  icon: Icons.chevron_left,
                  tooltip: 'Previous product image',
                  onPressed: () => goTo(_index - 1),
                ),
              ),
            ),
          if (showNavigationArrows && _isMulti && _index < _count - 1)
            Positioned(
              right: AppSpacing.sm,
              top: 0,
              bottom: 0,
              child: Center(
                child: _GalleryArrow(
                  icon: Icons.chevron_right,
                  tooltip: 'Next product image',
                  onPressed: () => goTo(_index + 1),
                ),
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
          if (widget.onZoomRequested != null)
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: Material(
                color: Colors.white.withValues(alpha: .94),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () {
                    _pauseForInteraction();
                    widget.onZoomRequested!();
                  },
                  tooltip: 'Zoom product image',
                  icon: const Icon(Icons.zoom_in, size: 20),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 38,
                    height: 38,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GalleryArrow extends StatelessWidget {
  const _GalleryArrow({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .94),
    shape: const CircleBorder(),
    elevation: 2,
    child: IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 27),
      constraints: const BoxConstraints.tightFor(width: 42, height: 42),
      padding: EdgeInsets.zero,
    ),
  );
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
  List<String>? images,
  int initialIndex = 0,
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
          images: images?.isNotEmpty == true ? images! : [url],
          initialIndex: initialIndex,
          placeholderIcon: placeholderIcon,
          placeholderAccent: placeholderAccent,
        ),
      ),
    ),
  );
}

class _ImageViewer extends StatefulWidget {
  final String url;
  final List<String> images;
  final int initialIndex;
  final IconData placeholderIcon;
  final Color placeholderAccent;

  const _ImageViewer({
    required this.url,
    required this.images,
    required this.initialIndex,
    required this.placeholderIcon,
    required this.placeholderAccent,
  });

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late final PageController _pageController = PageController(
    initialPage: widget.initialIndex,
  );
  final Map<int, TransformationController> _transformations = {};
  Offset _lastDoubleTap = Offset.zero;
  late int _index = widget.initialIndex;

  TransformationController _transformationFor(int index) =>
      _transformations.putIfAbsent(index, TransformationController.new);

  TransformationController get _activeTransformation =>
      _transformationFor(_index);

  @override
  void dispose() {
    for (final controller in _transformations.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    final transformationController = _activeTransformation;
    final currentScale = transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 1.05) {
      transformationController.value = Matrix4.identity();
      return;
    }

    const scale = 2.4;
    transformationController.value = Matrix4.identity()
      ..translate(
        _lastDoubleTap.dx * (1 - scale),
        _lastDoubleTap.dy * (1 - scale),
      )
      ..scale(scale);
  }

  void _zoomFromWheel(PointerSignalEvent event, Offset localPosition) {
    if (event is! PointerScrollEvent) return;
    final transformationController = _activeTransformation;
    final currentScale = transformationController.value.getMaxScaleOnAxis();
    final nextScale = (currentScale * (event.scrollDelta.dy < 0 ? 1.18 : 0.85))
        .clamp(1.0, 4.0);
    if (nextScale == currentScale) return;
    transformationController.value = Matrix4.identity()
      ..translate(
        localPosition.dx * (1 - nextScale),
        localPosition.dy * (1 - nextScale),
      )
      ..scale(nextScale);
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.images.length) return;
    _pageController.animateToPage(
      index,
      duration: AppDurations.normal,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 600;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) => Listener(
                onPointerSignal: (event) {
                  final renderObject = context.findRenderObject();
                  final localPosition =
                      event is PointerScrollEvent && renderObject is RenderBox
                      ? renderObject.globalToLocal(event.position)
                      : Offset(
                          constraints.maxWidth / 2,
                          constraints.maxHeight / 2,
                        );
                  _zoomFromWheel(event, localPosition);
                },
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.images.length,
                  onPageChanged: (index) {
                    _transformationFor(index).value = Matrix4.identity();
                    setState(() => _index = index);
                  },
                  itemBuilder: (context, index) => GestureDetector(
                    onDoubleTapDown: (details) =>
                        _lastDoubleTap = details.localPosition,
                    onDoubleTap: _toggleZoom,
                    child: InteractiveViewer(
                      transformationController: _transformationFor(index),
                      minScale: 1,
                      maxScale: 4,
                      panEnabled: true,
                      scaleEnabled: true,
                      child: ProductImageTile(
                        url: widget.images[index],
                        placeholderIcon: widget.placeholderIcon,
                        placeholderColor: const Color(0xFF1F2937),
                        placeholderAccent: Colors.white70,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isDesktop && _index > 0)
            Positioned(
              left: AppSpacing.md,
              top: 0,
              bottom: 0,
              child: Center(
                child: _GalleryArrow(
                  icon: Icons.chevron_left,
                  tooltip: 'Previous product image',
                  onPressed: () => _goTo(_index - 1),
                ),
              ),
            ),
          if (isDesktop && _index < widget.images.length - 1)
            Positioned(
              right: AppSpacing.md,
              top: 0,
              bottom: 0,
              child: Center(
                child: _GalleryArrow(
                  icon: Icons.chevron_right,
                  tooltip: 'Next product image',
                  onPressed: () => _goTo(_index + 1),
                ),
              ),
            ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .55),
                  borderRadius: AppRadius.allPill,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    isDesktop
                        ? 'Double-click or scroll to zoom'
                        : 'Double-tap or pinch to zoom',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + AppSpacing.sm,
              left: AppSpacing.md,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .55),
                  borderRadius: AppRadius.allPill,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Text(
                    '${_index + 1} / ${widget.images.length}',
                    style: const TextStyle(color: Colors.white),
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
