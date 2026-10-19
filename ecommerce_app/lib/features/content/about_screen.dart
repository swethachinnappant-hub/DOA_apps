import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';

/// "World of Kirtilals" (§10.7 About): hero + the house story in a narrow
/// reading column.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
              Text('THE HOUSE', style: AppTypography.eyebrow),
              const SizedBox(height: AppSpacing.sm),
              Text('World of Kirtilals', style: AppTypography.display),
              const SizedBox(height: AppSpacing.lg),
              Container(height: 2, width: 64, color: AppPalette.copper),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'A jeweller is only as good as the trust behind the counter. '
                'Ours has been built across three generations, one hallmark '
                'at a time.',
                style: AppTypography.bodyMuted.copyWith(height: 1.8),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _StorySection(
                heading: 'Where it began',
                body:
                    'The first Kirtilals counter opened in the 1930s with a '
                    'simple promise: what you buy is what was stamped. That '
                    'rule still decides every design we sign off today.',
              ),
              _StorySection(
                heading: 'Craft before scale',
                body:
                    'Our karigars train for years before a design carries the '
                    'house name. Stone setting, filigree and enamel work stay '
                    'in-house so a piece can be traced back to the bench that '
                    'made it.',
              ),
              _StorySection(
                heading: 'Certified, always',
                body:
                    'Every diamond above 0.30 carats ships with an IGI or GIA '
                    'certificate, and every gold design is BIS hallmarked. '
                    'The numbers are printed on your invoice, not hidden in a '
                    'folder.',
              ),
              _StorySection(
                heading: 'From our stores to yours',
                body:
                    'Boutiques across South and West India welcome walk-ins, '
                    'and the online store ships the same inventory nationwide '
                    '— insured, tracked and packed by the same team.',
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorySection extends StatelessWidget {
  const _StorySection({required this.heading, required this.body});

  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: AppTypography.subtitle),
          const SizedBox(height: AppSpacing.md),
          Text(body, style: AppTypography.bodyMuted.copyWith(height: 1.75)),
        ],
      ),
    );
  }
}
