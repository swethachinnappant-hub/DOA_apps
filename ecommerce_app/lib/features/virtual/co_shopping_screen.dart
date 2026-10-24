import 'package:common_widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/business_config.dart';
import '../../core/navigation/nav_helpers.dart';
import '../../core/pricing.dart';
import '../../core/product.dart';
import '../../core/store/commerce_store.dart';
import '../config/providers/business_config_provider.dart';
import 'virtual_gate.dart';

class ShortlistReaction {
  const ShortlistReaction(this.emoji, this.label);

  final String emoji;
  final String label;
}

const _reactions = <ShortlistReaction>[
  ShortlistReaction('❤️', 'Love'),
  ShortlistReaction('❌', 'Pass'),
];

/// §10.6: decide with friends — a shared shortlist with ❤️/❌ reactions and a
/// comment thread, plus a copyable invite link. All local demo state until a
/// realtime backend is wired up.
class CoShoppingScreen extends StatefulWidget {
  const CoShoppingScreen({super.key});

  @override
  State<CoShoppingScreen> createState() => _CoShoppingScreenState();
}

class _CoShoppingScreenState extends State<CoShoppingScreen> {
  final Set<String> _shortlisted = {};
  final Map<String, Map<int, int>> _votes = {};
  final List<(String, String)> _comments = [
    ('Meera', 'The first necklace would match the saree.'),
    ('You', 'Adding it to the shortlist — tap ❤️ to vote.'),
  ];
  final _linkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _linkController.text = 'kirtilals.example/co/bridge-set-24';
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final candidates = store.shopProducts.take(4).toList();

    return VirtualGate(
      title: 'Decide With Friends',
      copy:
          'Share a shortlist, let friends react with a heart or a pass and '
          'read their notes in one place. The shared shortlist opens soon.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Build the shortlist, send the link and let the group vote. '
            'Nothing leaves this device in the demo.',
            style: AppTypography.bodyMuted.copyWith(height: 1.7),
          ),
          const SizedBox(height: AppSpacing.lg),
          _linkRow(config),
          const SizedBox(height: AppSpacing.lg),
          _shortlist(candidates),
          const SizedBox(height: AppSpacing.lg),
          _thread(),
        ],
      ),
    );
  }

  Widget _linkRow(BusinessConfig config) {
    final allowShare = config.rules.allowShare;

    return Row(
      children: [
        Expanded(
          child: AppTextField(
            key: const ValueKey('co-link-field'),
            controller: _linkController,
            readOnly: true,
            label: 'Shortlist link',
            prefixIcon: const Icon(Icons.link),
          ),
        ),
        if (allowShare) ...[
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            key: const ValueKey('co-copy-link'),
            tooltip: 'Copy shortlist link',
            icon: const Icon(Icons.copy_rounded),
            onPressed: _copyLink,
          ),
        ],
      ],
    );
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _linkController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shortlist link copied'),
        duration: Duration(milliseconds: 1400),
      ),
    );
  }

  Widget _shortlist(List<Product> candidates) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final product in candidates)
          _shortlistCard(product, candidates.indexOf(product)),
      ],
    );
  }

  Widget _shortlistCard(Product product, int index) {
    final on = _shortlisted.contains(product.id);
    final width = Responsive.isMobile(context) ? 160.0 : 220.0;

    return SizedBox(
      width: width,
      child: AppCard(
        key: ValueKey('co-card-${product.id}'),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 96,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppPalette.surfaceMuted,
                borderRadius: AppRadius.allSm,
              ),
              child: ProductImageTile(
                url: product.images.isEmpty ? '' : product.images.first,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              Pricing.money(
                product.price,
                currencySymbol:
                    context.read<BusinessConfigProvider>().config.currencySymbol,
              ),
              style: AppTypography.price.copyWith(fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var r = 0; r < _reactions.length; r++)
                  Semantics(
                    button: true,
                    label: '${_reactions[r].label} ${product.name}',
                    child: InkWell(
                      key: ValueKey('co-vote-${product.id}-$r'),
                      borderRadius: AppRadius.allSm,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          final counts = _votes.putIfAbsent(
                            product.id,
                            () => {0: 0, 1: 0},
                          );
                          counts[r] = (counts[r] ?? 0) + 1;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: Text(
                          '${_reactions[r].emoji} '
                          '${_votes[product.id]?[r] ?? 0}',
                          style: AppTypography.caption,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: on ? 'ON SHORTLIST' : 'ADD TO SHORTLIST',
                type: on ? AppButtonType.outlined : AppButtonType.filled,
                height: 40,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (on) {
                      _shortlisted.remove(product.id);
                    } else {
                      _shortlisted.add(product.id);
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thread() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppPalette.warm,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppPalette.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THE GROUP SAYS', style: AppTypography.eyebrow),
          const SizedBox(height: AppSpacing.md),
          for (final (author, message) in _comments)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$author: ',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: message,
                      style: AppTypography.body,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            text: 'INVITE MORE FRIENDS',
            icon: Icons.person_add_outlined,
            type: AppButtonType.outlined,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Invites open when the shared shortlist ships',
                  ),
                  duration: Duration(milliseconds: 1400),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: () => navTo(context, '/catalogue'),
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: const Text('Keep browsing designs'),
          ),
        ],
      ),
    );
  }
}
