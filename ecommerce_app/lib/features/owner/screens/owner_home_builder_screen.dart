import 'package:flutter/material.dart';

import 'package:common_widgets/common_widgets.dart';
import 'package:provider/provider.dart';

import '../../../core/models/cms.dart';
import '../../../core/store/commerce_store.dart';
import '../../config/providers/business_config_provider.dart';
import '../../home/home_layout.dart';
import '../../home/home_sections.dart';

/// SPEC-18 "Home Builder": reorder and show/hide the home sections, and edit
/// the hero slides. Both feed the customer's home tab through the store.
class OwnerHomeBuilderScreen extends StatefulWidget {
  const OwnerHomeBuilderScreen({super.key});

  @override
  State<OwnerHomeBuilderScreen> createState() => _OwnerHomeBuilderScreenState();
}

class _OwnerHomeBuilderScreenState extends State<OwnerHomeBuilderScreen> {
  /// The §6.1 default ids — the first frame before [ensureHomeOrder] lands,
  /// and the fallback while no owner edit exists yet.
  List<String> get _defaultIds => [
        for (final section in HomeLayout.standard().sections) section.id,
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CommerceStore>().ensureHomeOrder(_defaultIds);
    });
  }

  String _titleFor(String id) {
    final spaced = id
        .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceFirst('new Arrivals', 'New arrivals');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CommerceStore>();
    final config = context.watch<BusinessConfigProvider>().config;
    final ids = store.homeSectionOrder.isEmpty
        ? _defaultIds
        : store.homeSectionOrder;
    final slides = store.heroSlides ?? defaultHeroSlides(config);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Builder'),
        actions: [
          IconButton(
            tooltip: 'Reset home page',
            icon: const Icon(Icons.restart_alt_outlined),
            onPressed: _confirmReset,
          ),
        ],
      ),
      body: ListView(
        padding: Responsive.padding(context),
        children: [
          Text(
            'Reorder the home page and hide what shoppers should not see. '
            'Hero slides sit under the section list.',
            style: AppTypography.bodyMuted.copyWith(height: 1.6),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Sections', style: AppTypography.eyebrow),
          const SizedBox(height: AppSpacing.sm),
          for (var index = 0; index < ids.length; index++)
            _SectionRow(
              title: _titleFor(ids[index]),
              visible: !store.homeSectionHidden.contains(ids[index]),
              index: index,
              count: ids.length,
              onMove: (delta) => store.moveHomeSection(index, delta),
              onToggle: (visible) =>
                  store.setHomeSectionVisible(ids[index], visible),
            ),
          const SizedBox(height: AppSpacing.xl),
          Text('Hero slides', style: AppTypography.eyebrow),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tap a slide to edit its copy, target route and image.',
            style: AppTypography.caption.copyWith(color: AppPalette.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var index = 0; index < slides.length; index++)
            _SlideRow(
              slide: slides[index],
              index: index,
              count: slides.length,
              onMove: (delta) => _moveSlide(index, delta),
              onToggle: (enabled) => _updateSlide(
                index,
                (slide) => slide.copyWith(enabled: enabled),
              ),
              onEdit: () => _editSlide(index),
              onRemove: () => _removeSlide(index),
            ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _editSlide(
              -1,
              seed: slides.isEmpty
                  ? const HeroSlide(
                      title: 'New slide',
                      subtitle: 'Describe the offer',
                      cta: 'Shop now',
                      location: '/catalogue',
                    )
                  : null,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add slide'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ slide edits

  /// Every mutation runs through this so the first edit seeds the explicit
  /// list from whatever the customer currently sees.
  void _mutateSlides(
    List<HeroSlide> Function(List<HeroSlide> current) edit,
  ) {
    final store = context.read<CommerceStore>();
    final config = context.read<BusinessConfigProvider>().config;
    final current = store.heroSlides ?? defaultHeroSlides(config);
    store.setHeroSlides(edit(current));
  }

  void _moveSlide(int index, int delta) {
    _mutateSlides((current) {
      final target = index + delta;
      if (target < 0 || target >= current.length) return current;
      final next = List<HeroSlide>.of(current);
      final item = next.removeAt(index);
      next.insert(target, item);
      return next;
    });
  }

  void _updateSlide(int index, HeroSlide Function(HeroSlide) change) {
    _mutateSlides((current) {
      if (index < 0 || index >= current.length) return current;
      final next = List<HeroSlide>.of(current);
      next[index] = change(next[index]);
      return next;
    });
  }

  void _removeSlide(int index) {
    _mutateSlides((current) {
      if (index < 0 || index >= current.length) return current;
      return [...current]..removeAt(index);
    });
  }

  Future<void> _editSlide(int index, {HeroSlide? seed}) async {
    final store = context.read<CommerceStore>();
    final config = context.read<BusinessConfigProvider>().config;
    final current = List<HeroSlide>.of(store.heroSlides ?? defaultHeroSlides(config));
    final isNew = seed != null;
    final source = isNew ? seed : current[index];
    if (isNew) current.add(seed);

    final titleController = TextEditingController(text: source.title);
    final subtitleController = TextEditingController(text: source.subtitle);
    final ctaController = TextEditingController(text: source.cta);
    final locationController = TextEditingController(text: source.location);
    final imageController = TextEditingController(text: source.imageUrl);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isNew ? 'New hero slide' : 'Edit hero slide'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: subtitleController,
                decoration: const InputDecoration(labelText: 'Subtitle'),
              ),
              TextField(
                controller: ctaController,
                decoration: const InputDecoration(labelText: 'Button label'),
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Target route',
                  hintText: '/catalogue',
                ),
              ),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'Optional — defaults to product photos',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved ?? false) {
      final replaceAt = isNew ? current.length - 1 : index;
      current[replaceAt] = current[replaceAt].copyWith(
        title: titleController.text.trim().isEmpty
            ? current[replaceAt].title
            : titleController.text.trim(),
        subtitle: subtitleController.text.trim(),
        cta: ctaController.text.trim().isEmpty
            ? current[replaceAt].cta
            : ctaController.text.trim(),
        location: locationController.text.trim().isEmpty
            ? current[replaceAt].location
            : locationController.text.trim(),
        imageUrl: imageController.text.trim(),
      );
      store.setHeroSlides(current);
    }

    titleController.dispose();
    subtitleController.dispose();
    ctaController.dispose();
    locationController.dispose();
    imageController.dispose();
  }

  Future<void> _confirmReset() async {
    final store = context.read<CommerceStore>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset home page?'),
        content: const Text(
          'Section order, hidden sections and hero slides return to the '
          'default layout.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      store.resetHomeLayout();
      store.resetHeroSlides();
    }
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.title,
    required this.visible,
    required this.index,
    required this.count,
    required this.onMove,
    required this.onToggle,
  });

  final String title;
  final bool visible;
  final int index;
  final int count;
  final ValueChanged<int> onMove;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppPalette.surfaceMuted,
        borderRadius: AppRadius.allMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Move up',
                icon: const Icon(Icons.keyboard_arrow_up),
                onPressed: index == 0 ? null : () => onMove(-1),
              ),
              IconButton(
                tooltip: 'Move down',
                icon: const Icon(Icons.keyboard_arrow_down),
                onPressed: index == count - 1 ? null : () => onMove(1),
              ),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.label.copyWith(
                    color: visible
                        ? AppPalette.textPrimary
                        : AppPalette.textMuted,
                  ),
                ),
              ),
              Switch(value: visible, onChanged: onToggle),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideRow extends StatelessWidget {
  const _SlideRow({
    required this.slide,
    required this.index,
    required this.count,
    required this.onMove,
    required this.onToggle,
    required this.onEdit,
    required this.onRemove,
  });

  final HeroSlide slide;
  final int index;
  final int count;
  final ValueChanged<int> onMove;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppPalette.surfaceMuted,
        borderRadius: AppRadius.allMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Move up',
                icon: const Icon(Icons.keyboard_arrow_up),
                onPressed: index == 0 ? null : () => onMove(-1),
              ),
              IconButton(
                tooltip: 'Move down',
                icon: const Icon(Icons.keyboard_arrow_down),
                onPressed: index == count - 1 ? null : () => onMove(1),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slide.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(
                        color: slide.enabled
                            ? AppPalette.textPrimary
                            : AppPalette.textMuted,
                      ),
                    ),
                    Text(
                      '${slide.cta} → ${slide.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit slide',
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Remove slide',
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onRemove,
              ),
              Switch(value: slide.enabled, onChanged: onToggle),
            ],
          ),
        ),
      ),
    );
  }
}
