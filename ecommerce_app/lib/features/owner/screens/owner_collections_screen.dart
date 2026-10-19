import 'package:flutter/material.dart';

import 'package:common_widgets/common_widgets.dart';
import 'package:provider/provider.dart';

import '../../../core/models/cms.dart';
import '../../../core/navigation/menu_data.dart';
import '../../../core/store/commerce_store.dart';

/// SPEC-18 "Collections": CRUD the curated tiles that feed the home rail —
/// name, route, optional hero image, assigned products, order and visibility.
class OwnerCollectionsScreen extends StatefulWidget {
  const OwnerCollectionsScreen({super.key});

  @override
  State<OwnerCollectionsScreen> createState() => _OwnerCollectionsScreenState();
}

class _OwnerCollectionsScreenState extends State<OwnerCollectionsScreen> {
  @override
  Widget build(BuildContext context) {
    final store = context.watch<CommerceStore>();
    final collections = store.collections;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        actions: [
          IconButton(
            tooltip: 'New collection',
            icon: const Icon(Icons.add),
            onPressed: _createCollection,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCollection,
        icon: const Icon(Icons.add),
        label: const Text('New collection'),
      ),
      body: collections.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'No collections yet — create one to place a tile on the '
                  'home page.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMuted,
                ),
              ),
            )
          : ListView.separated(
              padding: Responsive.padding(context).copyWith(bottom: 96),
              itemCount: collections.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final collection = collections[index];
                return Material(
                  color: AppPalette.surfaceMuted,
                  borderRadius: AppRadius.allMd,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Move up',
                          icon: const Icon(Icons.keyboard_arrow_up),
                          onPressed: index == 0
                              ? null
                              : () => store.moveCollection(index, -1),
                        ),
                        IconButton(
                          tooltip: 'Move down',
                          icon: const Icon(Icons.keyboard_arrow_down),
                          onPressed: index == collections.length - 1
                              ? null
                              : () => store.moveCollection(index, 1),
                        ),
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: collection.imageUrl.isEmpty
                              ? Icon(
                                  StoreNav.categoryIcon(collection.name),
                                  color: AppPalette.copperDark,
                                )
                              : ClipRRect(
                                  borderRadius: AppRadius.allSm,
                                  child: Image.network(
                                    collection.imageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => Icon(
                                      StoreNav.categoryIcon(collection.name),
                                      color: AppPalette.copperDark,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                collection.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.label.copyWith(
                                  color: collection.visible
                                      ? AppPalette.textPrimary
                                      : AppPalette.textMuted,
                                ),
                              ),
                              Text(
                                '${collection.route} · '
                                '${collection.productIds.length} product(s)',
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
                          onPressed: () => _editCollection(collection),
                        ),
                        Switch(
                          value: collection.visible,
                          onChanged: (visible) => store.upsertCollection(
                            collection.copyWith(visible: visible),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _createCollection() async {
    final store = context.read<CommerceStore>();
    final nameController = TextEditingController();
    final routeController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New collection'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: routeController,
                decoration: const InputDecoration(
                  labelText: 'Route',
                  hintText: '/voyage-of-hearts',
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
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (saved ?? false) {
      final name = nameController.text.trim();
      if (name.isNotEmpty) {
        final route = routeController.text.trim().isEmpty
            ? '/${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}'
            : routeController.text.trim();
        store.upsertCollection(
          ShopCollection(
            id: store.collectionIdFor(route),
            name: name,
            route: route,
          ),
        );
      }
    }
    nameController.dispose();
    routeController.dispose();
  }

  Future<void> _editCollection(ShopCollection collection) async {
    final store = context.read<CommerceStore>();
    final nameController = TextEditingController(text: collection.name);
    final routeController = TextEditingController(text: collection.route);
    final imageController = TextEditingController(text: collection.imageUrl);
    var productIds = List<String>.of(collection.productIds);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text('Edit ${collection.name}'),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: routeController,
                    decoration: const InputDecoration(labelText: 'Route'),
                  ),
                  TextField(
                    controller: imageController,
                    decoration: const InputDecoration(
                      labelText: 'Hero image URL',
                      hintText: 'Optional',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.playlist_add_check, size: 18),
                      label: Text('Assign products (${productIds.length})'),
                      onPressed: () async {
                        final picked = await _pickProducts(productIds);
                        if (picked != null) {
                          setDialogState(() => productIds = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _confirmDelete(collection);
                },
                child: const Text('Delete'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    store.upsertCollection(
                      collection.copyWith(
                        name: name,
                        route: routeController.text.trim().isEmpty
                            ? collection.route
                            : routeController.text.trim(),
                        imageUrl: imageController.text.trim(),
                        productIds: productIds,
                      ),
                    );
                  }
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    nameController.dispose();
    routeController.dispose();
    imageController.dispose();
  }

  Future<List<String>?> _pickProducts(List<String> selected) async {
    final store = context.read<CommerceStore>();
    final next = List<String>.of(selected);
    final products = store.allProducts;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Assign products'),
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final product in products)
                CheckboxListTile(
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  value: next.contains(product.id),
                  onChanged: (checked) {
                    if (checked ?? false) {
                      next.add(product.id);
                    } else {
                      next.remove(product.id);
                    }
                    // Rebuild the dialog list through its own state.
                    (dialogContext as Element).markNeedsBuild();
                  },
                ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    return next;
  }

  Future<void> _confirmDelete(ShopCollection collection) async {
    final store = context.read<CommerceStore>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${collection.name}?'),
        content: const Text('Its tile disappears from the home rail.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) store.removeCollection(collection.id);
  }
}
