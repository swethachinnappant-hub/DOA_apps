import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';

import '../../core/navigation/nav_helpers.dart';

/// The designed "Coming soon" hero §10.6 asks for while the live camera,
/// panorama and shared-shortlist backends are not wired up yet.
class VirtualPage extends StatelessWidget {
  const VirtualPage({super.key, required this.title, required this.copy});

  final String title;
  final String copy;

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pageInset(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: EdgeInsets.fromLTRB(padding, AppSpacing.xxxl, padding, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('VIRTUAL', style: AppTypography.eyebrow),
              const SizedBox(height: AppSpacing.sm),
              Text(title, style: AppTypography.display),
              const SizedBox(height: AppSpacing.lg),
              Container(height: 2, width: 64, color: AppPalette.copper),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppPalette.warm,
                  borderRadius: AppRadius.allMd,
                  border: Border.all(color: AppPalette.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome_outlined,
                      size: 30,
                      color: AppPalette.copper,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Coming soon', style: AppTypography.subtitle),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      copy,
                      style: AppTypography.bodyMuted.copyWith(height: 1.7),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: 'BROWSE THE CATALOGUE',
                type: AppButtonType.filled,
                onPressed: () => navTo(context, '/catalogue'),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}
