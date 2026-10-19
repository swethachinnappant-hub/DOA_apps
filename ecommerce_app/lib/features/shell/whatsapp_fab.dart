import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/navigation/menu_data.dart';
import 'contact_actions.dart';

/// Floating WhatsApp support button (architecture Â§5.1).
///
/// Web and desktop only â€” hidden inside the native phone apps.
class WhatsAppFab extends StatelessWidget {
  const WhatsAppFab({super.key});

  static bool get _shouldShow =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.windows;

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();
    return FloatingActionButton.small(
      heroTag: 'whatsapp-support',
      onPressed: () => showContactSheet(
        context,
        title: 'WhatsApp',
        line1: StoreNav.whatsappBot,
        line2: 'Support: ${StoreNav.whatsappSupport}',
      ),
      backgroundColor: const Color(0xFF25D366),
      foregroundColor: Colors.white,
      tooltip: 'Chat on WhatsApp',
      child: const Icon(Icons.chat, size: 22),
    );
  }
}
