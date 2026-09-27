import 'package:flutter/material.dart';
import '../core/design_tokens.dart';

class AppColorPickerSheet extends StatefulWidget {
  final Color initialColor;
  final String title;
  final List<Color> presets;

  const AppColorPickerSheet({
    super.key,
    required this.initialColor,
    this.title = 'Select Colour',
    this.presets = defaultPresets,
  });

  static const List<Color> defaultPresets = [
    Color(0xFF000000),
    Color(0xFF3F3F46),
    Color(0xFF71717A),
    Color(0xFFA1A1AA),
    Color(0xFFE4E4E7),
    Color(0xFFFFFFFF),
    Color(0xFF7F1D3A),
    Color(0xFF9D174D),
    Color(0xFFDB2777),
    Color(0xFFE11D48),
    Color(0xFFDC2626),
    Color(0xFFEA580C),
    Color(0xFFD97706),
    Color(0xFFCA8A04),
    Color(0xFF65A30D),
    Color(0xFF16A34A),
    Color(0xFF059669),
    Color(0xFF0D9488),
    Color(0xFF0891B2),
    Color(0xFF0284C7),
    Color(0xFF2563EB),
    Color(0xFF4F46E5),
    Color(0xFF7C3AED),
    Color(0xFF9333EA),
  ];

  @override
  State<AppColorPickerSheet> createState() => _AppColorPickerSheetState();
}

class _AppColorPickerSheetState extends State<AppColorPickerSheet> {
  late HSVColor _hsv;
  double _saturation = 1;
  double _value = 1;

  Color get _color => _hsv.withSaturation(_saturation).withValue(_value).toColor();

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
    _saturation = _hsv.saturation;
    _value = _hsv.value;
  }

  void _setFromPreset(Color color) {
    setState(() {
      _hsv = HSVColor.fromColor(color);
      _saturation = _hsv.saturation;
      _value = _hsv.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pureHue = _hsv.withSaturation(1).withValue(1).toColor();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.sm,
          AppSpacing.screenH,
          AppSpacing.screenH,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: AppTypography.title),
              const SizedBox(height: AppSpacing.lg),

              Row(
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: AppRadius.allMd,
                      border: Border.all(color: AppPalette.border),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '#${_color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                          style: AppTypography.subtitle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Hue ${_hsv.hue.round()}  Sat ${(_saturation * 100).round()}%  Val ${(_value * 100).round()}%',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              _SaturationValueBox(
                hueColor: pureHue,
                saturation: _saturation,
                value: _value,
                onChanged: (s, v) => setState(() {
                  _saturation = s;
                  _value = v;
                }),
              ),
              const SizedBox(height: AppSpacing.lg),

              _LabelRow(label: 'Hue', value: _hsv.hue.round().toString()),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: pureHue,
                  inactiveTrackColor: AppPalette.surfaceMuted,
                ),
                child: Slider(
                  value: _hsv.hue,
                  max: 360,
                  onChanged: (h) => setState(() {
                    _hsv = _hsv.withHue(h);
                  }),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              _LabelRow(label: 'Saturation', value: '${(_saturation * 100).round()}%'),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: pureHue,
                  inactiveTrackColor: AppPalette.surfaceMuted,
                ),
                child: Slider(
                  value: _saturation,
                  onChanged: (s) => setState(() => _saturation = s),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              _LabelRow(label: 'Brightness', value: '${(_value * 100).round()}%'),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: pureHue,
                  inactiveTrackColor: AppPalette.surfaceMuted,
                ),
                child: Slider(
                  value: _value,
                  onChanged: (v) => setState(() => _value = v),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text('Quick Picks', style: AppTypography.label),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: widget.presets.map((preset) {
                  final selected = preset.toARGB32() == _color.toARGB32();
                  return GestureDetector(
                    onTap: () => _setFromPreset(preset),
                    child: Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        color: preset,
                        borderRadius: AppRadius.allSm,
                        border: Border.all(
                          color: selected ? AppPalette.textPrimary : AppPalette.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: selected
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: preset.computeLuminance() > 0.55
                                  ? Colors.black
                                  : Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(_color),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaturationValueBox extends StatelessWidget {
  final Color hueColor;
  final double saturation;
  final double value;
  final void Function(double saturation, double value) onChanged;

  const _SaturationValueBox({
    required this.hueColor,
    required this.saturation,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          void handle(Offset local) {
            final s = (local.dx / width).clamp(0.0, 1.0);
            final v = 1 - (local.dy / height).clamp(0.0, 1.0);
            onChanged(s, v);
          }

          return GestureDetector(
            onPanDown: (d) => handle(d.localPosition),
            onPanUpdate: (d) => handle(d.localPosition),
            onTapDown: (d) => handle(d.localPosition),
            child: ClipRRect(
              borderRadius: AppRadius.allMd,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, hueColor],
                        ),
                      ),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: saturation * width - 11,
                    top: (1 - value) * height - 11,
                    child: Container(
                      height: 22,
                      width: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: Color(0x40000000), blurRadius: 4),
                        ],
                      ),
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
}

class _LabelRow extends StatelessWidget {
  final String label;
  final String value;

  const _LabelRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.label),
        Text(value, style: AppTypography.caption),
      ],
    );
  }
}

Future<Color?> showAppColorPicker(
  BuildContext context, {
  required Color initialColor,
  String title = 'Select Colour',
}) {
  return showModalBottomSheet<Color>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppPalette.surface,
    builder: (_) => AppColorPickerSheet(
      initialColor: initialColor,
      title: title,
    ),
  );
}
