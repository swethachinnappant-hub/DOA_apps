import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';

/// Shimmer placeholder for the home stack (§6.3): mirrors the real layout so
/// the switch to content does not jump, and stays on screen for the minimum
/// ~300 ms that hides first-paint flicker.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final railWidth = Responsive.isDesktop(context) ? 272.0 : 202.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 150, height: 12, borderRadius: 4),
              SizedBox(height: AppSpacing.sm),
              SkeletonBox(width: 240, height: 26, borderRadius: 6),
              SizedBox(height: AppSpacing.md),
              SkeletonBox(height: 44, borderRadius: 22),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: SkeletonBox(
            height: Responsive.isDesktop(context) ? 300 : 224,
            borderRadius: 16,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: SkeletonBox(width: 180, height: 18, borderRadius: 4),
        ),
        const SizedBox(height: AppSpacing.md),
        const SizedBox(
          height: 96,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: Row(
              children: [
                SkeletonCircle(size: 68),
                SizedBox(width: AppSpacing.md),
                SkeletonCircle(size: 68),
                SizedBox(width: AppSpacing.md),
                SkeletonCircle(size: 68),
                SizedBox(width: AppSpacing.md),
                SkeletonCircle(size: 68),
                SizedBox(width: AppSpacing.md),
                SkeletonCircle(size: 68),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: SkeletonBox(width: 200, height: 18, borderRadius: 4),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: Responsive.isDesktop(context)
              ? 468
              : Responsive.isTablet(context)
              ? 420
              : 388,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: Row(
              children: [
                SkeletonBox(width: railWidth, height: double.infinity),
                const SizedBox(width: AppSpacing.lg),
                SkeletonBox(width: railWidth, height: double.infinity),
                const SizedBox(width: AppSpacing.lg),
                SkeletonBox(width: railWidth, height: double.infinity),
                const SizedBox(width: AppSpacing.lg),
                SkeletonBox(width: railWidth, height: double.infinity),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: SkeletonBox(width: 160, height: 18, borderRadius: 4),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: SkeletonBox(
            height: Responsive.isDesktop(context) ? 120 : 160,
            borderRadius: 16,
          ),
        ),
      ],
    );
  }
}
