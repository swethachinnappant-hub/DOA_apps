import 'package:flutter/material.dart';
import '../../core/responsive.dart';

enum AppButtonType { filled, outlined, text, gradient }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final Color? color;
  final Color? textColor;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final double radius;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.filled,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.color,
    this.textColor,
    this.height,
    this.width,
    this.padding,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonHeight = height ?? Responsive.spacing(context, mobile: 48, tablet: 50, desktop: 52);
    final fontSize = Responsive.fontSize(context, mobile: 14, tablet: 15, desktop: 16);

    Widget button;

    switch (type) {
      case AppButtonType.filled:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? theme.primaryColor,
            foregroundColor: textColor ?? Colors.white,
            minimumSize: Size(width ?? 0, buttonHeight),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
            elevation: 0,
          ),
          child: _buildChild(context, fontSize),
        );
        break;

      case AppButtonType.outlined:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color ?? theme.primaryColor,
            side: BorderSide(color: color ?? theme.primaryColor),
            minimumSize: Size(width ?? 0, buttonHeight),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          ),
          child: _buildChild(context, fontSize),
        );
        break;

      case AppButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: color ?? theme.primaryColor,
            minimumSize: Size(width ?? 0, buttonHeight),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          ),
          child: _buildChild(context, fontSize),
        );
        break;

      case AppButtonType.gradient:
        button = Container(
          height: buttonHeight,
          width: width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color ?? theme.primaryColor,
                (color ?? theme.primaryColor).withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: textColor ?? Colors.white,
              shadowColor: Colors.transparent,
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
            ),
            child: _buildChild(context, fontSize),
          ),
        );
        break;
    }

    if (isExpanded) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  Widget _buildChild(BuildContext context, double fontSize) {
    if (isLoading) {
      return SizedBox(
        height: fontSize + 4,
        width: fontSize + 4,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            textColor ?? Colors.white,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class IconAppButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? iconColor;
  final double? size;
  final String? tooltip;
  final bool isCircular;

  const IconAppButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.iconColor,
    this.size,
    this.tooltip,
    this.isCircular = true,
  });

  @override
  Widget build(BuildContext context) {
    final btnSize = size ?? Responsive.spacing(context, mobile: 40, tablet: 42, desktop: 44);

    final button = IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: btnSize * 0.5),
      style: IconButton.styleFrom(
        backgroundColor: color ?? Theme.of(context).primaryColor.withValues(alpha: 0.1),
        foregroundColor: iconColor ?? Theme.of(context).primaryColor,
        minimumSize: Size(btnSize, btnSize),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isCircular ? btnSize / 2 : 10),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

class ChipButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isSelected;
  final Color? color;
  final IconData? icon;

  const ChipButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isSelected = false,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final btnColor = color ?? theme.primaryColor;

    return FilterChip(
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      selected: isSelected,
      onSelected: (_) => onPressed?.call(),
      avatar: icon != null ? Icon(icon, size: 18) : null,
      selectedColor: btnColor.withValues(alpha: 0.15),
      checkmarkColor: btnColor,
      labelStyle: TextStyle(
        color: isSelected ? btnColor : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? btnColor : theme.dividerColor,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

