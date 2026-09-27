import 'package:flutter/material.dart';
import '../core/design_tokens.dart';
import '../core/responsive.dart';

class AppListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showDivider = false,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: padding ?? Responsive.horizontalPadding(context, mobile: 16),
          leading: leading,
          title: Text(
            title,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, mobile: 14, tablet: 15, desktop: 16),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, mobile: 12, tablet: 13, desktop: 14),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: trailing,
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class StatusListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String status;
  final Color statusColor;
  final Widget? leading;
  final VoidCallback? onTap;

  const StatusListTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.status,
    required this.statusColor,
    this.leading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: title,
      subtitle: subtitle,
      leading: leading ?? Container(
        width: Responsive.spacing(context, mobile: 48),
        height: Responsive.spacing(context, mobile: 48),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.receipt, color: statusColor),
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.spacing(context, mobile: 10),
          vertical: Responsive.spacing(context, mobile: 5),
        ),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, mobile: 11),
            fontWeight: FontWeight.w600,
            color: statusColor,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}

class AmountListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String amount;
  final Color? amountColor;
  final String? status;
  final Color? statusColor;
  final Widget? leading;
  final VoidCallback? onTap;

  const AmountListTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.amount,
    this.amountColor,
    this.status,
    this.statusColor,
    this.leading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, mobile: 14, tablet: 15, desktop: 16),
              fontWeight: FontWeight.w600,
              color: amountColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (status != null && statusColor != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.spacing(context, mobile: 8),
                vertical: Responsive.spacing(context, mobile: 3),
              ),
              decoration: BoxDecoration(
                color: statusColor!.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, mobile: 10),
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.xl,
            AppSpacing.screenH,
            AppSpacing.xs,
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              title,
              style: AppTypography.sectionTitle.copyWith(
                fontSize: Responsive.fontSize(context, mobile: 15.5, tablet: 17, desktop: 18),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

