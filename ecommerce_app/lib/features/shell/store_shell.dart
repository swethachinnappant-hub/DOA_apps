import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';

import 'app_header.dart';
import 'cookie_banner.dart';
import 'nav_drawer.dart';
import 'rate_strip.dart';
import 'whatsapp_fab.dart';

/// Global chrome shared by the home shell and every deep page (§5):
/// responsive header (drawer below 1200) · gold & silver
/// rate boxes (Thangamayil-style, per gram) · body · optional bottom bar
/// (compact only, §5.5) · cookie banner · WhatsApp FAB.
class StoreShell extends StatefulWidget {
  const StoreShell({super.key, required this.body, this.bottomBar});

  /// Page content; laid out under the header and above the bottom bar.
  final Widget body;

  /// Rendered under the body when present — callers own the visibility rule
  /// (`width < 768`) and the tab wiring.
  final Widget? bottomBar;

  @override
  State<StoreShell> createState() => _StoreShellState();
}

class _StoreShellState extends State<StoreShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool get _hasDrawer => MediaQuery.sizeOf(context).width < 1200;

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppPalette.background,
      drawer: _hasDrawer ? const NavDrawer() : null,
      floatingActionButton: const WhatsAppFab(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(onMenu: _openDrawer),
            const RateStrip(),
            Expanded(child: widget.body),
            if (widget.bottomBar != null) widget.bottomBar!,
            const CookieBanner(),
          ],
        ),
      ),
    );
  }
}
