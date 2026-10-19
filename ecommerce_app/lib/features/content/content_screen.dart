import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';

import 'content_pages.dart';

/// The shared §10.7 reading shell: ≈760 px column, serif H1, copper rule and
/// generous line-height. FAQ pages render their questions as accordions;
/// legal and company pages render heading + paragraph sections.
class ContentScreen extends StatelessWidget {
  const ContentScreen({super.key, required this.page});

  final ContentPageSpec page;

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
              if (page.eyebrow != null) ...[
                Text(page.eyebrow!, style: AppTypography.eyebrow),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(page.title, style: AppTypography.display),
              const SizedBox(height: AppSpacing.lg),
              Container(height: 2, width: 64, color: AppPalette.copper),
              if (page.intro != null) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  page.intro!,
                  style: AppTypography.bodyMuted.copyWith(height: 1.7),
                ),
              ],
              if (page.faqs.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                for (final faq in page.faqs)
                  _FaqTile(question: faq.question, answer: faq.answer),
              ],
              for (final section in page.sections) ...[
                const SizedBox(height: AppSpacing.xxl),
                Text(section.heading, style: AppTypography.subtitle),
                const SizedBox(height: AppSpacing.md),
                for (final paragraph in section.paragraphs) ...[
                  Text(
                    paragraph,
                    style: AppTypography.bodyMuted.copyWith(height: 1.75),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppPalette.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          title: Text(question, style: AppTypography.subtitle.copyWith(fontSize: 14.5)),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: AppTypography.bodyMuted.copyWith(height: 1.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
