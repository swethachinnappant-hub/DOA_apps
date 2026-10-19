import 'package:flutter/material.dart';

import 'package:common_widgets/common_widgets.dart';
import 'package:provider/provider.dart';

import '../../../core/models/cms.dart';
import '../../../core/navigation/menu_data.dart';
import '../../../core/store/commerce_store.dart';

/// SPEC-18 "Categories & Menu": edit the customer-facing navigation tree —
/// labels, icons, order and show/hide — for the desktop top menu and the
/// mobile drawer. Every change notifies the store, so the storefront chrome
/// reflects it with no restart.
class OwnerCategoriesScreen extends StatefulWidget {
  const OwnerCategoriesScreen({super.key});

  @override
  State<OwnerCategoriesScreen> createState() => _OwnerCategoriesScreenState();
}

class _OwnerCategoriesScreenState extends State<OwnerCategoriesScreen> {
  /// `header` = desktop top menu, `drawer` = mobile drawer.
  String _view = 'header';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CommerceStore>();
    final isHeader = _view == 'header';
    final keys = isHeader ? store.navHeaderKeys : store.navDrawerKeys;
    final menus = {for (final menu in store.allMenus) menu.route: menu};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories & Menu'),
        actions: [
          IconButton(
            tooltip: 'Reset to defaults',
            icon: const Icon(Icons.restart_alt_outlined),
            onPressed: () => _confirmReset(),
          ),
        ],
      ),
      body: ListView(
        padding: Responsive.padding(context),
        children: [
          Text(
            'Edit what shoppers see in the navigation. Renames, reordering '
            'and hidden entries land in the storefront immediately.',
            style: AppTypography.bodyMuted.copyWith(height: 1.6),
          ),
          const SizedBox(height: AppSpacing.lg),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'header', label: Text('Top menu')),
              ButtonSegment(value: 'drawer', label: Text('Drawer')),
            ],
            selected: {_view},
            onSelectionChanged: (value) => setState(() => _view = value.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var index = 0; index < keys.length; index++)
            _MenuRow(
              key: ValueKey('$_view-${keys[index]}'),
              menu: menus[keys[index]]!,
              patch: store.navPatchFor(keys[index]),
              index: index,
              count: keys.length,
              onEdit: () => _editEntry(keys[index]),
              onMove: (delta) =>
                  store.moveNavEntry(_view, index, delta),
              onToggleVisible: (visible) =>
                  store.setNavVisible(keys[index], visible),
            ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _pickMenuToAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add menu'),
          ),
        ],
      ),
    );
  }

  Future<void> _editEntry(String route) async {
    final store = context.read<CommerceStore>();
    final menu = store.allMenus.firstWhere(
      (menu) => menu.route == route,
      orElse: () => throw StateError('unknown menu $route'),
    );
    final patch = store.navPatchFor(route);

    final labelController = TextEditingController(
      text: patch.label ?? menu.label,
    );
    var iconCode = patch.iconCode;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text('Edit ${menu.label}'),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: labelController,
                      decoration: InputDecoration(
                        labelText: 'Label',
                        hintText: menu.label,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Icon', style: AppTypography.label),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final choice in navIconChoices)
                          InkWell(
                            borderRadius: AppRadius.allSm,
                            onTap: () => setDialogState(
                              () => iconCode = choice.codePoint,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: AppRadius.allSm,
                                border: Border.all(
                                  color: iconCode == choice.codePoint
                                      ? AppPalette.copper
                                      : AppPalette.border,
                                ),
                              ),
                              child: Icon(choice, size: 20),
                            ),
                          ),
                        ActionChip(
                          label: const Text('Default'),
                          onPressed: () => setDialogState(() => iconCode = 0),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      menu.route,
                      style: AppTypography.caption.copyWith(
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    store.setNavLabel(route, '');
                    store.setNavIcon(route, 0);
                    store.setNavVisible(route, true);
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Revert'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _confirmRemove(route);
                  },
                  child: const Text('Remove'),
                ),
                FilledButton(
                  onPressed: () {
                    store.setNavLabel(route, labelController.text);
                    store.setNavIcon(route, iconCode ?? 0);
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    labelController.dispose();
  }

  Future<void> _pickMenuToAdd() async {
    final store = context.read<CommerceStore>();
    final keys = _view == 'header' ? store.navHeaderKeys : store.navDrawerKeys;
    final missing = store.allMenus
        .where((menu) => !keys.contains(menu.route))
        .toList();
    if (missing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Every menu is already listed.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add menu'),
        content: SizedBox(
          width: 380,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final menu in missing)
                ListTile(
                  leading: Icon(menu.icon, size: 20),
                  title: Text(menu.label),
                  subtitle: Text(
                    menu.route,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    store.appendNavEntry(_view, menu.route);
                    Navigator.of(dialogContext).pop();
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(String route) async {
    final store = context.read<CommerceStore>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove from menu?'),
        content: Text('Shoppers lose this entry from the $_view list. '
            'You can add it back with “Add menu”.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) store.removeNavEntry(_view, route);
  }

  Future<void> _confirmReset() async {
    final store = context.read<CommerceStore>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset navigation?'),
        content: const Text(
          'Labels, icons, order and visibility return to the verified '
          'defaults for both menus.',
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
    if (confirmed ?? false) store.resetNav();
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    super.key,
    required this.menu,
    required this.patch,
    required this.index,
    required this.count,
    required this.onEdit,
    required this.onMove,
    required this.onToggleVisible,
  });

  final NavMenu menu;
  final NavMenuState patch;
  final int index;
  final int count;
  final VoidCallback onEdit;
  final ValueChanged<int> onMove;
  final ValueChanged<bool> onToggleVisible;

  IconData get _icon => navIconFor(patch.iconCode, menu.icon);

  @override
  Widget build(BuildContext context) {
    final label = patch.label ?? menu.label;
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
              Icon(_icon, size: 20, color: AppPalette.copperDark),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(
                        color: patch.visible
                            ? AppPalette.textPrimary
                            : AppPalette.textMuted,
                      ),
                    ),
                    Text(
                      patch.label == null
                          ? menu.route
                          : '${menu.route} · default “${menu.label}”',
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
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
              ),
              Switch(
                value: patch.visible,
                onChanged: onToggleVisible,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
