import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';

/// "Give Feedback" (§10.7): star rating, message and an inline success state.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _messageController = TextEditingController();
  int _rating = 0;
  bool _submitted = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pageInset(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: EdgeInsets.fromLTRB(padding, AppSpacing.xxxl, padding, 0),
          child: _submitted ? _success() : _form(context, padding),
        ),
      ),
    );
  }

  Widget _success() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('GIVE FEEDBACK', style: AppTypography.eyebrow),
        const SizedBox(height: AppSpacing.sm),
        Text('Thank you', style: AppTypography.display),
        const SizedBox(height: AppSpacing.lg),
        Container(height: 2, width: 64, color: AppPalette.copper),
        const SizedBox(height: AppSpacing.xl),
        const Icon(Icons.check_circle_outline, size: 44, color: AppPalette.success),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Your note is with our customer delight team. We read every message '
          'and reply within two working days.',
          style: AppTypography.bodyMuted.copyWith(height: 1.7),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          text: 'SEND ANOTHER',
          type: AppButtonType.outlined,
          onPressed: () => setState(() {
            _submitted = false;
            _rating = 0;
            _messageController.clear();
          }),
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  Widget _form(BuildContext context, double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('GIVE FEEDBACK', style: AppTypography.eyebrow),
        const SizedBox(height: AppSpacing.sm),
        Text('Tell us how we did', style: AppTypography.display),
        const SizedBox(height: AppSpacing.lg),
        Container(height: 2, width: 64, color: AppPalette.copper),
        const SizedBox(height: AppSpacing.xl),
        Text('Your rating', style: AppTypography.subtitle),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            for (var star = 1; star <= 5; star++)
              IconButton(
                tooltip: '$star star${star == 1 ? '' : 's'}',
                onPressed: () => setState(() => _rating = star),
                icon: Icon(
                  star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 32,
                  color: star <= _rating
                      ? AppPalette.goldDark
                      : AppPalette.textHint,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _messageController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Your message',
            hintText: 'What did you love, and what should we fix?',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'SUBMIT FEEDBACK',
            type: AppButtonType.filled,
            onPressed: () => setState(() => _submitted = true),
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }
}
