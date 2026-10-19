import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';

const _steps = [
  (
    '01',
    'Share your idea',
    'Bring a sketch, a photograph or just a description. Our design desk '
        'listens first and sketches options within a week.',
  ),
  (
    '02',
    'Design',
    'You receive CAD renders with metal, stone and budget options. Iterate '
        'until the drawing feels like yours.',
  ),
  (
    '03',
    'Approve',
    'Sign off the final drawing and quote. A 30% advance begins the craft; '
        'the balance is due before dispatch.',
  ),
  (
    '04',
    'Craft',
    'The piece is made at our bench, hallmarked, certified and photographed '
        'before it ships to you.',
  ),
];

/// Bespoke (§10.5): hero → four-step process → enquiry form + success state.
class BespokeScreen extends StatefulWidget {
  const BespokeScreen({super.key});

  @override
  State<BespokeScreen> createState() => _BespokeScreenState();
}

class _BespokeScreenState extends State<BespokeScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ideaController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ideaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pageInset(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Padding(
          padding: EdgeInsets.fromLTRB(padding, AppSpacing.xxl, padding, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MADE FOR YOU', style: AppTypography.eyebrow),
              const SizedBox(height: AppSpacing.sm),
              Text('Bespoke', style: AppTypography.display),
              const SizedBox(height: AppSpacing.lg),
              Container(height: 2, width: 64, color: AppPalette.copper),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'One piece, made once, for one person. From the first sketch '
                'to the hallmark, every bespoke design is crafted at our own '
                'bench.',
                style: AppTypography.bodyMuted.copyWith(height: 1.75),
              ),
              const SizedBox(height: AppSpacing.xxl),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 820 ? 4 : 1;
                  if (columns == 1) {
                    return Column(
                      children: [
                        for (final step in _steps) ...[
                          _StepCard(
                            number: step.$1,
                            title: step.$2,
                            body: step.$3,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < _steps.length; i++) ...[
                        Expanded(
                          child: _StepCard(
                            number: _steps[i].$1,
                            title: _steps[i].$2,
                            body: _steps[i].$3,
                          ),
                        ),
                        if (i != _steps.length - 1)
                          const SizedBox(width: AppSpacing.md),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxxl),
              if (_sent)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ENQUIRY', style: AppTypography.eyebrow),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Idea received', style: AppTypography.display),
                    const SizedBox(height: AppSpacing.lg),
                    Container(height: 2, width: 64, color: AppPalette.copper),
                    const SizedBox(height: AppSpacing.xl),
                    const Icon(
                      Icons.check_circle_outline,
                      size: 44,
                      color: AppPalette.success,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Our design desk will call you within two working days '
                      'to walk through the first sketches.',
                      style: AppTypography.bodyMuted.copyWith(height: 1.7),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      text: 'START ANOTHER',
                      type: AppButtonType.outlined,
                      onPressed: () => setState(() {
                        _sent = false;
                        _nameController.clear();
                        _phoneController.clear();
                        _ideaController.clear();
                      }),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                )
              else ...[
                Text('ENQUIRY', style: AppTypography.eyebrow),
                const SizedBox(height: AppSpacing.sm),
                Text('Start your piece', style: AppTypography.display),
                const SizedBox(height: AppSpacing.lg),
                Container(height: 2, width: 64, color: AppPalette.copper),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _ideaController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Describe the piece you have in mind',
                    hintText: 'A pendant with the motif from my grandmother…',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'SEND ENQUIRY',
                    type: AppButtonType.filled,
                    onPressed: () => setState(() => _sent = true),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.body,
  });

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: AppTypography.display.copyWith(
              fontSize: 22,
              color: AppPalette.copper,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: AppTypography.subtitle),
          const SizedBox(height: AppSpacing.sm),
          Text(body, style: AppTypography.bodyMuted.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}
