import 'package:common_widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/providers/business_config_provider.dart';
import '../services/virtual_page.dart';

/// §10.6: shared hero + switch gate for the virtual feature screens.
///
/// Off (the default) the shopper gets the designed "Coming soon" hero; on,
/// the screen's own demo UI renders under the same VIRTUAL eyebrow header.
class VirtualGate extends StatelessWidget {
  const VirtualGate({
    super.key,
    required this.title,
    required this.copy,
    required this.child,
  });

  final String title;
  final String copy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final enabled =
        context.watch<BusinessConfigProvider>().config.rules.virtualTryOn;
    if (!enabled) return VirtualPage(title: title, copy: copy);

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
              child,
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}
