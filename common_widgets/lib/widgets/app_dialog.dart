import 'package:flutter/material.dart';
import '../core/responsive.dart';

class AppDialog {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    List<DialogAction>? actions,
    bool isDismissible = true,
    double? maxWidth,
  }) {
    final maxDialogWidth = maxWidth ?? Responsive.maxValue(context, mobile: 400, tablet: 500, desktop: 600);

    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxDialogWidth),
          child: Padding(
            padding: Responsive.padding(context, mobile: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, mobile: 18, tablet: 20, desktop: 22),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(child: content),
                if (actions != null && actions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    children: actions.map((action) {
                      return action.build(context);
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    IconData? icon,
  }) {
    final theme = Theme.of(context);

    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: Responsive.padding(context, mobile: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Container(
                  padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16)),
                  decoration: BoxDecoration(
                    color: (confirmColor ?? theme.primaryColor).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: confirmColor ?? theme.primaryColor, size: 32),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                message,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, mobile: 14, tablet: 15, desktop: 16),
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(cancelText, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor ?? theme.primaryColor,
                      ),
                      child: Text(confirmText, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
    IconData? icon,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);

    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: Responsive.padding(context, mobile: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Container(
                  padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16)),
                  decoration: BoxDecoration(
                    color: (iconColor ?? theme.primaryColor).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor ?? theme.primaryColor, size: 32),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                message,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, mobile: 14, tablet: 15, desktop: 16),
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(buttonText, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> error(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return info(
      context,
      title: title,
      message: message,
      buttonText: buttonText,
      icon: Icons.error_outline,
      iconColor: Theme.of(context).colorScheme.error,
    );
  }

  static Future<void> success(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return info(
      context,
      title: title,
      message: message,
      buttonText: buttonText,
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
    );
  }

  static Future<T?> bottomSheet<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: Responsive.padding(context, mobile: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, mobile: 20, tablet: 22, desktop: 24),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  content,
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class DialogAction {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isExpanded;

  const DialogAction({
    required this.label,
    this.onPressed,
    this.color,
    this.isExpanded = false,
  });

  factory DialogAction.cancel({VoidCallback? onPressed, String label = 'Cancel'}) {
    return DialogAction(label: label, onPressed: onPressed, color: Colors.grey);
  }

  factory DialogAction.confirm({
    VoidCallback? onPressed,
    String label = 'Confirm',
    Color? color,
  }) {
    return DialogAction(label: label, onPressed: onPressed, color: color);
  }

  factory DialogAction.danger({VoidCallback? onPressed, String label = 'Delete'}) {
    return DialogAction(label: label, onPressed: onPressed, color: Colors.red);
  }

  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isExpanded) {
      return Expanded(
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? theme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      );
    }

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? theme.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
