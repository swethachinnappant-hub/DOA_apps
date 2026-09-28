import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../../core/demo_catalog.dart';
import '../../../core/product.dart';
import '../../../core/store/commerce_store.dart';
import '../../auth/providers/auth_provider.dart';
import '../../config/providers/business_config_provider.dart';

/// Create or edit a listing.
///
/// Photos are the thing sellers care about most, so the image editor sits at
/// the top and accepts as many entries as the product needs.
class OwnerProductFormScreen extends StatefulWidget {
  const OwnerProductFormScreen({super.key, required this.productId});

  /// `null` means this is a new listing.
  final String? productId;

  @override
  State<OwnerProductFormScreen> createState() => _OwnerProductFormScreenState();
}

class _OwnerProductFormScreenState extends State<OwnerProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _price = TextEditingController();
  final _mrp = TextEditingController();
  final _stock = TextEditingController();
  final _highlights = TextEditingController();
  final _description = TextEditingController();

  /// One controller per label the business declares in `productFields`
  /// (Gold Purity, Gross Weight, ... for a jewellery store).
  final Map<String, TextEditingController> _specFields = {};
  bool _specFieldsReady = false;

  final List<String> _images = [];
  final Set<String> _sizes = {};
  final Set<String> _shades = {};
  String? _category;
  String? _badge;
  bool _saving = false;
  String? _formError;

  Product? _existing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_existing == null && widget.productId != null) {
      final store = context.read<CommerceStore>();
      final found = store.productById(widget.productId!);
      if (found != null) {
        _existing = found;
        _name.text = found.name;
        _brand.text = found.brand;
        _price.text = '${found.price}';
        _mrp.text = '${found.mrp}';
        _stock.text = '${found.stock}';
        _highlights.text = found.highlights.join('\n');
        _description.text = found.description;
        _images.addAll(found.images);
        _sizes.addAll(found.sizes.map((v) => v.name));
        _shades.addAll(found.shades.map((v) => v.name));
        _category = found.category;
        _badge = found.badges.isEmpty ? null : found.badges.first;
        for (final entry in _specFields.entries) {
          entry.value.text = found.specs[entry.key] ?? '';
        }
      }
    }

    if (_specFieldsReady) return;
    _specFieldsReady = true;
    final config = context.read<BusinessConfigProvider>().config;
    for (final label in config.productFields) {
      _specFields[label] = TextEditingController(
        text: _existing?.specs[label] ?? '',
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _price.dispose();
    _mrp.dispose();
    _stock.dispose();
    _highlights.dispose();
    _description.dispose();
    for (final controller in _specFields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _isNew => widget.productId == null;

  Future<void> _pickImage() async {
    final url = await showDialog<String>(
      context: context,
      builder: (_) => const _ImageUrlDialog(),
    );
    if (url == null || url.trim().isEmpty) return;
    setState(() => _images.add(url.trim()));
  }

  Future<void> _addSampleImage() async {
    setState(() => _images.add(DemoCatalog.imageForCategory(_category ?? '')));
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_category == null) {
      setState(() => _formError = 'Choose a category');
      return;
    }
    if (_images.isEmpty) {
      setState(() => _formError = 'Add at least one photo');
      return;
    }

    final auth = context.read<AuthProvider>();
    final store = context.read<CommerceStore>();
    final user = auth.user;
    if (user == null) return;

    setState(() {
      _saving = true;
      _formError = null;
    });

    final price = int.tryParse(_price.text.trim()) ?? 0;
    final mrpRaw = int.tryParse(_mrp.text.trim());
    final mrp = mrpRaw == null || mrpRaw <= price ? price : mrpRaw;
    final stock = int.tryParse(_stock.text.trim()) ?? 0;

    final existingVariants = <String, ProductVariant>{
      for (final v in [...?_existing?.sizes, ...?_existing?.shades]) v.name: v,
    };

    final product = Product(
      id: _existing?.id ?? 'own-${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim(),
      brand: _brand.text.trim(),
      category: _category!,
      sku:
          _existing?.sku ??
          'OWN-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      price: price,
      mrp: mrp,
      rating: _existing?.rating ?? 0,
      reviewCount: _existing?.reviewCount ?? 0,
      images: List.unmodifiable(_images),
      icon: _existing?.icon ?? Icons.shopping_bag_outlined,
      // Rebuilt from the chips so an edited option list is actually saved,
      // while any swatch colour the seller picked before is carried over.
      sizes: _sizes
          .map((n) => existingVariants[n] ?? ProductVariant(n))
          .toList(growable: false),
      shades: _shades
          .map((n) => existingVariants[n] ?? ProductVariant(n))
          .toList(growable: false),
      highlights: _highlights.text
          .split('\n')
          .map((h) => h.trim())
          .where((h) => h.isNotEmpty)
          .toList(growable: false),
      badges: _badge == null ? const [] : [_badge!],
      description: _description.text.trim(),
      specs: {
        for (final entry in _specFields.entries)
          if (entry.value.text.trim().isNotEmpty)
            entry.key: entry.value.text.trim(),
      },
      inStock: stock > 0,
      deliveryDays: _existing?.deliveryDays ?? 3,
      ownerId: user.id,
      stock: stock,
      createdAt: _existing?.createdAt ?? DateTime.now(),
    );

    if (_isNew) {
      store.publishProduct(product);
    } else {
      store.updateProduct(product);
    }

    if (!mounted) return;
    setState(() => _saving = false);
    context.go('/owner/products');
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final spacing = Responsive.spacing(context, mobile: 16);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New product' : 'Edit product'),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: 'Delete listing',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: Responsive.padding(context),
                children: [
                  _SectionLabel(
                    title: 'Photos',
                    hint: 'The first photo is the cover',
                  ),
                  SizedBox(height: spacing),
                  _ImagesEditor(
                    images: _images,
                    onAdd: _pickImage,
                    onAddSample: _addSampleImage,
                    onRemove: _removeImage,
                  ),
                  SizedBox(height: spacing),

                  _SectionLabel(title: 'Basics'),
                  SizedBox(height: spacing),
                  AppTextField(
                    controller: _name,
                    label: 'Product name',
                    hint: 'Silk embroidered kurta',
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'Enter a product name';
                      if (value.length > 80) {
                        return 'Keep it under 80 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: spacing),
                  AppTextField(
                    controller: _brand,
                    label: 'Brand',
                    hint: 'Aurelle',
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      if ((v ?? '').trim().isEmpty) return 'Enter a brand';
                      return null;
                    },
                  ),
                  SizedBox(height: spacing),
                  _Dropdown(
                    label: 'Category',
                    value: _category,
                    items: config.categories,
                    hint: 'Choose a category',
                    onChanged: (v) => setState(() => _category = v),
                  ),
                  SizedBox(height: spacing),
                  AppTextField(
                    controller: _description,
                    label: 'Description',
                    hint: 'One line shown under the product title',
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  SizedBox(height: spacing),

                  _SectionLabel(title: 'Pricing & stock'),
                  SizedBox(height: spacing),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _price,
                          label: 'Selling price',
                          prefixText: '${config.currencySymbol} ',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) {
                            final value = int.tryParse((v ?? '').trim());
                            if (value == null) return 'Required';
                            if (value <= 0) return 'Must be above 0';
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        child: AppTextField(
                          controller: _mrp,
                          label: 'MRP (optional)',
                          prefixText: '${config.currencySymbol} ',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) {
                            final raw = (v ?? '').trim();
                            if (raw.isEmpty) return null;
                            final value = int.tryParse(raw);
                            if (value == null) return 'Invalid';
                            final price = int.tryParse(_price.text.trim()) ?? 0;
                            if (value < price) return 'Below price';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing),
                  AppTextField(
                    controller: _stock,
                    label: 'Units in stock',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final value = int.tryParse((v ?? '').trim());
                      if (value == null) return 'Enter a stock count';
                      if (value < 0) return 'Cannot be negative';
                      return null;
                    },
                  ),
                  SizedBox(height: spacing),

                  _SectionLabel(title: 'Variants', hint: 'Optional'),
                  SizedBox(height: spacing),
                  _ChipInput(
                    label: 'Sizes',
                    values: _sizes,
                    suggestions: const ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
                    onChanged: () => setState(() {}),
                  ),
                  SizedBox(height: spacing),
                  _ChipInput(
                    label: 'Shades',
                    values: _shades,
                    suggestions: const [
                      'Ivory',
                      'Rose',
                      'Emerald',
                      'Indigo',
                      'Charcoal',
                    ],
                    onChanged: () => setState(() {}),
                  ),
                  SizedBox(height: spacing),

                  _SectionLabel(title: 'Details', hint: 'One per line'),
                  SizedBox(height: spacing),
                  AppTextField(
                    controller: _highlights,
                    label: 'Highlights',
                    hint: 'Hand-embroidered\nShips in 2 days',
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  SizedBox(height: spacing),
                  _Dropdown(
                    label: 'Badge',
                    value: _badge,
                    items: const [
                      'Bestseller',
                      'New In',
                      'Limited Edition',
                      'Handpicked',
                    ],
                    hint: 'No badge',
                    allowClear: true,
                    onChanged: (v) => setState(() => _badge = v),
                  ),
                  if (_specFields.isNotEmpty) ...[
                    SizedBox(height: spacing),
                    _SectionLabel(
                      title: 'Specifications',
                      hint: 'Blank rows are hidden from buyers',
                    ),
                    SizedBox(height: spacing),
                    for (final entry in _specFields.entries) ...[
                      AppTextField(
                        controller: entry.value,
                        label: entry.key,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      SizedBox(height: spacing),
                    ],
                  ],
                  if (_formError != null) ...[
                    SizedBox(height: spacing),
                    Semantics(
                      liveRegion: true,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 16,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _formError!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: spacing * 1.5),
                  AppButton(
                    text: _isNew ? 'Publish product' : 'Save changes',
                    icon: _isNew ? Icons.publish_outlined : Icons.save_outlined,
                    color: config.primaryColor,
                    isLoading: _saving,
                    isExpanded: true,
                    onPressed: _save,
                  ),
                  SizedBox(height: Responsive.spacing(context, mobile: 28)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final store = context.read<CommerceStore>();
    final name = _name.text.trim().isEmpty ? 'this product' : _name.text.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete listing?'),
        content: Text('$name will be removed from the shop.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    store.deleteProduct(widget.productId!);
    context.go('/owner/products');
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, mobile: 15),
            fontWeight: FontWeight.w700,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              hint!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ),
        ],
      ],
    );
  }
}

/// Grid of photo previews with an add tile.
class _ImagesEditor extends StatelessWidget {
  const _ImagesEditor({
    required this.images,
    required this.onAdd,
    required this.onAddSample,
    required this.onRemove,
  });

  final List<String> images;
  final VoidCallback onAdd;
  final VoidCallback onAddSample;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 132,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < images.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _ImageTile(
                    url: images[i],
                    isCover: i == 0,
                    onRemove: () => onRemove(i),
                  ),
                ),
              _AddTile(onTap: onAdd),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Add photo URL'),
              onPressed: onAdd,
            ),
            ActionChip(
              avatar: const Icon(Icons.auto_awesome_outlined, size: 18),
              label: const Text('Use a sample photo'),
              onPressed: onAddSample,
            ),
          ],
        ),
        if (images.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Add at least one photo before publishing.',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.url,
    required this.isCover,
    required this.onRemove,
  });

  final String url;
  final bool isCover;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 92,
            height: 132,
            child: ProductImageTile(
              url: url,
              fit: BoxFit.cover,
              placeholderIcon: Icons.broken_image_outlined,
            ),
          ),
        ),
        if (isCover)
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Cover',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.black.withValues(alpha: 0.55),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(Icons.close, size: 15, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 92,
        height: 132,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: scheme.outlineVariant,
            style: BorderStyle.solid,
          ),
          color: scheme.surfaceContainerHighest,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: scheme.primary),
            const SizedBox(height: 6),
            Text(
              'Add',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipInput extends StatelessWidget {
  const _ChipInput({
    required this.label,
    required this.values,
    required this.suggestions,
    required this.onChanged,
  });

  final String label;
  final Set<String> values;
  final List<String> suggestions;
  final VoidCallback onChanged;

  Future<void> _addManually(BuildContext context) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add $label value'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty) return;
    values.add(value.trim());
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final rest = suggestions.where((s) => !values.contains(s));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in values)
              InputChip(
                label: Text(v),
                onDeleted: () {
                  values.remove(v);
                  onChanged();
                },
              ),
            for (final s in rest)
              ActionChip(
                label: Text(s),
                onPressed: () {
                  values.add(s);
                  onChanged();
                },
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: Text('Add $label'),
              onPressed: () => _addManually(context),
            ),
          ],
        ),
        if (values.isEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Shoppers will see a plain listing without $label options.',
            style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
          ),
        ],
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
    this.allowClear = false,
  });

  /// Sentinel so an optional field can be reset to "nothing selected".
  /// `DropdownButton` cannot hold a null value and still offer a clear
  /// choice, so we map this back to null on the way out.
  static const String _clearValue = '__none__';

  final String label;
  final String? value;
  final List<String> items;
  final String hint;
  final ValueChanged<String?> onChanged;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          hint: Text(hint, maxLines: 1, overflow: TextOverflow.ellipsis),
          validator: (_) => value == null && !allowClear ? 'Required' : null,
          items: [
            if (allowClear)
              const DropdownMenuItem<String>(
                value: _clearValue,
                child: Text(
                  'None',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            for (final item in items)
              DropdownMenuItem<String>(
                value: item,
                child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => onChanged(v == _clearValue ? null : v),
        ),
      ],
    );
  }
}

class _ImageUrlDialog extends StatefulWidget {
  const _ImageUrlDialog();

  @override
  State<_ImageUrlDialog> createState() => _ImageUrlDialogState();
}

class _ImageUrlDialogState extends State<_ImageUrlDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final url = _controller.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Enter an image address');
      return;
    }
    if (!Uri.tryParse(url)!.hasScheme) {
      setState(() => _error = 'Include http:// or https://');
      return;
    }
    Navigator.of(context).pop(url);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add photo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: 'https://…/photo.jpg',
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          Text(
            'Paste a direct link to a photo. A backend upload can replace this '
            'later without changing the form.',
            style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
