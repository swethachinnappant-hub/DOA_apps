import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/nav_helpers.dart';
import '../config/providers/business_config_provider.dart';
import 'contact_actions.dart';

/// Site footer (architecture Â§5.8): link columns Â· newsletter + social +
/// app block Â· copyright.
///
/// Compact renders each column as a collapsible accordion; newsletter and
/// copyright stay open. Desktop renders five columns in one row.
class SiteFooter extends StatefulWidget {
  const SiteFooter({super.key});

  /// Footer link columns (§5.8) — public so the route-map test can walk
  /// every target.
  static const linkColumns = <String, List<List<String>>>{
    'About Us': [
      ['About Us', '/world-of-kirtilals'],
      ['Blog', '/blog/country/kirtilals-india'],
      ['F.A.Q.', '/faq'],
      ['Give Feedback', '/feedback'],
    ],
    'Customer Delight': [
      ['Contact Us', '/contactusform'],
    ],
    'Policies': [
      ['Privacy Policy', '/privacy-policy'],
      ['Shipping & Returns', '/shipping-and-return-policy'],
      ['Investors', '/investors'],
      ['Terms of Service', '/terms-and-conditions'],
      ['CLP Terms & Conditions', '/clp-terms'],
    ],
    'Services': [
      ['Bespoke', '/bespoke'],
      ['Our Store', '/tryinstore'],
    ],
  };

  @override
  State<SiteFooter> createState() => _SiteFooterState();
}

class _SiteFooterState extends State<SiteFooter> {
  final _emailController = TextEditingController();
  String? _newsletterMessage;
  bool _subscribed = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final wide = Responsive.isExpanded(context);

    return Container(
      color: AppPalette.warm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.contentCap(context),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.pageInset(context),
                  vertical: AppSpacing.xxxl,
                ),
                child: wide ? _wideColumns() : _compactColumns(),
              ),
            ),
          ),
          _copyright(config.name),
        ],
      ),
    );
  }

  Widget _wideColumns() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in SiteFooter.linkColumns.entries)
          Expanded(child: _linkColumn(entry.key, entry.value)),
        const SizedBox(width: AppSpacing.xxl),
        Expanded(flex: 2, child: _newsletterBlock()),
      ],
    );
  }

  Widget _compactColumns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in SiteFooter.linkColumns.entries)
          _accordionColumn(entry.key, entry.value),
        const Divider(height: 1, color: AppPalette.hairline),
        const SizedBox(height: AppSpacing.lg),
        _newsletterBlock(),
      ],
    );
  }

  Widget _linkColumn(String heading, List<List<String>> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(heading.toUpperCase(), style: AppTypography.footerHeading),
        ),
        for (final link in links)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: InkWell(
              onTap: () => navTo(context, link[1]),
              child: Text(
                link[0],
                style: AppTypography.caption.copyWith(
                  color: AppPalette.textSupporting,
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _accordionColumn(String heading, List<List<String>> links) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.md),
        title: Text(heading.toUpperCase(), style: AppTypography.footerHeading),
        iconColor: AppPalette.copper,
        collapsedIconColor: AppPalette.textMuted,
        children: [
          for (final link in links)
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => navTo(context, link[1]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    link[0],
                    style: AppTypography.caption.copyWith(
                      color: AppPalette.textSupporting,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _newsletterBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('JOIN OUR EMAIL LIST', style: AppTypography.footerHeading),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Please sign me up to receive information about new designs and '
          'exclusive events.',
          style: AppTypography.caption.copyWith(
            color: AppPalette.textSupporting,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTypography.caption.copyWith(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Your email address',
                    hintStyle: TextStyle(fontSize: 13),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _subscribe(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              height: 42,
              child: FilledButton(
                onPressed: _subscribe,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  backgroundColor: AppPalette.copper,
                  textStyle: AppTypography.buttonUppercase.copyWith(
                    fontSize: 12,
                  ),
                ),
                child: const Text('SUBSCRIBE'),
              ),
            ),
          ],
        ),
        if (_newsletterMessage != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _newsletterMessage!,
            style: AppTypography.caption.copyWith(
              color: _subscribed ? AppPalette.success : AppPalette.error,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.lg,
          children: [
            for (final social in const [
              ('Facebook', 'https://www.facebook.com/kirtilalsonline'),
              ('Instagram', 'https://www.instagram.com/kirtilalsonline'),
              ('YouTube', 'https://www.youtube.com/kirtilalsonline/'),
              ('Pinterest', 'https://in.pinterest.com/kirtilalsonline/'),
            ])
              InkWell(
                onTap: () => showContactSheet(
                  context,
                  title: social.$1,
                  line1: social.$2,
                ),
                child: Text(
                  social.$1,
                  style: AppTypography.caption.copyWith(
                    color: AppPalette.copperDark,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppPalette.copperTint,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _subscribe() {
    final email = _emailController.text.trim();
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    setState(() {
      _subscribed = valid;
      _newsletterMessage = valid
          ? 'Thank you — you are on the list.'
          : 'Please enter a valid email address.';
      if (valid) _emailController.clear();
    });
  }

  Widget _copyright(String brandName) {
    return Container(
      color: AppPalette.drawerSurface,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.pageInset(context),
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Text(
            '© $brandName',
            style: AppTypography.caption.copyWith(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
