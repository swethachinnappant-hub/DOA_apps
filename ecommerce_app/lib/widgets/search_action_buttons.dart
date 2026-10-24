import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// §3.16: the camera flow behind every "Search by photo" affordance. Exposed
/// as a top-level function so the search overlay can render a labelled chip
/// (not just the suffix icon) while sharing the exact same behaviour.
Future<void> showPhotoSearch(BuildContext context) async {
  final picker = ImagePicker();
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return;
  try {
    final photo = await picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (photo == null || !context.mounted) return;
    final bytes = await photo.readAsBytes();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Photo ready'),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            height: 280,
            width: double.infinity,
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  } on Exception catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open the camera: $error')),
    );
  }
}

/// Compact camera and dictation controls shared by the customer search fields.
class SearchActionButtons extends StatefulWidget {
  const SearchActionButtons({super.key, required this.onVoiceQuery});

  final ValueChanged<String> onVoiceQuery;

  @override
  State<SearchActionButtons> createState() => _SearchActionButtonsState();
}

class _SearchActionButtonsState extends State<SearchActionButtons> {
  final _speech = SpeechToText();
  bool _listening = false;

  Future<void> _capturePhoto() => showPhotoSearch(context);

  Future<void> _toggleVoice() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
      if (!available || !mounted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voice search is unavailable on this device.'),
            ),
          );
        }
        return;
      }
      setState(() => _listening = true);
      await _speech.listen(
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 8),
          pauseFor: const Duration(seconds: 2),
        ),
        onResult: (result) {
          final query = result.recognizedWords.trim();
          if (result.finalResult && query.isNotEmpty) {
            widget.onVoiceQuery(query);
          }
          if (result.finalResult && mounted) setState(() => _listening = false);
        },
      );
    } on Exception {
      if (mounted) {
        setState(() => _listening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Voice search could not start. Check microphone access.',
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _action(Icons.camera_alt_outlined, 'Search by photo', _capturePhoto),
      _action(
        _listening ? Icons.mic : Icons.mic_none_rounded,
        _listening ? 'Stop voice search' : 'Voice search',
        _toggleVoice,
        active: _listening,
      ),
    ],
  );

  Widget _action(
    IconData icon,
    String label,
    VoidCallback onPressed, {
    bool active = false,
  }) => IconButton(
    tooltip: label,
    onPressed: onPressed,
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 32, height: 36),
    icon: Icon(
      icon,
      size: 18,
      color: active ? Theme.of(context).colorScheme.primary : null,
    ),
  );
}
