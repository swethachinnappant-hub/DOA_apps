import 'package:flutter/foundation.dart';

/// Escape-key hook for the shell's non-route overlay (§16.4 keyboard polish).
///
/// The mega-menu hover panel is an `OverlayPortal`, not a pushed route, so it
/// is not reachable by `Navigator.pop`. The panel registers its close callback
/// here while open; [SearchShortcutHost] fires it on Escape and the widget
/// clears it on close/dispose.
VoidCallback? activeEscapeHandler;
