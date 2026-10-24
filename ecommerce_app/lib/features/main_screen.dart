import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';
import 'package:provider/provider.dart';
import '../core/navigation/nav_helpers.dart';
import '../core/store/commerce_store.dart';
import 'catalogue/screens/catalogue_screen.dart';
import 'config/providers/business_config_provider.dart';
import 'home/home_layout.dart';
import 'home/home_skeleton.dart';
import '../widgets/search_action_buttons.dart';
import 'profile/screens/profile_screen.dart';
import 'shell/bottom_bar.dart';
import 'shell/store_shell.dart';

/// Customer shell: top USP strip · responsive header · body · bottom bar
/// (compact only) · cookie banner (architecture §5).
///
/// The bottom bar carries the four verified destinations — Home, Catalogue
/// (listing with its grid/list view toggle), Cart(n), Account — and the
/// drawer opens from the header's menu button.
class MainScreen extends StatefulWidget {
  /// Home section order (§6.1). Pass a customised [HomeLayout] to reorder
  /// sections without touching the shell.
  final HomeLayout? layout;

  const MainScreen({super.key, this.layout});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// The bar's own visual indices: 0 Home · 1 Catalogue · 3 Account.
  /// Slot 2 is Cart, which pushes its own route and never rests here.
  int _currentIndex = 0;

  bool get _showBottomBar => MediaQuery.sizeOf(context).width < 768;

  @override
  Widget build(BuildContext context) {
    // §16.4 Android: system back walks tabs home-ward before leaving the
    // shop; the cart entry pushes its own route and is unaffected.
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && mounted) {
          setState(() => _currentIndex = 0);
        }
      },
      child: StoreShell(
        bottomBar: _showBottomBar
            ? BottomBar(
                selectedIndex: _currentIndex,
                onSelect: (index) => setState(() => _currentIndex = index),
                cartCount: context.watch<CommerceStore>().cartCount,
                onCart: () => navTo(context, '/cart'),
              )
            : null,
        // Smooth tab changes: the outgoing screen fades out as the incoming
        // one fades in instead of swapping on a single frame.
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: KeyedSubtree(
            key: ValueKey(_currentIndex),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 1:
        // The listing lives in the shell: its own grid/list view toggle,
        // sort and filters, with "back to home" wired to the first tab.
        return CatalogueScreen(onExit: () => setState(() => _currentIndex = 0));
      case 3:
        return const ProfileScreen();
      case 0:
      case 2:
      default:
        return _HomeTab(layout: widget.layout);
    }
  }
}

// ----------------------------------------------------------------- home tab

class _HomeTab extends StatefulWidget {
  const _HomeTab({this.layout});

  final HomeLayout? layout;

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();

  /// Skeleton holds the screen for §6.3's minimum ~300 ms before the real
  /// sections paint, so first load never flickers.
  late final AnimationController _loaded = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..forward();

  @override
  void dispose() {
    _loaded.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    // The promotional hero leads, followed by product discovery; owner edits
    // from the Home Builder (SPEC-18) can still reorder or hide sections.
    final layout =
        widget.layout ?? resolveHomeLayout(context.watch<CommerceStore>());

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('THE JEWELLERY EDIT', style: AppTypography.eyebrow),
                const SizedBox(height: 6),
                Text(
                  'Pieces to treasure, every day.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 15),
                AppSearchField(
                  hint: config.searchHint,
                  controller: _searchController,
                  trailing: SearchActionButtons(
                    onVoiceQuery: (query) {
                      _searchController.text = query;
                      navTo(
                        context,
                        '/catalogue?search=${Uri.encodeQueryComponent(query)}',
                      );
                    },
                  ),
                  onSubmitted: (value) {
                    final search = value.trim();
                    if (search.isNotEmpty) {
                      navTo(
                        context,
                        '/catalogue?search=${Uri.encodeQueryComponent(search)}',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedBuilder(
            animation: _loaded,
            builder: (context, _) {
              if (!_loaded.isCompleted) {
                return const HomeSkeleton(key: Key('home-skeleton'));
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < layout.sections.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.md),
                    KeyedSubtree(
                      key: Key('home-section-${layout.sections[i].id}'),
                      child: layout.sections[i].build(context),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
