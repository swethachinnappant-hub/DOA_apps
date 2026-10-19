import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';

class BlogArticle {
  const BlogArticle({
    required this.title,
    required this.excerpt,
    required this.date,
    required this.paragraphs,
  });

  final String title;
  final String excerpt;
  final String date;
  final List<String> paragraphs;
}

const _articles = <BlogArticle>[
  BlogArticle(
    title: 'How to read a diamond certificate',
    excerpt:
        'Cut, colour, clarity and carat — what the grading report actually '
        'says about the stone you are buying.',
    date: '12 Sep 2026',
    paragraphs: [
      'A grading report is a map of the stone, not a scorecard. Start with '
      'the cut grade: it decides how the diamond plays with light, and it '
      'matters more than a colour step or two.',
      'Clarity grades describe inclusions under 10× magnification. Most '
      'grades between VS1 and SI2 are eye-clean — ask for the plot diagram '
      'to see where the marks sit before you decide.',
      'Carat is weight, not size. Two stones of the same weight can face up '
      'differently depending on how deep the cut is, so compare diameter '
      'measurements when you shortlist.',
    ],
  ),
  BlogArticle(
    title: 'Caring for gold jewellery through the monsoon',
    excerpt:
        'Humidity, perfume and pool water are the three enemies of a bright '
        'finish. Here is the seasonal routine our karigars recommend.',
    date: '28 Aug 2026',
    paragraphs: [
      'Store each piece in the pouch it arrived in — humidity sticks '
      'neighbouring pieces together and scratches the polish.',
      'Apply perfume before you wear jewellery, not after. Alcohol and '
      'aerosols dull the surface within a few wears.',
      'Wipe with a soft dry cloth at the end of the day. Once a year, bring '
      'pieces to any boutique for a professional clean — it is included for '
      'life.',
    ],
  ),
  BlogArticle(
    title: 'Bandhan: the bridal edit, explained',
    excerpt:
        'What goes into a bridal set, from the first sketch to the last '
        'stone, and how to order one in time for the muhurat.',
    date: '5 Aug 2026',
    paragraphs: [
      'A bridal set is designed as a family — necklace, earrings and maang '
      'tikka share motif proportions so they sit together on the day.',
      'Allow two to three weeks for made-to-order pieces after design '
      'approval. Bring the outfit swatch to the appointment so the metal '
      'tone is matched to the embroidery.',
      'Every Bandhan piece ships with its certificate and a care kit, and '
      'the set is photographed on you at the store if you visit before the '
      'wedding.',
    ],
  ),
];

/// Blog list + article reader (§10.7). Articles open in a local push so the
/// §4.3 blog path keeps working without extra router entries.
class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});

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
              Text('JOURNAL', style: AppTypography.eyebrow),
              const SizedBox(height: AppSpacing.sm),
              Text('The Kirtilals Blog', style: AppTypography.display),
              const SizedBox(height: AppSpacing.lg),
              Container(height: 2, width: 64, color: AppPalette.copper),
              const SizedBox(height: AppSpacing.xl),
              for (final article in _articles) ...[
                _ArticleCard(
                  article: article,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _ArticleScreen(article: article),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article, required this.onTap});

  final BlogArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.surface,
      borderRadius: AppRadius.allMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allMd,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.allMd,
            border: Border.all(color: AppPalette.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.date.toUpperCase(),
                  style: AppTypography.overline.copyWith(
                    color: AppPalette.textHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(article.title, style: AppTypography.subtitle),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  article.excerpt,
                  style: AppTypography.bodyMuted.copyWith(height: 1.6),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'READ MORE',
                  style: AppTypography.overline.copyWith(
                    color: AppPalette.copper,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArticleScreen extends StatelessWidget {
  const _ArticleScreen({required this.article});

  final BlogArticle article;

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pageInset(context);

    return Scaffold(
      appBar: AppBar(title: const Text('The Kirtilals Blog')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: EdgeInsets.fromLTRB(padding, AppSpacing.xl, padding, 0),
            children: [
              Text(
                article.date.toUpperCase(),
                style: AppTypography.overline.copyWith(
                  color: AppPalette.textHint,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(article.title, style: AppTypography.display.copyWith(fontSize: 28)),
              const SizedBox(height: AppSpacing.lg),
              Container(height: 2, width: 64, color: AppPalette.copper),
              const SizedBox(height: AppSpacing.xl),
              for (final paragraph in article.paragraphs) ...[
                Text(
                  paragraph,
                  style: AppTypography.bodyMuted.copyWith(height: 1.8),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}
