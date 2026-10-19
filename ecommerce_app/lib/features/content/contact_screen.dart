import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';

/// "Contact Us" (§10.7): message form plus the verified tel / WhatsApp /
/// email actions from the live footer (§5.8).
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pageInset(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: EdgeInsets.fromLTRB(padding, AppSpacing.xxxl, padding, 0),
          child: _submitted ? _success() : _form(padding),
        ),
      ),
    );
  }

  Widget _success() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CUSTOMER DELIGHT', style: AppTypography.eyebrow),
        const SizedBox(height: AppSpacing.sm),
        Text('Message received', style: AppTypography.display),
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
          'Thank you for writing in. A jewellery specialist will reply to '
          'your email within one working day.',
          style: AppTypography.bodyMuted.copyWith(height: 1.7),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          text: 'SEND ANOTHER',
          type: AppButtonType.outlined,
          onPressed: () => setState(() {
            _submitted = false;
            _nameController.clear();
            _emailController.clear();
            _messageController.clear();
          }),
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  Widget _form(double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CUSTOMER DELIGHT', style: AppTypography.eyebrow),
        const SizedBox(height: AppSpacing.sm),
        Text('Contact us', style: AppTypography.display),
        const SizedBox(height: AppSpacing.lg),
        Container(height: 2, width: 64, color: AppPalette.copper),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _ActionChipTile(
              icon: Icons.call_outlined,
              label: 'Call 1800 120 0411',
              onTap: () => _toast('Call us on 1800 120 0411 — 9 AM to 9 PM'),
            ),
            _ActionChipTile(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'WhatsApp +91 98948 40711',
              onTap: () => _toast('WhatsApp us on +91 98948 40711'),
            ),
            _ActionChipTile(
              icon: Icons.mail_outline_rounded,
              label: 'Enquiry@online-kirtilals.com',
              onTap: () => _toast('Write to Enquiry@online-kirtilals.com'),
            ),
          ],
        ),
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
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _messageController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'How can we help?',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'SEND MESSAGE',
            type: AppButtonType.filled,
            onPressed: () => setState(() => _submitted = true),
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }
}

class _ActionChipTile extends StatelessWidget {
  const _ActionChipTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppPalette.textPrimary,
        side: const BorderSide(color: AppPalette.border),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
        textStyle: AppTypography.label.copyWith(letterSpacing: 0),
      ),
    );
  }
}
