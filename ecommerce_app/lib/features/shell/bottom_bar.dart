import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';

/// Compact-only bottom bar (architecture §5.5):
/// Home · Catalogue · Cart (count) · Account.
class BottomBar extends StatelessWidget {
  const BottomBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.cartCount,
    this.onCart,
  });

  /// Selected tab index; the cart entry (2) never becomes a resting tab.
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final int cartCount;

  /// Pushes the cart route; falls back to a no-op without a router.
  final VoidCallback? onCart;

  static const _labels = ['Home', 'Catalogue', 'Cart', 'Account'];
  static const _icons = [
    Icons.home_outlined,
    Icons.category_outlined,
    Icons.shopping_cart_outlined,
    Icons.person_outline,
  ];
  static const _activeIcons = [
    Icons.home,
    Icons.category,
    Icons.shopping_cart,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: const BoxDecoration(
        color: AppPalette.surface,
        border: Border(top: BorderSide(color: AppPalette.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_labels.length, (i) {
              final selected = i == selectedIndex && i != 2;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: _labels[i],
                  child: InkWell(
                    onTap: () {
                      if (i == 2) {
                        onCart?.call();
                      } else {
                        onSelect(i);
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              selected ? _activeIcons[i] : _icons[i],
                              size: 22,
                              color: selected
                                  ? primary
                                  : AppPalette.textSecondary,
                            ),
                            if (i == 2 && cartCount > 0)
                              Positioned(
                                right: -7,
                                top: -4,
                                child: Semantics(
                                  container: true,
                                  liveRegion: true,
                                  label: 'Cart, $cartCount items',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primary,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Text(
                                      cartCount > 99 ? '99+' : '$cartCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            fontSize: 10.5,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected
                                ? primary
                                : AppPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
