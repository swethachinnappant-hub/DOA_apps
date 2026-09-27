import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:common_widgets/common_widgets.dart';
import '../providers/business_config_provider.dart';
import '../../../core/business_config.dart';

class BusinessConfigScreen extends StatelessWidget {
  const BusinessConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<BusinessConfigProvider>();
    final currentConfig = configProvider.config;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalise Your App'),
        actions: [
          TextButton(
            onPressed: () => context.go('/app'),
            child: const Text('Skip'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.lg,
          AppSpacing.screenH,
          AppSpacing.giant,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose your business type to shape the catalogue, categories and rules.',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.xl),
            _BusinessTypeGrid(
              selected: currentConfig.type,
              onSelect: configProvider.setBusinessType,
            ),
            const SizedBox(height: AppSpacing.xxxl),

            _BrandColorSection(config: currentConfig, provider: configProvider),
            const SizedBox(height: AppSpacing.xxxl),

            if (currentConfig.type != BusinessType.custom) ...[
              Text('Preview', style: AppTypography.sectionTitle),
              const SizedBox(height: AppSpacing.md),
              _PreviewCard(config: currentConfig),
              const SizedBox(height: AppSpacing.xxxl),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/app'),
                child: Text('Continue to ${currentConfig.name}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessTypeGrid extends StatelessWidget {
  final BusinessType selected;
  final ValueChanged<BusinessType> onSelect;

  const _BusinessTypeGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.isDesktop(context)
            ? 4
            : (Responsive.isTablet(context) ? 3 : 2),
        childAspectRatio: 0.98,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: BusinessType.values.length,
      itemBuilder: (context, index) {
        final type = BusinessType.values[index];
        final config = BusinessConfig.getConfig(type);
        final isSelected = type == selected;

        return Material(
          color: AppPalette.surface,
          borderRadius: AppRadius.allMd,
          child: InkWell(
            onTap: () => onSelect(type),
            borderRadius: AppRadius.allMd,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: AppRadius.allMd,
                border: Border.all(
                  color: isSelected ? config.primaryColor : AppPalette.border,
                  width: isSelected ? 1.6 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: config.accentColor,
                        borderRadius: AppRadius.allSm,
                      ),
                      child: Icon(
                        config.icon,
                        size: 20,
                        color: config.primaryColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        config.name,
                        textAlign: TextAlign.center,
                        style: AppTypography.label.copyWith(
                          color: isSelected
                              ? config.primaryColor
                              : AppPalette.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: config.primaryColor,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BrandColorSection extends StatelessWidget {
  final BusinessConfig config;
  final BusinessConfigProvider provider;

  const _BrandColorSection({required this.config, required this.provider});

  Future<void> _pick(
    BuildContext context, {
    required Color current,
    required String title,
    required void Function(Color) onPicked,
  }) async {
    final picked = await showAppColorPicker(
      context,
      initialColor: current,
      title: title,
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Brand Colours', style: AppTypography.sectionTitle),
                  const SizedBox(height: 2),
                  Text(
                    'Pick a preset or set your own main and sub colours.',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            if (config.hasCustomColors)
              TextButton(
                onPressed: provider.resetColors,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Reset'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: BusinessConfig.colorOptions.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final option = BusinessConfig.colorOptions[index];
              final isSelected = option.primary.toARGB32() == config.primaryColor.toARGB32() &&
                  option.secondary.toARGB32() == config.secondaryColor.toARGB32();
              return GestureDetector(
                onTap: () => provider.applyPalette(option),
                child: Container(
                  width: 56,
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppPalette.surface,
                    borderRadius: AppRadius.allSm,
                    border: Border.all(
                      color: isSelected ? option.primary : AppPalette.border,
                      width: isSelected ? 1.6 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: ColoredBox(color: option.primary),
                              ),
                              Expanded(
                                flex: 2,
                                child: ColoredBox(color: option.secondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        option.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        _ColorRow(
          label: 'Main Colour',
          hint: 'Buttons, prices, active icons',
          color: config.primaryColor,
          onTap: () => _pick(
            context,
            current: config.primaryColor,
            title: 'Main Colour',
            onPicked: (c) => provider.updateColors(
              primaryColor: c,
              accentColor: _deriveAccent(c),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ColorRow(
          label: 'Sub Colour',
          hint: 'Gradients and secondary accents',
          color: config.secondaryColor,
          onTap: () => _pick(
            context,
            current: config.secondaryColor,
            title: 'Sub Colour',
            onPicked: (c) => provider.updateColors(secondaryColor: c),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ColorRow(
          label: 'Tint Colour',
          hint: 'Soft backgrounds and chips',
          color: config.accentColor,
          onTap: () => _pick(
            context,
            current: config.accentColor,
            title: 'Tint Colour',
            onPicked: (c) => provider.updateColors(accentColor: c),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
        _LivePreview(config: config),
      ],
    );
  }

  static Color _deriveAccent(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    return hsl
        .withLightness((hsl.lightness + 0.82).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 0.42).clamp(0.0, 1.0))
        .toColor();
  }
}

class _ColorRow extends StatelessWidget {
  final String label;
  final String hint;
  final Color color;
  final VoidCallback onTap;

  const _ColorRow({
    required this.label,
    required this.hint,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.surface,
      borderRadius: AppRadius.allMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allMd,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.allMd,
            border: Border.all(color: AppPalette.border),
          ),
          child: Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: AppRadius.allSm,
                  border: Border.all(color: AppPalette.border),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: AppTypography.subtitle),
                    const SizedBox(height: 1),
                    Text(hint, style: AppTypography.caption),
                  ],
                ),
              ),
              Text(
                '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                style: AppTypography.caption,
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.tune,
                size: 18,
                color: AppPalette.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePreview extends StatelessWidget {
  final BusinessConfig config;

  const _LivePreview({required this.config});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Live Preview', style: AppTypography.label),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.allMd,
            border: Border.all(color: AppPalette.border),
            color: AppPalette.surfaceMuted,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(config.name, style: AppTypography.title),
              const SizedBox(height: 2),
              Text(config.tagline, style: AppTypography.caption),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: config.primaryColor,
                      borderRadius: AppRadius.allPill,
                    ),
                    child: Text(
                      'Primary',
                      style: AppTypography.caption.copyWith(
                        color: config.onPrimaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: config.secondaryColor,
                      borderRadius: AppRadius.allPill,
                    ),
                    child: Text(
                      'Secondary',
                      style: AppTypography.caption.copyWith(
                        color: _onColor(config.secondaryColor),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: config.accentColor,
                      borderRadius: AppRadius.allPill,
                    ),
                    child: Text(
                      'Tint chip',
                      style: AppTypography.caption.copyWith(
                        color: config.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  Color _onColor(Color color) =>
      color.computeLuminance() > 0.55 ? Colors.black : Colors.white;
}

class _PreviewCard extends StatelessWidget {
  final BusinessConfig config;

  const _PreviewCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: config.accentColor,
                  borderRadius: AppRadius.allSm,
                ),
                child: Icon(config.icon, color: config.primaryColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(config.name, style: AppTypography.subtitle),
                    const SizedBox(height: 1),
                    Text(
                      config.tagline,
                      style: AppTypography.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Categories', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.chipGap,
            runSpacing: AppSpacing.chipGap,
            children: config.categories
                .take(6)
                .map(
                  (cat) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: config.accentColor,
                      borderRadius: AppRadius.allPill,
                    ),
                    child: Text(
                      cat,
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        color: config.primaryColor,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          if (config.categories.length > 6) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '+${config.categories.length - 6} more categories',
              style: AppTypography.caption,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text('Product Fields', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.chipGap,
            runSpacing: AppSpacing.chipGap,
            children: config.productFields
                .map(
                  (field) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.surfaceMuted,
                      borderRadius: AppRadius.allPill,
                      border: Border.all(color: AppPalette.border),
                    ),
                    child: Text(field, style: AppTypography.caption.copyWith(fontSize: 11)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
