import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/responsive.dart';

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: size, height: size, borderRadius: size / 2);
  }
}

class SkeletonText extends StatelessWidget {
  final double? width;
  final double height;

  const SkeletonText({super.key, this.width, this.height = 16});

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: width ?? double.infinity, height: height, borderRadius: 4);
  }
}

class SkeletonCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double? height;

  const SkeletonCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.radius = 12,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        height: height,
        margin: margin,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      ),
    );
  }
}

class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Responsive.padding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonCard(
            child: Row(
              children: [
                const SkeletonCircle(size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonText(width: 150, height: 18),
                      const SizedBox(height: 8),
                      SkeletonText(width: 200, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 16)),
          SkeletonGrid(itemCount: 6),
          SizedBox(height: Responsive.spacing(context, mobile: 16)),
          SkeletonCard(height: 250),
        ],
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;

  const SkeletonList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return SkeletonCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              const SkeletonCircle(size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(width: 120, height: 16),
                    const SizedBox(height: 8),
                    SkeletonText(width: 80, height: 12),
                  ],
                ),
              ),
              SkeletonText(width: 60, height: 16),
            ],
          ),
        );
      },
    );
  }
}

class SkeletonGrid extends StatelessWidget {
  final int itemCount;

  const SkeletonGrid({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.crossAxisCount(context),
        childAspectRatio: Responsive.childAspectRatio(context),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return SkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SkeletonBox(width: 40, height: 40, borderRadius: 10),
              const SizedBox(height: 12),
              const SkeletonText(height: 16),
              const SizedBox(height: 8),
              SkeletonText(width: 80, height: 12),
            ],
          ),
        );
      },
    );
  }
}
