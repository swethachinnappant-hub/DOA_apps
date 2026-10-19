import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';

/// Shared contact sheet for the verified support numbers (§5.1 / §5.8).
///
/// Dialling and `wa.me` deep links activate once `url_launcher` is wired in
/// (architecture §16.5); until then the details are shown for copy-out.
void showContactSheet(
  BuildContext context, {
  required String title,
  required String line1,
  String? line2,
}) {
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.title),
            const SizedBox(height: AppSpacing.md),
            SelectableText(line1, style: AppTypography.body),
            if (line2 != null) ...[
              const SizedBox(height: AppSpacing.xs),
              SelectableText(line2, style: AppTypography.bodyMuted),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Dialling and WhatsApp deep links activate once contact '
              'handling is wired up.',
              style: AppTypography.caption.copyWith(
                color: AppPalette.textMuted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
