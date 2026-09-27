import 'package:flutter/material.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../../core/business_config.dart';
import '../../../core/models/user.dart';

/// Customer / owner switch shared by the sign-in and registration forms.
///
/// Both forms must ask the same question in the same way, otherwise a user who
/// picks "Shop Owner" on login and never sees the option on register ends up
/// registered as a customer by accident.
class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.role,
    required this.config,
    required this.onChanged,
    this.enabled = true,
    this.caption,
  });

  final UserRole role;
  final BusinessConfig config;
  final ValueChanged<UserRole> onChanged;
  final bool enabled;

  /// Optional line above the selector explaining why the choice matters.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (caption != null) ...[
            Text(
              caption!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, mobile: 13),
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              for (final option in UserRole.values) ...[
                if (option != UserRole.values.first) const SizedBox(width: 12),
                Expanded(
                  child: _RolePill(
                    option: option,
                    selected: role == option,
                    config: config,
                    onTap: enabled ? () => onChanged(option) : null,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({
    required this.option,
    required this.selected,
    required this.config,
    required this.onTap,
  });

  final UserRole option;
  final bool selected;
  final BusinessConfig config;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = config.primaryColor;
    final textColor = selected ? Colors.white : accent;
    final borderColor = selected ? accent : Theme.of(context).dividerColor;

    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.spacing(context, mobile: 10),
            vertical: Responsive.spacing(context, mobile: 12),
          ),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(option.icon, size: 22, color: textColor),
              const SizedBox(height: 6),
              Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, mobile: 12),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
